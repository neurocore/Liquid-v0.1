module solver_pvs;
//import std.concurrency;
import std.stdio, std.string, std.format;
import std.algorithm: min, max;
import types, solver, movelist;
import timer, board, moves, gen;
import consts, engine, piece, utils;
import app, hash, eval, eval_smart;

import std.stdio : writefln;

extern(C) int kbhit();
extern(C) int getch();

// from GreKo 2021.12
const int[] Futility_Margin = [0, 50, 350, 550];

class SolverPVS : Solver
{
  this(Engine engine, shared Input input)
  {
    super(engine, input);
    B = new Board;
    for (int i = 0; i < Limits.Plies; i++)
      undos[i].ms = new MoveSeries(&B);
    undo = undos.ptr;
    E = new EvalSmart;
    H = new Hash;
  }

  override void set(const Board board)
  {
    B = board.dup();
    H.clear();
  }

  int ply() const @property { return cast(int)(undo - undos.ptr); }

  bool abort()
  {
    string str = input.pop();
    if (str == "isready") say("readyok");
    if (str == "stop" || str == "stop")
    {
      thinking = false;
      return true;
    }

    if (!thinking) return true;
    if (infinite) return false;

    const MS time_to_move = to_think / 30;
    if (timer.getms() > time_to_move)
    {
      thinking = false;
      return true;
    }
    return false;
  }

  void show_states(bool full = false)
  {
    debug
    {
      log("------ stack ------");
      auto high = full ? undos.ptr + Limits.Plies - 1 : undo;
      for (Undo * it = undos.ptr; it <= high; it++)
      {
        log(it - undos.ptr, " - ", it.state);
      }
      log("x - ", B.get_state);
      log("-------------------");
    }
  }

  override u64 perft(int depth)
  {
    u64 count = 0u;

    say("-- Perft ", depth);
    say(B);

    timer.start();
    auto ms = undo.ms;
    undo.ms.init();

    foreach (Move move; ms)
    {
      if (move.is_empty) break;
      if (!B.make(move, undo)) continue;

      if (mode == Mode.Game) write(move, " - ");

      u64 cnt = perft_inner(depth - 1);
      count += cnt;

      say(cnt);

      B.unmake(move, undo);
    }

    i64 time = timer.getms();
    double knps = cast(double)count / (time + 1);

    say();
    say("Count: ", count);
    say("Time: ", time, " ms");
    say("Speed: ", knps, " knps");
    say("\n");

    return count;
  }

  u64 perft_inner(int depth)
  {
    if (depth <= 0) return 1;

    auto ms = undo.ms;
    ms.init();

    u64 count = 0u;
    foreach (Move move; ms)
    {
      if (move.is_empty) break;
      if (!B.make(move, undo)) continue;

      count += depth > 1 ? perft_inner(depth - 1) : 1;

      B.unmake(move, undo);
    }
    return count;
  }

  override Move get_move(MS time)
  {
    timer.start();

    thinking = true;
    to_think = time;
    max_ply = 0;
    nodes = 0;

    //H.clear();

    Move best = Move.None; 
    for (int depth = 1; depth < Limits.Plies; depth++)
    {
      int val = pvs(-Val.Inf, Val.Inf, depth);
      if (!thinking) break;

      if (depth > max_ply) max_ply = depth;

      if (!undos[0].best.is_empty) best = undos[0].best;
      string fmt = "info depth %d seldepth %d score cp %d nodes %d time %d pv %s";
      sayf(fmt, depth, max_ply, val, nodes, timer.getms(), best);
      stdout.flush();

      if (val > Val.Mate || val < -Val.Mate) break;
    }

    say("bestmove ", best);
    stdout.flush();

    thinking = false;
    return best;
  }

  // Improvements:
  //
  // + LMR +108 elo (1+1 h2h-20)
  // + IID +50 elo (1+1 h2h-30)
  // + Hashing +50 elo (1+1 h2h-20)
  // + Futility Pruning +131 elo (1+1 h2h-30)
  // + Null Move Pruning +90 elo (.5+.5 h2h-30)
  // - Delta Pruning in QS
  // - Recapture & singular extension (check max ply!)

  int pvs(int alpha, int beta, int depth, bool is_null = false)
  {
    //check_input();

    const bool in_pv = (beta - alpha) > 1;
    const bool in_check = B.in_check;
    HashType hash_type = HashType.Alpha;
    int val = ply - Val.Inf;
    undo.best = Move.None;
    nodes++;

    if (!in_check && depth <= 0) return qs(alpha, beta);
    if (ply > 0 && B.is_draw) return 0; // contempt();

    int legal = 0;

    // 0. Mate pruning

    //if (ply > 0)
    //{
    //  alpha = max(-Val.Inf + ply, alpha);
    //  beta = min(Val.Inf - (ply + 1), beta);
    //  if (alpha >= beta) return alpha;
    //}

    // 1. Retrieving hash move

    //import bitboard;
    //u64 key = B.calc_hash();
    //assert(
    //  key == B.state.hash,
    //  format(
    //    "hash key is wrong\n%s\n%16x\n%16x\n%16x",
    //    B, key, B.state.hash, key ^ B.state.hash
    //  )
    //);

    // Somehow it returns same position but with wrong ep rights
    //  how is it even possible? Hash key already includes ep sq
    //  and i checked that hash key on the fly and calculated
    //  are the same, this is really strange

    Move hash_move = H.probe(B.state.hash, alpha, beta, depth, true);
    if (alpha == beta) return alpha;
    if (!B.is_allowed(hash_move)) hash_move = Move.None;

    // 2. Futility Pruning

    int static_eval = B.eval(E);

    if (!in_pv
    &&  !in_check
    &&  !is_null
    &&  depth >= 1
    &&  depth <= 3)
    {
      if (static_eval <= alpha - Futility_Margin[depth])
        return qs(alpha, beta);
      if (static_eval >= beta + Futility_Margin[depth])
        return beta;
    }

    // 3. Null Move Pruning

    if (!in_pv
    &&  !in_check
    &&  !is_null
    &&  B.has_pieces(B.color)
    &&  static_eval > beta
    &&  beta > -Val.Mate
    &&  depth >= 2)
    {
      int R = 3 + depth / 4;

      B.make_null(undo);
      int v = -pvs(-beta, -beta - 1, depth - R, false /*true*/);
      B.unmake_null(undo);

      if (abort) return alpha;

      if (v >= beta)
      {
        if (v > Val.Mate) v = beta; // don't return unproved mates
        if (depth >= 6) // verification search at high depths
        {
          v = pvs(alpha, beta, depth - R, true);
          if (v >= beta) return v;
        }
      }
    }

    // 4. Internal Iterative Deepening

    if (in_pv
    &&  depth >= 3
    &&  hash_move == Move.None)
    {
      int new_depth = depth - 2;

      int v = pvs(alpha, beta, new_depth, is_null);
      if (v <= alpha)
        v = pvs(-Val.Inf, beta, new_depth, is_null);

      if (!undo.best.is_empty)
        if (B.is_allowed(undo.best))
          hash_move = undo.best;
    }

    // Looking all legal moves

    auto ms = undo.ms;
    ms.init(false, hash_move);

    foreach (Move move; ms)
    {
      if (move.is_empty) break;
      if (!B.make(move, undo)) continue;

      legal++;
      int new_depth = depth - 1;
      int reduction = 0;

      // Extensions

      if (in_check) new_depth++;

      // LMR

      if (!in_pv
      &&  !is_null
      &&  !in_check
      &&  depth >= 4
      &&  !B.in_check
      &&  !move.is_attack)
      {
        // from Fruit Reloaded
        reduction = cast(int)( sqrt(depth - 1) + sqrt(legal - 1) );
      }

      if (legal == 1)
        val = -pvs(-beta, -alpha, new_depth, is_null);
      else
      {
        val = -pvs(-alpha - 1, -alpha, new_depth - reduction, is_null);
        if (val > alpha && reduction > 0)
          val = -pvs(-alpha - 1, -alpha, new_depth, is_null);
        if (val > alpha && val < beta)
          val = -pvs(-beta, -alpha, new_depth, is_null);
      }

      B.unmake(move, undo);

      if (abort) return alpha;

      if (val > alpha)
      {
        alpha = val;
        hash_type = HashType.Exact;
        undo.best = move;

        if (val >= beta)
        {
          if (!move.is_attack && !in_check)
            update_moves_stats(B.color, move, depth, undo);

          hash_type = HashType.Beta;
          break;
        }
      }
    }

    if (!legal)
    {
      return in_check ? val : 0; // contempt();
    }

    if (!abort)
      H.store(B.state.hash, undo.best, depth, ply, alpha, hash_type);

    return alpha;
  }

  int qs(int alpha, int beta)
  {
    //check_input();
    if (abort) return 0;

    nodes++;
    int stand_pat = B.eval(E);
    if (stand_pat >= beta) return beta;
    if (alpha < stand_pat) alpha = stand_pat;

    // Looking all captures moves

    auto ms = undo.ms;
    ms.init(true);

    foreach (Move move; ms)
    {
      if (move.is_empty) break;
      if (!B.make(move, undo)) continue;

      int val = -qs(-beta, -alpha);

      B.unmake(move, undo);

      if (val >= beta) return beta;
      if (val > alpha) alpha = val;
    }

    return alpha;
  }

  void update_moves_stats(Color color, Move move, int depth, Undo * undo)
  {
    undo.ms.history[color][move.from][move.to] += depth * depth;
    if (undo.ms.history[color][move.from][move.to] >> 56)
    {
      import square;
      foreach (i; A1..SQ.size)
        foreach (j; A1..SQ.size)
          undo.ms.history[color][i][j] >>= 1;
    }

    //if (undo.ms.killer[0] != move) // why it ruins the whole
    //{
    //  undo.ms.killer[1] = undo.ms.killer[0];
    //  undo.ms.killer[0] = move;
    //}
  }

private:
  //shared Signals signals;
  Undo[Limits.Plies] undos;
  Undo * undo;
  Board B;
  Eval E;
  Hash H;
  u64 nodes;
  int max_ply;
  MS to_think;
  Timer timer;
}

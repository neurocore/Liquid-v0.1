module solver_pvs;
import std.stdio, std.format;
import std.algorithm: min, max;
import types, solver, movelist;
import timer, board, moves, gen;
import consts, engine, piece, utils;
import app, hash, eval, eval_smart;

class SolverPVS : Solver
{
  this(Engine engine)
  {
    super(engine);
    B = new Board;
    for (int i = 0; i < Limits.Plies; i++)
      undos[i].ms = new MoveSeries(&B);
    undo = undos.ptr;
    E = new EvalSmart;
    H = new Hash;
  }

  override void set(const Board board) { B = board.dup(); }
  //override void stop() {}

  int ply() const @property { return cast(int)(undo - undos.ptr); }

  bool time_lack()
  {
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

    Move best = Move.None; 
    for (int depth = 1; depth <= Limits.Plies; depth++)
    {
      int val = pvs(-Val.Inf, Val.Inf, depth);
      if (!thinking) break;

      if (depth > max_ply) max_ply = depth;

      best = undos[0].best;
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

  // position startpos moves e2e4 e7e5 g1f3 b8c6 f1b5 a7a6 b5a4 g8f6 e1g1 f6e4 d2d4 b7b5 a4b3 d7d5 d4e5 c8e6 c2c3 f8c5 d1d3 e8g8 b1d2 f7f5 e5f6 f8f6 a2a4 b5b4 f3d4 c6e5 d3h3
  // - enpassant doing incorrectly on board, "captured" pawn remains


  // Improvements:
  //
  // + LMR +108 elo (1+1 h2h-20)
  // + IID +50 elo (1+1 h2h-30)
  // - Null Move Pruning
  // - Hashing (fix garbage input)

  int pvs(int alpha, int beta, int depth)
  {
    if (depth <= 0) return qs(alpha, beta);
    //check_input();
    if (time_lack()) return 0;

    const bool in_pv = (beta - alpha) > 1;
    const bool in_check = B.in_check;
    HashType hash_type = HashType.Alpha;
    undo.best = Move.None;
    int val = ply - Val.Inf;
    nodes++;

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

    //HashEntry he = H.get(B.state.hash, alpha, beta, depth, ply, !in_pv);
    //if (alpha == beta) return alpha;
    //Move hash_move = he.is_bad ? Move.None : he.move;
    //if (!B.is_allowed(hash_move)) hash_move = Move.None;
    auto hash_move = Move.None;

    // 2. Internal Iterative Deepening

    if (depth >= 3 && in_pv && hash_move == Move.None)
    {
      int new_depth = depth - 2;

      int v = pvs(alpha, beta, new_depth);
      //if (v <= alpha)
      //  v = pvs(-Val.Inf, beta, new_depth);

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

      // LMR

      if (!in_pv
      &&  depth >= 4
    // && !isNull
      && !in_check
      && !B.in_check
      && !move.mt.is_attack)
      {
        reduction = cast(int)( sqrt(depth - 1) + sqrt(legal - 1) );
      }

      if (legal == 1)
        val = -pvs(-beta, -alpha, new_depth);
      else
      {
        val = -pvs(-alpha - 1, -alpha, new_depth - reduction);
        if (val > alpha && reduction > 0)
          val = -pvs(-alpha - 1, -alpha, new_depth);
        if (val > alpha && val < beta)
          val = -pvs(-beta, -alpha, new_depth);
      }

      B.unmake(move, undo);

      if (val > alpha)
      {
        alpha = val;
        hash_type = HashType.Exact;
        undo.best = move;

        if (val >= beta)
        {
          //int in_check = B.in_check();
          //if (!is_cap_or_prom(move) && !in_check)
          //  B->update_moves_stats(move, depth, history);

          alpha = beta;
          hash_type = HashType.Beta;
          break;
        }
      }
    }

    //if (legal > 1 && !ml.is_hash_correct())
    //{
    //  auto mv0 = new MoveList;
    //  B.generate!0(mv0);
    //  B.generate!1(mv0);

    //  bool found = false;
    //  Move fmove = Move.None;
    //  foreach (m; mv0) if (m == hash_move)
    //  {
    //    found = true;
    //    fmove = m;
    //    break;
    //  }
    //  assert(false,
    //    format("hashmove is incorrect\n%s%s\n%s\n\n%d\n%x\n%x\n%d",
    //            B, mv0, hash_move, found, cast(u16)fmove,
    //            cast(u16)hash_move, legal));
    //}

    if (!legal)
    {
      return in_check > 0 ? val : 0; // contempt();
    }

    H.set(B.state.hash, undo.best, depth, ply, alpha, hash_type);

    return alpha;
  }

  int qs(int alpha, int beta)
  {
    //check_input();
    if (time_lack()) return 0;

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
    history[color][move.from][move.to] += depth * depth;
    if (history[color][move.from][move.to] >> 56)
    {
      import square;
      foreach (i; A1..SQ.size)
        foreach (j; A1..SQ.size)
          history[color][i][j] >>= 1;
    }

    if (undo.ms.killer[0] != move)
    {
      undo.ms.killer[1] = undo.ms.killer[0];
      undo.ms.killer[0] = move;
    }
  }

private:
  Undo[Limits.Plies] undos;
  u64[64][64][2] history;
  Undo * undo;
  Board B;
  Eval E;
  Hash H;
  u64 nodes;
  int max_ply;
  MS to_think;
  Timer timer;
}

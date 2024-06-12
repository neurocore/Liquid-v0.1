module solver_pvs;
import std.stdio, std.format;
import std.algorithm: min, max;
import types, solver, movelist;
import timer, board, moves, gen;
import consts, engine, piece;
import app, hash, eval;

class SolverPVS : Solver
{
  this(Engine engine)
  {
    super(engine);
    for (int i = 0; i < Limits.Plies; i++)
      undos[i].ml = new MoveList;
    undo = undos.ptr;
    B = new Board;
    E = new EvalSimple;
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

    //show_states(true);

    timer.start();
    auto ml = undo.ml;
    ml.clear();
    B.generate!0(ml);
    B.generate!1(ml);

    foreach (Move move; ml)
    {
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

    auto ml = undo.ml;
    ml.clear();
    B.generate!0(ml);
    B.generate!1(ml);

    u64 count = 0u;
    foreach (Move move; ml)
    {
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

  int pvs(int alpha, int beta, int depth)
  {
    if (depth <= 0) return qs(alpha, beta); // B.eval(E);
    //check_input();
    if (time_lack()) return 0;

    const bool in_pv = (beta - alpha) > 1;
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

    //HashEntry * he = H->get(B->hash(), alpha, beta, depth, ply;
    //if (alpha == beta) return alpha;
    //Move hash_move = he ? he->move : None;

    // Looking all legal moves

    auto ml = undo.ml;
    ml.clear();
    B.generate!0(ml);
    B.generate!1(ml);
    ml.value_moves(B, undo);

    foreach (Move move; ml)
    {
      if (!B.make(move, undo)) continue;

      legal++;
      int new_depth = depth - 1;
      bool reduced = false;

      if (legal == 1)
        val = -pvs(-beta, -alpha, new_depth);
      else
      {
        val = -pvs(-alpha - 1, -alpha, new_depth);
        if (val > alpha && val < beta)
          val = -pvs(-beta, -alpha, new_depth);
      }

      if (reduced && val >= beta)
        val = -pvs(-beta, -alpha, new_depth + 1);

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

    if (!legal)
    {
      int in_check = B.in_check();
      return in_check > 0 ? val : 0; // contempt();
    }

    //H->set(B->hash(), B->best(), alpha, hash_type, depth, ply;

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

    auto ml = undo.ml;
    ml.clear();
    B.generate!1(ml);
    ml.value_moves(B, undo); // TODO: add qs ordering

    foreach (Move move; ml)
    {
      if (!B.make(move, undo)) continue;

      int val = -qs(-beta, -alpha);

      B.unmake(move, undo);

      if (val >= beta) return beta;
      if (val > alpha) alpha = val;
    }

    return alpha;
  }

private:
  Undo[Limits.Plies] undos;
  Undo * undo;
  Board B;
  Eval E;
  bool analysis = false;
  u64 nodes;
  int max_ply;
  MS to_think;
  Timer timer;
}

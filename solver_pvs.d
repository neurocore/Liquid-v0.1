module solver_pvs;
import std.stdio, std.format;
import types, solver, movelist;
import timer, board, moves, gen;
import consts, engine, piece;

class SolverPVS : Solver
{
  private Undo[Limits.Plies] undos;
  private Undo * undo;

  this(Engine engine)
  {
    super(engine);
    undo = undos.ptr;
  }
  override Move get_move(MS time) { return Move(); }
  override void set(const ref Board board) {}
  override void stop() {}
  override void set_analysis(bool val) {}

  void show_states()
  {
    for (Undo * it = undos.ptr; it <= undo; it++)
    {
      writeln(it.state);
    }
    writeln(engine.board.get_state);
  }

  override u64 perft(int depth)
  {
    u64 count = 0u;

    writeln("-- Perft ", depth);
    writeln(engine.board);

    Timer timer;
    timer.start();
    auto ml = new MoveListSimple;
    engine.board.generate!0(ml);
    engine.board.generate!1(ml);

    foreach (Move move; ml)
    {
      if (!engine.board.make(move, undo)) continue;
      //writeln();
      //show_states();

      write(format("%v - ", move));

      u64 cnt = perft_inner(depth - 1);
      count += cnt;

      writeln(cnt);
      engine.board.unmake(move, undo);
    }

    i64 time = timer.getms();
    double knps = cast(double)count / (time + 1);

    writeln();
    writeln("Count: ", count);
    writeln("Time: ", time, " ms");
    writeln("Speed: ", knps, " knps");
    writeln("\n");

    return count;
  }

  u64 perft_inner(int depth)
  {
    if (depth <= 0) return 1;

    auto ml = new MoveListSimple;
    engine.board.generate!0(ml);
    engine.board.generate!1(ml);

    u64 count = 0u;
    foreach (Move move; ml)
    {
      if (!engine.board.make(move, undo)) continue;
      //writeln();
      //show_states();
      //write(format("    %v - ", move));

      count += depth > 1 ? perft_inner(depth - 1) : 1;

      //writeln(count);
      engine.board.unmake(move, undo);
    }
    return count;
  }
}

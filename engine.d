module engine;
import std.stdio, std.string;
import consts, command, moves;
import piece, board, protocol;
import solver, solver_pvs;
import timer, options;

class Engine
{
  Options options;

  this()
  {
    P = new UCI;
    B = new Board;
    S[0] = new SolverPVS(this);
    S[1] = new Reader(this);
    options = new Options;
  }

  Board board() { return B; }

  void start()
  {
    debug writeln(format("%v", options));

    new_game();
    debug writeln(B);

    bool running;
    do
    {
      running = read_input();
    }
    while (running);
  }

  bool read_input()
  {
    string str = readln().chomp();
    Cmd cmd = P.parse(str, options);
    cmd.execute(this);
    return !cmd.exit;
  }

  void new_game()
  {
    B.set();
  }

  void stop()
  {
    S[0].stop();
    S[1].stop();
  }

  void perft(int depth = 1)
  {
    S[0].perft(depth);
    S[1].perft(depth);
  }

  void set_debug(bool val)
  {
    options.flag_debug = val;
  }

  void set_pos(string fen)
  {
    stop();
    B.set(fen);
  }

  void do_move(Move move)
  {

  }

  void go(const TimeControl tc)
  {
    MS time = tc.full_time(B.to_move);

    foreach (solver; S)
    {
      solver.set(B);
      solver.set_analysis(tc.infinite);
      solver.get_move(time);
    }
  }

  void quit()
  {
    // No action
  }

private:
  Board B;
  Protocol P;
  Solver[2] S;
}

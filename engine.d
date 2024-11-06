module engine;
import std.concurrency, core.thread;
import std.stdio, std.string;
import std.algorithm: canFind;
import consts, command, moves;
import piece, board, protocol;
import solver, solver_pvs, utils;
import app, epd, timer, options;
import eval_smart;

class Engine
{
  Options options;

  this()
  {
    input = new shared Input(128);
    spawn(&async_input, input);

    P = new UCI;
    B = new Board;
    S[0] = new SolverPVS(this, input);
    S[1] = new Reader(this, input);
    options = new Options;
  }

  Board board() { return B; }

  void start()
  {
    //logf("%v", options);

    new_game();
    log(B);

    bool running;
    do
    {
      running = read_input();
    }
    while (running);
  }

  bool read_input()
  {
    if (!input.is_working) return false;
    string str = input.pop();
    if (str.length > 0)
    {
      Cmd cmd = P.parse(str, options);
      cmd.execute(this);
      return !cmd.exit;
    }

    Thread.sleep(10.msecs);
    return true;
  }

  BenchResult bench(string file)
  {
    BenchResult result = {0, 0};
    Mode old_mode = mode;
    mode = Mode.Bench;

    EPD problems = new EPD(file);

    foreach (P; problems.list)
    {
      result.total++;
      string num = format("%d", result.total);
      writef("%s | %s - ", num.rightJustify(5), P.id);

      stop();
      B.set(P.fen);
      S[0].set(B);
      Move move = S[0].get_move(9000);

      bool success = true;
      if (!P.best.empty)  success &=  P.best.canFind(move);
      if (!P.avoid.empty) success &= !P.avoid.canFind(move);

      write(success ? "correct" : "fail!  ");
      result.correct += success;

      write("  |  ", move, "  -- ");
      if (!P.best.empty) write(" ", P.best);
      if (!P.avoid.empty) write(" ~", P.avoid);
      writeln();
    }

    writeln("\nSolved: ", result);

    mode = old_mode;
    return result;
  }

  void print_message(string message)
  {
    debug
    {
      say(message);
    }
    else
    {
      if (options.flag_debug)
      {
        say("info string %s", message);
        stdout.flush();
      }
    }
  }

  void new_game()
  {
    B.set();
    S[0].set(B);
    S[1].set(B);
  }

  void stop()
  {
    S[0].stop();
    S[1].stop();
  }

  void perft(int depth = 1)
  {
    S[0].set(B);
    S[1].set(B);
    S[0].perft(depth);
    S[1].perft(depth);
  }

  void see(Move mv)
  {
    Move move = B.recognize(mv);

    if (!move.is_cap)
    {
      print_message(format!"%s is not a capture (result may be unpredictable)"(move));
    }

    int score = B.see(move);
    print_message(format!"SEE(%s) = %d"(move, score));
  }

  void eval()
  {
    int eval = B.eval(new EvalSmart);
    print_message(format!"Eval = %d"(eval));
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

  bool do_move(Move mv)
  {
    Undo * undo = undos.ptr;
    Move move = B.recognize(mv);
    if (move == Move.None) return false;
    return B.make(move, undo);
  }

  void go(const SearchParams sp)
  {
    MS time = sp.full_time(B.to_move);

    foreach (solver; S)
    {
      solver.set(B);
      solver.set_analysis(sp.infinite);
      solver.get_move(time);
    }
  }

private:
  shared Input input;
  Board B;
  Protocol P;
  Solver[2] S;
  Undo[2] undos;
}

module command;
import std.stdio, std.format;
import engine, moves, timer;
import piece, consts;

abstract class Cmd
{
  bool exit = false;
  void execute(Engine E);
}

struct SearchParams
{
  MS get_time(Color c) const { return time[c]; }
  MS get_inc(Color c) const { return inc[c]; }
  MS full_time(Color c) const { return time[c] + inc[c]; }

  MS[2] time = [Time.Def, Time.Def];
  MS[2] inc = [Time.Inc, Time.Inc];
  bool infinite = false;

  // not supported by engine
  Move[] searchmoves = [];
  bool ponder = false;
  int movestogo = Val.Inf;
  int depth = Val.Inf;
  int nodes = Val.Inf;
  int mate = Val.Inf;
  MS movetime = MS.max;
}


enum Bad { Empty, Unknown, Incomplete, Invalid }

class Cmd_Bad : Cmd
{
  private Bad bad;
  private string str;
  this(string str, Bad bad = Bad.Unknown)
  {
    this.str = str;
    this.bad = bad;
  }

  override void execute(Engine E)
  {
    if (bad == Bad.Empty) return;
    string err = format("%s", bad) ~ " command \"%s\"";
    string answer = format(err, str);

    E.print_message(answer);
  }
}

class Cmd_Response : Cmd
{
  private string str;
  this(string str) { this.str = str; }

  override void execute(Engine E)
  {
    writeln(str);
    stdout.flush();
  }
}

class Cmd_Debug : Cmd
{
  private bool flag_debug;
  this(bool val)
  {
    this.flag_debug = val;
  }

  override void execute(Engine E)
  {
    E.set_debug(flag_debug);
  }
}

class Cmd_Option : Cmd
{
  private string name;
  private string val;
  this(string name, string val)
  {
    this.name = name;
    this.val = val;
  }

  override void execute(Engine E)
  {
    E.options.set(name, val);
    debug writefln("%v", E.options);
  }
}

class Cmd_NewGame : Cmd
{
  override void execute(Engine E)
  {
    E.new_game();
  }
}

class Cmd_Stop : Cmd
{
  override void execute(Engine E)
  {
    E.stop();
  }
}

class Cmd_Perft : Cmd
{
  private int depth;
  this(int depth) { this.depth = depth; }
  
  override void execute(Engine E)
  {
    E.perft(depth);
  }
}

class Cmd_Pos : Cmd
{
  private string fen;
  private Move[] moves;

  this(string fen, Move[] moves)
  {
    this.fen = fen;
    this.moves = moves;
  }

  override void execute(Engine E)
  {
    E.set_pos(fen);
    foreach (move; moves)
    {
      if (!E.do_move(move))
      {
        E.print_message(format("can't perform move \"%s\"", move));
        break;
      }
    }

    writeln(E.board);
  }
}

class Cmd_Go : Cmd
{
  private SearchParams sp;
  this(SearchParams sp) { this.sp = sp; }

  override void execute(Engine E)
  {
    E.go(sp);
  }
}

class Cmd_Quit : Cmd
{
  this() { this.exit = true; }

  override void execute(Engine E)
  {
    debug writeln("Good to see you again");
  }
}

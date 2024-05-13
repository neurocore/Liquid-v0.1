module command;
import std.stdio, std.format;
import engine, moves, timer;

abstract class Cmd
{
  bool exit = false;
  void execute(Engine E);
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
  private TimeControl tc;
  this(TimeControl tc) { this.tc = tc; }

  override void execute(Engine E)
  {
    E.go(tc);
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

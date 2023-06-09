module command;
import std.stdio;
import engine, moves;

interface Cmd
{
  void execute(ref Engine E);
}

class Cmd_Unknown : Cmd
{
  string str;
  this(string str)
  {
    this.str = str;
  }

  void execute(ref Engine E)
  {
    writeln("Unknown command: ", str); // if debug?
  }
}

class Cmd_Response : Cmd
{
  string str;
  this(string str)
  {
    this.str = str;
  }

  void execute(ref Engine E)
  {
    writeln(str);
  }
}

class Cmd_NewGame : Cmd
{
  void execute(ref Engine E)
  {
    E.new_game();
  }
}

class Cmd_Pos : Cmd
{
  string fen;
  Move[] moves;

  this(string fen, Move[] moves)
  {
    this.fen = fen;
    this.moves = moves;
  }

  void execute(ref Engine E)
  {
    E.set_position(fen);
    foreach (move; moves)
      E.do_move(move);
  }
}

struct Time {}

class Cmd_Go : Cmd
{
  bool inf;
  Time time;

  this(bool inf, Time time)
  {
    this.inf = inf;
    this.time = time;
  }

  void execute(ref Engine E)
  {
    E.go(inf, time);
  }
}

class Cmd_Quit : Cmd
{
  void execute(ref Engine E)
  {
    E.quit();
  }
}

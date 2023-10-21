module command;
import std.stdio;
import engine, moves, timer;

abstract class Cmd
{
  bool exit = false;
  void execute(Engine E);
}


class Cmd_Unknown : Cmd
{
  private string str;
  this(string str) { this.str = str; }

  override void execute(Engine E)
  {
    debug writeln("Unknown command: \"", str, "\"");
  }
}

class Cmd_Response : Cmd
{
  private string str;
  this(string str) { this.str = str; }

  override void execute(Engine E)
  {
    writeln(str);
  }
}

class Cmd_NewGame : Cmd
{
  override void execute(Engine E)
  {
    E.new_game();
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
      E.do_move(move);
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
    writeln("Good to see you again");
    E.quit();
  }
}

module app;
import std.stdio;

enum Mode { Game, Bench, Tune };
Mode mode = Mode.Game;

void sayf(Mode m = Mode.Game, Char, A...)(Char[] fmt, A args)
{
  if (m == mode) writefln(fmt, args);
}

void say(Mode m = Mode.Game, A...)(A args)
{
  if (m == mode) writeln(args);
}

void logf(Mode m = Mode.Game, Char, A...)(Char[] fmt, A args)
{
  debug if (m == mode) writefln(fmt, args);
}

void log(Mode m = Mode.Game, A...)(A args)
{
  debug if (m == mode) writeln(args);
}

void errf(Char, A...)(Char[] fmt, A args)
{
  stderr.writefln(fmt, args);
}

void err(A...)(A args)
{
  stderr.writeln(args);
}

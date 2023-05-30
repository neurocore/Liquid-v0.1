module main;

import std.stdio;
import square;
import piece;
import moves;

void main()
{
  writeln("Chess engine Liquid v0.1 by Nick Kurgin (c) 2023");
  writefln("%s", Color.White.opp());

  Move move = Move(SQ.E2, SQ.F3, MT.NCapProm);

  writefln("%v", move);
  writeln(move);

  // readln();
}

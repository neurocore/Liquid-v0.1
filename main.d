module main;

import std.stdio;
import square, piece, moves, bitboard, board, magics;

version(Windows)
{
  import core.sys.windows.windows;
  import std.process:executeShell;
  extern(Windows) bool SetConsoleOutputCP(uint);
}

void main()
{
  version(Windows)
  {
    auto _ = SetConsoleOutputCP(65001);
  }

  writeln("Chess engine Liquid v0.1 by Nick Kurgin (c) 2023");
  writefln("%s", Color.White.opp());

  Move move = Move(SQ.E2, SQ.F3, MT.NCapProm);

  writefln("%v", move);
  writeln(move);

  Board board;
  board.set();
  writeln(board);

  auto bb = r_att(Empty, SQ.E4);
  writeln(bb);
  writeln(bb.to_bitboard());
  writeln(q_att(Empty, SQ.D3).to_bitboard());

  readln();
}

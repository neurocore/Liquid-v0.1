module main;

import std.stdio;
import square, piece, moves, consts, engine;
import protocol, bitboard, board, magics;

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

  writefln("Chess engine %s v%s by %s (c) 2023", Name, Vers, Auth);
  writefln("%s", Color.White.opp());

  writefln("Moves: %s", Limits.Moves);
  writefln("Plies: %s", Limits.Plies);

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

  auto engine = new Engine();
  engine.start();
  engine.destroy();
}

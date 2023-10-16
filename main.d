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

  writeln("A1 = ", A1);

  writefln("Chess engine %s v%s by %s (c) 2023", Name, Vers, Auth);
  writefln("%s", Color.White.opp());

  //info!SQ();

  version(linux) { writefln("I am on linux!"); }
  version(D_SIMD) { writefln("SIMD version"); }

  writefln("Moves: %s", Limits.Moves);
  writefln("Plies: %s", Limits.Plies);

  Move move = Move(E2, F3, MT.NCapProm);

  writefln("%v", move);
  writeln(move);

  Board board;
  board.set();
  writeln(board);

  auto bb = r_att(Empty, E4);
  writeln(bb);
  writeln(bb.to_bitboard());
  writeln(q_att(Empty, D3).to_bitboard());

  auto engine = new Engine();
  engine.start();
  engine.destroy();
}

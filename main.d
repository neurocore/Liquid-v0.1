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

  writefln("Chess engine %s v%s by %s (c) 2023\n", Name, Vers, Auth);

  //auto bb = r_att(Empty, E4);
  //writeln(bb);
  //writeln(bb.to_bitboard());
  //writeln(q_att(Empty, D3).to_bitboard());

  auto engine = new Engine();
  engine.start();
  engine.destroy();
}

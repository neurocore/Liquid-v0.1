module main;
import std.stdio;
import square, piece, moves, consts;
import engine, types, protocol, bitboard;
import app, board, magics, tables, kpk;

void main(string[] args)
{
  if (args.length > 1)
  {
    const string cmd = args[1];
    switch(cmd)
    {
      case "bench", "b": if (args.length > 2) mode = Mode.Bench; break;
      case "tune", "t": mode = Mode.Tuning; break;
      default: break;
    }
  }

  sayf("Chess engine %s v%s by %s (c) 2023\n", Name, Vers, Auth);

  debug
  {
    import consts;
    Board B = new Board;
    //B.set("5k2/p2P2pp/1b6/1p6/1Nn1P1n1/8/PPP4P/R2QK1NR w KQ -");

    // 8/8/8/1k6/8/8/K5P1/8 w - - 0 1; bm Kb3; c0 "Mate in 28"
    writeln("kpka(1)  = ", Kpk.probe!White(White, H2, B2, G5));
    writeln("kpk0(1)  = ", Kpk.probe!White(White, A2, G2, B5));
    writeln("kpk1(1)  = ", Kpk.probe!White(White, A5, A4, D4));
    writeln("kpk2(0)  = ", Kpk.probe!White(White, H8, H6, F8));
    writeln("kpk3(-1) = ", Kpk.probe!White(Black, A1, A2, G1));
    writeln("kpk4(0)  = ", Kpk.probe!White(Black, A5, A4, E6));

    //writeln(B);
    //writeln(B.see(Move("d7d8q")));

    //writefln("%(%(%16x\n%)\n\n%)", hash_key);
    //writefln("%(%16x\n%)", hash_castle);
    //writefln("%(%16x\n%)", hash_ep);
    //writefln("%(%16x\n%)", hash_wtm);
  }

  auto engine = new Engine();

  if (mode == Mode.Game)
    engine.start();
  else
    engine.bench(args[2]);
  engine.destroy();
}

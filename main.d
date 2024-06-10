module main;
import std.stdio;
import square, piece, moves, consts;
import engine, types, protocol, bitboard;
import app, board, magics, tables;

void main(string[] args)
{
  if (args.length > 1)
  {
    const string cmd = args[1];
    switch(cmd)
    {
      case "bench", "b": if (args.length > 2) mode = Mode.Bench; break;
      case "tune", "t": mode = Mode.Tune; break;
      default: break;
    }
  }

  sayf("Chess engine %s v%s by %s (c) 2023\n", Name, Vers, Auth);
  //say!(Mode.Bench)("this is benchmark");

  debug
  {
    Board B = new Board;
    B.set("3r3r/1k6/8/R1K5/4Q2Q/8/8/R6Q w - - 0 1");
    log(B);
    log("---");
    log("R1xa3+! -> ", B.san("R1xa3+!"));
    log("Qh4e1# -> ", B.san("Qh4e1#"));

    B.set("2r1k2r/2pn1pp1/1p3n1p/p3PP2/4q2B/P1P5/2Q1N1PP/R4RK1 w k -");
    log(B);
    log("---");
    log("exf6 -> ", B.san("exf6"));
  }

  auto engine = new Engine();

  if (mode == Mode.Game)
    engine.start();
  else
    engine.bench(args[2]);
  engine.destroy();
}

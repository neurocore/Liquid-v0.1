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
      case "tune", "t": mode = Mode.Tuning; break;
      default: break;
    }
  }

  sayf("Chess engine %s v%s by %s (c) 2023\n", Name, Vers, Auth);

  debug
  {
    //import std.conv;
    //import eval, utils;
    import hash, solver;
    writeln("Undo.size = ", Undo.sizeof);
    writeln("HashEntry.size = ", HashEntry.sizeof);
    writeln(__traits(isPOD, State));
    writeln(__traits(isPOD, HashEntry));
    writeln(Table.between(D1, F3).to_bitboard);

    //writeln(to!string(Term.MatKnight));
    //writeln(terms);

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

module main;

import std.stdio;
import square, piece, moves, consts, engine, types;
import protocol, bitboard, board, magics, tables;

void main()
{
  writefln("Chess engine %s v%s by %s (c) 2023\n", Name, Vers, Auth);

  import utils;
  auto data = parse_san!"Nxa1"("a4");
  writeln(data);

  Board B = new Board;
  B.set("3r3r/1k6/8/R1K5/4Q2Q/8/8/R6Q w - - 0 1");
  writeln(B);
  writeln("---");
  writeln(B.san("R1xa3+!"));
  writeln(B.san("Qh4e1#"));

  //writeln(State.sizeof);
  //writeln(uncastle[C4]);
  //writeln(uncastle[C5]);
  /*ulong occ = Bit << E2;
  writeln(b_att(occ, A6).to_bitboard());
  ulong bb = 18428448475101265920u;
  writeln(bb.to_bitboard());
  writeln(bb.shift_dl.to_bitboard());
  writeln(bb.shift_dr.to_bitboard());
  writeln(Table.between(E4, E4).to_bitboard());
  writeln(Table.between(E4, C1).to_bitboard());
  writeln(Table.between(E4, E8).to_bitboard());
  writeln(q_att(Empty, D3).to_bitboard());*/

  auto engine = new Engine();
  engine.start();
  engine.destroy();
}

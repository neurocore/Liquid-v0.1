module bitboard;
import core.bitop;
import types, square;

enum : u64
{
  Empty = 0x0000000000000000,
  Full  = 0xFFFFFFFFFFFFFFFF,
  Bit   = 0x0000000000000001,
  Light = 0xaa55aa55aa55aa55,
  Dark  = 0x55aa55aa55aa55aa,
}

SQ bitscan(u64 bb)
{
  return cast(SQ)bsf(bb);
}

u32 popcnt(u64 bb)
{
  return core.bitop.popcnt(bb);
}

u64 bit(SQ sq) { return Bit << cast(int)sq; }
u64 bits(SQ[] sqs)
{
  u64 bb = Empty;
  foreach (sq; sqs) bb |= sq.bit;
  return bb;
}

u64 lsb(u64 bb)  { return bb & (Empty - bb); }
u64 rlsb(u64 bb) { return bb & (bb - Bit); }

bool only_one(u64 bb) { return bb && !rlsb(bb); }

u64 msb(u64 bb)
{
  u32 n = 0;

  while (bb >>= 1) n++;
  return Bit << n;
}

bool get(u64 bb, SQ index)
{
  return cast(bool)(bb & index.bit);
}

u64 set(u64 bb, SQ index)
{
  return bb | index.bit;
}

u64 reset(u64 bb, SQ index)
{
  return bb & !index.bit;
}

string to_bitboard(u64 bb)
{
  import std.format;

  string str;
  foreach_reverse (int rank; 0..8)
  {
    str ~= format("%d | ", rank + 1);

    foreach (int file; 0..8)
    {
      SQ sq = to_sq(file, rank);
      str ~= bb.get(sq) ? 'x' : '.';
      str ~= ' ';
    }
    str ~= "\n";
  }
  str ~= "  +----------------   \n";
  str ~= "    a b c d e f g h\n\n";
  return str;
}

u64 shift_u(u64 bb) { return bb << 8; }
u64 shift_d(u64 bb) { return bb >> 8; }
u64 shift_l(u64 bb) { return (bb & ~FileA) >> 1; }
u64 shift_r(u64 bb) { return (bb & ~FileH) << 1; }

u64 shift_ul(u64 bb) { return (bb & ~FileA) << 7; }
u64 shift_ur(u64 bb) { return (bb & ~FileH) << 9; }
u64 shift_dl(u64 bb) { return (bb & ~FileA) >> 9; }
u64 shift_dr(u64 bb) { return (bb & ~FileH) >> 7; }

enum Dir {U, D, L, R, UL, UR, DL, DR}

u64 shift(u64 bb, Dir dir)
{
  final switch (dir)
  {
    case Dir.U : return shift_u(bb);
    case Dir.D : return shift_d(bb);
    case Dir.L : return shift_l(bb);
    case Dir.R : return shift_r(bb);
    case Dir.UL: return shift_ul(bb);
    case Dir.UR: return shift_ur(bb);
    case Dir.DL: return shift_dl(bb);
    case Dir.DR: return shift_dr(bb);
  }
}

@("Bitboard shifts") unittest
{
  import utils;

  equal("sht_full_u" , shift_u (Full), (Full & ~Rank1));
  equal("sht_full_d" , shift_d (Full), (Full & ~Rank8));
  equal("sht_full_l" , shift_l (Full), (Full & ~FileH));
  equal("sht_full_r" , shift_r (Full), (Full & ~FileA));
  equal("sht_full_ul", shift_ul(Full), (Full & ~FileH & ~Rank1));
  equal("sht_full_ur", shift_ur(Full), (Full & ~FileA & ~Rank1));
  equal("sht_full_dl", shift_dl(Full), (Full & ~FileH & ~Rank8));
  equal("sht_full_dr", shift_dr(Full), (Full & ~FileA & ~Rank8));

  equal("sht_to_0_u" , shift_u (Rank8), Empty);
  equal("sht_to_0_d" , shift_d (Rank1), Empty);
  equal("sht_to_0_l" , shift_l (FileA), Empty);
  equal("sht_to_0_r" , shift_r (FileH), Empty);
  equal("sht_to_0_ul", shift_ul(Rank8 | FileA), Empty);
  equal("sht_to_0_ur", shift_ur(Rank8 | FileH), Empty);
  equal("sht_to_0_dl", shift_dl(Rank1 | FileA), Empty);
  equal("sht_to_0_dr", shift_dr(Rank1 | FileH), Empty);
}

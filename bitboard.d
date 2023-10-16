module bitboard;
import square;

enum : ulong
{
  Empty    = 0x0000000000000000,
  Full     = 0xFFFFFFFFFFFFFFFF,
  Bit      = 0x0000000000000001,
  Light    = 0xaa55aa55aa55aa55,
  Dark     = 0x55aa55aa55aa55aa,

  Debruijn = 0x03f79d71b4cb0a89,
}

immutable uint[64] bitscan64 =
[
   0,  1, 48,  2, 57, 49, 28,  3,
  61, 58, 50, 42, 38, 29, 17,  4,
  62, 55, 59, 36, 53, 51, 43, 22,
  45, 39, 33, 30, 24, 18, 12,  5,
  63, 47, 56, 27, 60, 41, 37, 16,
  54, 35, 52, 21, 44, 32, 23, 11,
  46, 26, 40, 15, 34, 20, 31, 10,
  25, 14, 19,  9, 13,  8,  7,  6
];

immutable uint[0xFFFF] LUT = () @safe pure nothrow
{
  uint[0xFFFF] arr;
  foreach (ushort i; 0 .. 0xFFFF)
  {
    arr[i] = 0;
    ushort n = i;
    while (n != 0)
    {
      arr[i]++;
      n &= n - 1;
    }
  }
  return arr;
}();

ulong bit(SQ sq) { return Bit << cast(int)sq; }
ulong bits(SQ[] sqs)
{
  ulong bb = Empty;
  foreach (sq; sqs) bb |= bit(sq);
  return bb;
}

ulong lsb(ulong bb)  { return bb & (Empty - bb); }
ulong rlsb(ulong bb) { return bb & (bb - Bit); }

ulong msb(ulong bb)
{
  uint n = 0;

  while (bb >>= 1) n++;
  return Bit << n;
}

bool get(ulong bb, ubyte index)
{
  return cast(bool) (bb & (Bit << index));
}

ulong set(ulong bb, ubyte index)
{
  return bb | (Bit << index);
}

ulong reset(ulong bb, ubyte index)
{
  return bb & !(Bit << index);
}

uint bitscan(ulong bb)
{
  ushort i = (bb.lsb() * Debruijn) >> 58;
  return bitscan64[i];
}

uint popcnt(ulong bb)
{
  ushort h0 =  bb >> 48;
  ushort h1 = (bb >> 32) & 0xFFFF;
  ushort h2 = (bb >> 16) & 0xFFFF;
  ushort h3 =  bb        & 0xFFFF;
  return LUT[h0] + LUT[h1] + LUT[h2] + LUT[h3];
}

string to_bitboard(ulong bb)
{
  import std.format;

  string str;
  foreach_reverse (int rank; 0..8)
  {
    str ~= format("%d | ", rank + 1);

    foreach (int file; 0..8)
    {
      SQ sq = sq(file, rank);
      str ~= bb.get(sq) ? 'x' : '.';
      str ~= ' ';
    }
    str ~= "\n";
  }
  str ~= "  +----------------   \n";
  str ~= "    a b c d e f g h\n\n";
  return str;
}

ulong shift_u(ulong bb) { return bb << 8; }
ulong shift_d(ulong bb) { return bb >> 8; }
ulong shift_l(ulong bb) { return (bb & ~FileA) >> 1; }
ulong shift_r(ulong bb) { return (bb & ~FileH) << 1; }

ulong shift_ul(ulong bb) { return (bb & ~FileA) << 7; }
ulong shift_ur(ulong bb) { return (bb & ~FileH) << 9; }
ulong shift_dl(ulong bb) { return (bb & ~FileA) >> 9; }
ulong shift_dr(ulong bb) { return (bb & ~FileH) >> 7; }

enum Dir {U, D, L, R, UL, UR, DL, DR}

ulong shift(ulong bb, Dir dir)
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

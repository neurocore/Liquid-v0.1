module square;
import std.algorithm, std.conv, std.string, std.range;
import utils;

enum SQ : ubyte
{
  A1, B1, C1, D1, E1, F1, G1, H1,
  A2, B2, C2, D2, E2, F2, G2, H2,
  A3, B3, C3, D3, E3, F3, G3, H3,
  A4, B4, C4, D4, E4, F4, G4, H4,
  A5, B5, C5, D5, E5, F5, G5, H5,
  A6, B6, C6, D6, E6, F6, G6, H6,
  A7, B7, C7, D7, E7, F7, G7, H7,
  A8, B8, C8, D8, E8, F8, G8, H8,
  size, None
}

string toString(SQ sq)
{
  char fileChar = to!char('a' + sq.file);
  char rankChar = to!char('1' + sq.rank);
  return to!string(fileChar) ~ to!string(rankChar);
}

SQ toSQ(string str)
{
  if (str.length < 2) return SQ.None;
  int rank = str[0] - 'a';
  int file = str[1] - '1';
  return sq(file, rank);
}

SQ opBinary(string op : "+")(SQ a, int shift)
{
  return cast(SQ) (a + shift);
}

SQ opBinary(string op : "-")(SQ a, int shift)
{
  return cast(SQ) (a - shift);
}

int rank(const SQ x) { return x >> 3; }
int file(const SQ x) { return x & 7; }

SQ sq(const int f, const int r)
{
  if (0 <= f && f < 8 && 0 <= r && r < 8)
    return cast(SQ) ((r << 3) + f);
  else return SQ.None;
}

SQ to_sq(string s)
{
  return s.length > 1 ? sq(s[0] - 'a', s[1] - '1') : SQ.None;
}

enum File : ulong
{
  A = 0x0101010101010101,
  B = 0x0202020202020202,
  C = 0x0404040404040404,
  D = 0x0808080808080808,
  E = 0x1010101010101010,
  F = 0x2020202020202020,
  G = 0x4040404040404040,
  H = 0x8080808080808080,
  size
}

File file(const int i)
{
  static immutable File[] arr =
  [
    File.A, File.B, File.C, File.D,
    File.E, File.F, File.G, File.H
  ];
  return arr[i];
}

enum Rank : ulong
{
  _1 = 0x00000000000000ffUL,
  _2 = 0x000000000000ff00UL,
  _3 = 0x0000000000ff0000UL,
  _4 = 0x00000000ff000000UL,
  _5 = 0x000000ff00000000UL,
  _6 = 0x0000ff0000000000UL,
  _7 = 0x00ff000000000000UL,
  _8 = 0xff00000000000000UL,
  size
}

Rank rank(const int i)
{
  static immutable Rank[] arr =
  [
    Rank._1, Rank._2, Rank._3, Rank._4,
    Rank._5, Rank._6, Rank._7, Rank._8
  ];
  return arr[i];
}

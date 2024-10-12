module square;
import std.algorithm, std.conv, std.string, std.range;
import types, utils, bitboard;

enum SQ : u8
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
mixin(GenAliases!SQ);

string toString(SQ sq)
{
  char fileChar = to!char('a' + sq.file);
  char rankChar = to!char('1' + sq.rank);
  return to!string(fileChar) ~ to!string(rankChar);
}

SQ toSQ(string str)
{
  if (str.length < 2) return SQ.None;
  int file = str[0] - 'a';
  int rank = str[1] - '1';
  return to_sq(file, rank);
}

SQ add(SQ a, int shift)
{
  int b = a + shift;
  return b > H8 ? SQ.None : cast(SQ)b;
}

SQ sub(SQ a, int shift)
{
  int b = a - shift;
  return b < A1 ? SQ.None : cast(SQ)b;
}

int rank(const SQ x) { return x >> 3; }
int file(const SQ x) { return x & 7; }

SQ to_sq(const int f, const int r)
{
  if (0 <= f && f < 8 && 0 <= r && r < 8)
    return cast(SQ) ((r << 3) + f);
  else return SQ.None;
}

SQ to_sq(string s)
{
  return s.length > 1 ? to_sq(s[0] - 'a', s[1] - '1') : SQ.None;
}

SQ opp(SQ sq)
{
  return to_sq(sq.file, 7 - sq.rank);
}

string to_str(SQ sq)
{
  if (sq == SQ.None) return "-";
  else return sq.toString;
}

struct File
{
  u64 bb;
  alias bb this;
}

static immutable File FileA = {0x0101010101010101UL};
static immutable File FileB = {0x0202020202020202UL};
static immutable File FileC = {0x0404040404040404UL};
static immutable File FileD = {0x0808080808080808UL};
static immutable File FileE = {0x1010101010101010UL};
static immutable File FileF = {0x2020202020202020UL};
static immutable File FileG = {0x4040404040404040UL};
static immutable File FileH = {0x8080808080808080UL};

static immutable File[] file_bb =
[
  FileA, FileB, FileC, FileD,
  FileE, FileF, FileG, FileH
];

struct Rank
{
  u64 bb;
  alias bb this;
}

static immutable Rank Rank1 = {0x00000000000000ffUL};
static immutable Rank Rank2 = {0x000000000000ff00UL};
static immutable Rank Rank3 = {0x0000000000ff0000UL};
static immutable Rank Rank4 = {0x00000000ff000000UL};
static immutable Rank Rank5 = {0x000000ff00000000UL};
static immutable Rank Rank6 = {0x0000ff0000000000UL};
static immutable Rank Rank7 = {0x00ff000000000000UL};
static immutable Rank Rank8 = {0xff00000000000000UL};

static immutable Rank[] rank_bb =
[
  Rank1, Rank2, Rank3, Rank4,
  Rank5, Rank6, Rank7, Rank8
];

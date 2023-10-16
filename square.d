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

// i surrender

alias A1 = SQ.A1;
alias A2 = SQ.A2;
alias A3 = SQ.A3;
alias A4 = SQ.A4;
alias A5 = SQ.A5;
alias A6 = SQ.A6;
alias A7 = SQ.A7;
alias A8 = SQ.A8;

alias B1 = SQ.B1;
alias B2 = SQ.B2;
alias B3 = SQ.B3;
alias B4 = SQ.B4;
alias B5 = SQ.B5;
alias B6 = SQ.B6;
alias B7 = SQ.B7;
alias B8 = SQ.B8;

alias C1 = SQ.C1;
alias C2 = SQ.C2;
alias C3 = SQ.C3;
alias C4 = SQ.C4;
alias C5 = SQ.C5;
alias C6 = SQ.C6;
alias C7 = SQ.C7;
alias C8 = SQ.C8;

alias D1 = SQ.D1;
alias D2 = SQ.D2;
alias D3 = SQ.D3;
alias D4 = SQ.D4;
alias D5 = SQ.D5;
alias D6 = SQ.D6;
alias D7 = SQ.D7;
alias D8 = SQ.D8;

alias E1 = SQ.E1;
alias E2 = SQ.E2;
alias E3 = SQ.E3;
alias E4 = SQ.E4;
alias E5 = SQ.E5;
alias E6 = SQ.E6;
alias E7 = SQ.E7;
alias E8 = SQ.E8;

alias F1 = SQ.F1;
alias F2 = SQ.F2;
alias F3 = SQ.F3;
alias F4 = SQ.F4;
alias F5 = SQ.F5;
alias F6 = SQ.F6;
alias F7 = SQ.F7;
alias F8 = SQ.F8;

alias G1 = SQ.G1;
alias G2 = SQ.G2;
alias G3 = SQ.G3;
alias G4 = SQ.G4;
alias G5 = SQ.G5;
alias G6 = SQ.G6;
alias G7 = SQ.G7;
alias G8 = SQ.G8;

alias H1 = SQ.H1;
alias H2 = SQ.H2;
alias H3 = SQ.H3;
alias H4 = SQ.H4;
alias H5 = SQ.H5;
alias H6 = SQ.H6;
alias H7 = SQ.H7;
alias H8 = SQ.H8;

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

struct File
{
  ulong bb;
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
  ulong bb;
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

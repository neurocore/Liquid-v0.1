module moves;
import std.string;
import square, piece, utils;

/// Move Type
enum MT : ushort
{
  Quiet,     // PC12 (Promotion, Capture, Flag_1, Flag_2)
  Pawn2,
  KCastle,   // 0010
  QCastle,   // 0011
  Cap,       // 0100
  Ep,        // 0101
  NProm = 8, // 1000
  BProm,     // 1001
  RProm,     // 1010
  QProm,     // 1011
  NCapProm,  // 1100
  BCapProm,  // 1101
  RCapProm,  // 1110
  QCapProm,  // 1111
  size       //   ^^ = (promoted - 1)
}

struct Move // newtype paradigm
{
  private ushort move;
  alias move this;

  enum
  {
    None = Move(SQ.A1, SQ.A1),
    Null = Move(SQ.B1, SQ.B1),
  }

  this(SQ from, SQ to, MT mt = MT.Quiet)
  {
    move = cast(ushort) (from | (to << 6) | (mt << 12));
  }

  this(string str)
  {
    if (str.length < 4) move = None;
    else
    {
      SQ from = str[0..2].toSQ();
      SQ to   = str[2..4].toSQ();
      move = Move(from, to);
    }
  }

  SQ from() const @property
  {
    return cast(SQ) (move & 63);
  }

  SQ to() const @property
  {
    return cast(SQ) ((move >> 6) & 63);
  }

  MT mt() const @property
  {
    return cast(MT) (move >> 12);
  }

  bool is_empty() const @property { return move == None || move == Null; }

  void toString(scope Sink sink, Fmt fmt) const
  {
    if (fmt.spec == 'v') // verbose - for debug
    {
      if      (move == None) sink("[None]");
      else if (move == Null) sink("[Null]");
      else if (mt == MT.KCastle) sink("o-o");
      else if (mt == MT.QCastle) sink("o-o-o");
      else
      {
        sink(from.toString());
        if (mt.is_cap) sink("x");
        sink(to.toString());
        if (mt.is_prom) sink(mt.promoted.toString());
        if (mt.is_ep) sink("ep");
      }
    }
    else // usual output for communication with GUI
    {
      sink(from.toString() ~ to.toString());
    }
  }
}

bool is_cap(MT mt) { return !!(mt & MT.Cap); }
bool is_prom(MT mt) { return !!(mt & MT.NProm); }
bool is_attack(MT mt) { return !!(mt & MT.NCapProm); }

bool is_ep(MT mt)     { return mt == MT.Ep; }
bool is_pawn2(MT mt)  { return mt == MT.Pawn2; }
bool is_castle(MT mt) { return mt == MT.KCastle || mt == MT.QCastle; }

PieceType promoted(MT mt) { return cast(PieceType) (1 + (mt & 3)); }

enum Castling
{
  BK = 1 << 0,
  BQ = 1 << 1,
  WK = 1 << 2,
  WQ = 1 << 3,
  ALL = BK | BQ | WK | WQ
}

Castling to_castling(const char c)
{
  size_t i = indexOf("kKqQ", c);
  if (i == -1) return Castling.init;
  return cast(Castling) (1 << i);
}

immutable int[64] uncastle = () @safe pure nothrow
{
  uint[64] arr;
  foreach (SQ i; SQ.A1 .. SQ.size)
    arr[i] = Castling.ALL;

  arr[SQ.A1] ^= Castling.WQ;
  arr[SQ.E1] ^= Castling.WQ | Castling.WK;
  arr[SQ.H1] ^= Castling.WK;
  arr[SQ.A8] ^= Castling.BQ;
  arr[SQ.E8] ^= Castling.BQ | Castling.BK;
  arr[SQ.H8] ^= Castling.BK;

  return arr;
}();

enum Order
{
  Hash    = +0x40000000,
  WinCap  = +0x30000000,
  EqCap   = +0x20000000,
  Killer1 = +0x10000001,
  Killer2 = +0x10000000,
  Castle  = +0x00000100,
  Quiet   =  0x00000000,
  BadCap  = -0x10000000,
}

module moves;
import std.string;
import types, square, piece;
import utils, bitboard;

/// Move Type
enum MT : u16
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
  private u16 move;
  alias move this;

  enum
  {
    None = Move(SQ.A1, SQ.A1),
    Null = Move(SQ.B1, SQ.B1),
  }

  this(SQ from, SQ to, MT mt = MT.Quiet)
  {
    move = cast(u16) (from | (to << 6) | (mt << 12));
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

  bool is_empty() const @property
  {
    return move == None || move == Null;
  }

  bool opCast(T)()
  {
    if (is(T == bool)) return !is_empty;
  }

  void toString(scope Sink sink, Fmt fmt) const
  {
    if (fmt.spec == 'v') // verbose - for debug
    {
      if      (move == None) sink("[None]");
      else if (move == Null) sink("[Null]");
      else if (mt == MT.KCastle) sink("O-O");
      else if (mt == MT.QCastle) sink("O-O-O");
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
PieceType promoted(Move move) { return promoted(move.mt); }
Piece promoted(MT mt, Color col) { return to_piece(promoted(mt), col); }
Piece promoted(Move move, Color col) { return promoted(move.mt, col); }

enum Castling : u8
{
  NO = 0,
  BK = 1 << 0,
  WK = 1 << 1,
  BQ = 1 << 2,
  WQ = 1 << 3,
  ALL = BK | BQ | WK | WQ
}

enum Span
{
  BK = [F8, G8].bits(),
  WK = [F1, G1].bits(),
  BQ = [B8, C8, D8].bits(),
  WQ = [B1, C1, D1].bits(),
}

Castling to_castling(const char c)
{
  size_t i = indexOf("kKqQ", c);
  if (i < 0 || i > 3) return Castling.init;
  return cast(Castling) (1 << i);
}

string to_string(Castling castling, string fill = "")
{
  string str;
  str ~= castling & Castling.WK ? "K" : fill;
  str ~= castling & Castling.WQ ? "Q" : fill;
  str ~= castling & Castling.BK ? "k" : fill;
  str ~= castling & Castling.BQ ? "q" : fill;
  return str;
}

immutable int[64] uncastle = () @safe pure nothrow
{
  u32[64] arr;
  foreach (SQ i; A1 .. SQ.size)
    arr[i] = Castling.ALL;

  arr[A1] ^= Castling.WQ;
  arr[E1] ^= Castling.WQ | Castling.WK;
  arr[H1] ^= Castling.WK;
  arr[A8] ^= Castling.BQ;
  arr[E8] ^= Castling.BQ | Castling.BK;
  arr[H8] ^= Castling.BK;

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

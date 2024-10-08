module piece;
import std.algorithm, std.conv, std.string;
import utils, types;

enum Color : u8 { Black, White, size, None }
mixin(GenAliases!Color);

Color opp(const Color c) { return cast(Color) !c; }

Color to_color(const char c)
{
  size_t i = indexOf("bw", c);
  if (i == -1) i = Color.size;
  return cast(Color) i;
}

enum PieceType : u8 { Pawn, Knight, Bishop, Rook, Queen, King, size, None }
mixin(GenAliases!PieceType);

string toString(PieceType pt)
{
  switch (pt)
  {
    case Pawn:   return "p";
    case Knight: return "n";
    case Bishop: return "b";
    case Rook:   return "r";
    case Queen:  return "q";
    case King:   return "k";
    default:     return "";
  }
}

PieceType to_piecetype(const char c)
{
  size_t i = indexOf("pnbrqk", c, CaseSensitive.no);
  if (i == -1) return PieceType.None;
  return cast(PieceType) i;
}

char to_char(const PieceType p) { return "pnbrqk."[p]; }

enum Piece : u8 { BP, WP, BN, WN, BB, WB, BR, WR, BQ, WQ, BK, WK, size, NOP }
mixin(GenAliases!Piece);

Piece to_piece(const PieceType pt, const Color c)
{
  return cast(Piece) (2 * pt + c);
}

Piece to_piece(const char c)
{
  size_t i = indexOf("pPnNbBrRqQkK.", c);
  if (i == -1) return Piece.NOP;
  return cast(Piece) i;
}

Piece pie(char piece)(Color color)
{
  PieceType pt = to_piecetype(piece);
  Piece p = to_piece(pt, color);
  return p;
}

char to_char(const Piece p)
{
  return "pPnNbBrRqQkK.."[p];
}

Color color(const Piece p)
{
  return p >= Piece.size
       ? Color.None
       : cast(Color) (p & 1);
}

PieceType pt(const Piece p)
{
  return cast(PieceType) (p >> 1);
}

bool be(PieceType pt)(const Piece p)
{
  return (p >> 1) == pt;
}

Piece opp(const Piece p)
{
  return cast(Piece) (p ^ 1);
}

Piece of(const Piece p, const Color c)
{
  return cast(Piece) (p ^ (cast(int)c));
}

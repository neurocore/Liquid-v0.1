module piece;
import std.algorithm, std.conv, std.string;

enum Color : ubyte { Black, White, size, None }

Color opp(const Color c) { return cast(Color) !c; }

Color to_color(const char c)
{
  size_t i = indexOf("bw", c);
  if (i == -1) i = Color.size;
  return cast(Color) i;
}

enum PieceType : ubyte
{
  Pawn, Knight, Bishop, Rook, Queen, King, size
}

string toString(PieceType pt)
{
  final switch (pt)
  {
    case PieceType.Pawn:   return "p";
    case PieceType.Knight: return "n";
    case PieceType.Bishop: return "b";
    case PieceType.Rook:   return "r";
    case PieceType.Queen:  return "q";
    case PieceType.King:   return "k";
    case PieceType.size:   return "";
  }
}

PieceType to_piecetype(const char c)
{
  size_t i = indexOf(".pnbrqk", c, CaseSensitive.no);
  if (i == -1) i = 0;
  return cast(PieceType) i;
}

char to_char(const PieceType p) { return "pnbrqk."[p]; }

enum Piece : ubyte { BP, WP, BN, WN, BB, WB, BR, WR, BQ, WQ, BK, WK, NOP, size }

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

char to_char(const Piece p)
{
  return "pPnNbBrRqQkK.."[p];
}

Color color(const Piece p)
{
  return p == Piece.NOP
       ? Color.None
       : cast(Color) (p % 1);
}

PieceType pt(const Piece p)
{
  return cast(PieceType) (p >> 1);
}

Piece opp(const Piece p)
{
  return cast(Piece) (p ^ 1);
}

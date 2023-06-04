module board;
import std.array, std.ascii, std.string, std.conv;
import bitboard, square, consts;
import piece, moves, utils;

struct Board
{
public:

  struct Undo
  {
    SQ ep = SQ.None;
    Piece cap = Piece.NOP;
    Castling castling;
    int fifty;
    // Val pst;
    // ulong hash;
    Move curr, best;
    Move[2] killer;
  }

  int ply = 0;
  Color color = Color.White;
  ulong[Piece.size] piece;
  ulong[Color.size] occ;
  Piece[SQ.size] square;
  Undo[Limits.Plies] undo;
  // int[Piece.size][SQ.size] history;

  void clear()
  {
    foreach (p; Piece.BP .. Piece.size) piece[p] = 0;
    foreach (c; Color.Black .. Color.size) occ[c] = Empty;
    foreach (x; SQ.A1 .. SQ.size) square[x] = Piece.NOP;
    undo[0] = Undo.init;
    color = Color.White;
    ply = 0;
  }

  Piece opIndex(const SQ sq) const
  {
		return square[sq];
	}

  int fifty() const @property
  {
		return undo[ply].fifty;
	}

  void place(bool full = false)(SQ sq, Piece p)
  {
    import std.stdio;
    piece[p]     ^= (Bit << sq);
    occ[p.color] ^= (Bit << sq);
    square[sq]    = p;

    static if (full)
    {
      // state.pst += E->pst[p][sq];
      // state.mkey += matkey[p];

      // state.hash ^= hash_key[p][sq];
    }
  }

  void remove(bool full = false)(SQ sq, Piece p)
  {
    piece[p]     ^= (Bit << sq);
    occ[p.color] ^= (Bit << sq);
    square[sq]    = Piece.NOP;

    static if (full)
    {
      // state->pst -= E->pst[p][square];
      // state->mkey -= matkey[p];

      // state->hash ^= hash_key[p][square];
    }
  }

  void set(string fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  {
    SQ sq = SQ.A8;

    string[] parts = fen.split();
    if (parts.length < 4) return error("Too few data in fen string");

    clear();

    foreach (char ch; parts[0]) // parsing main part
    {
      if (isDigit(ch)) sq += ch - '0';
      else
      {
        Piece p = ch.to_piece();
        if (p == Piece.NOP) continue;

        place(sq, p);
        sq++;
      }

      if (!(sq & 7)) // row wrap
      {
        sq -= 16;
        if (sq < 0) break;
      }
    }

    todo("calc hash key");

    foreach (ch; parts[1]) // parsing color
    {
      color = ch.to_color();
    }

    foreach (ch; parts[2]) // parsing castling
    {
      undo[ply].castling |= ch.to_castling();
    }

    undo[ply].ep = parts[3].toSQ(); // en passant

    if (parts.length < 5) return;

    if (isNumeric(parts[4])) // fifty rule counter
      undo[ply].fifty = to!int(parts[4]);

    if (parts.length < 6) return;

    // full move counter - no need
  }

  string to_fen()
  {
    string fen;

    

    return fen;
  }

  string toString()
  {
    import std.range, std.uni, std.utf, std.stdio;
    static immutable wchar[] pieces = ['♟', '♙', '♞', '♘', '♝', '♗', '♜', '♖', '♛', '♕', '♚', '♔', '.', '.'];
    string str;
    foreach_reverse (int rank; 0..8)
    {
      str ~= format("%d ", rank + 1);

      foreach (int file; 0..8)
      {
        SQ sq = sq(file, rank);
        Piece p = square[sq];

        str ~= pieces[p];
        str ~= ' ';
      }
      str ~= "\n";
    }
    str ~= "  a b c d e f g h\n\n";
    return str;
  }

  
}



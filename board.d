module board;
import std.array, std.ascii, std.string, std.conv;
import bitboard, square, consts;
import piece, moves, utils;

class Board
{
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

  Color to_move() const
  {
    return color;
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
    SQ sq = A8;

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

  override string toString()
  {
    import std.range, std.stdio;
    string str;
    foreach_reverse (int rank; 0..8)
    {
      str ~= format("%d | ", rank + 1);

      foreach (int file; 0..8)
      {
        SQ sq = sq(file, rank);
        Piece p = square[sq];
        str ~= to_char(p);
        str ~= ' ';
      }
      str ~= "\n";
    }
    str ~= "  +----------------   ";
    str ~= to!string(color) ~ " to move\n";
    str ~= "    a b c d e f g h\n\n";
    return str;
  }

  // Just playing around
  void ForBB(Func)(ulong bb, Func func)
  {
    for (ulong bb = piece[p]; bb; bb = rlsb(bb))
    {
      SQ s = bitscan(bb);
      func();
    }
  }

  void gen(PieceType pt, bool captures)()
  {
    MoveList & ml = state.ml;

    Piece p = to_piece(pt, color);
    ulong mask = att_mask!captures();

    for (ulong bb = piece[p]; bb; bb = rlsb(bb))
    {
      SQ s = bitscan(bb);
      for (ulong att = attack(p, s) & mask; att; att = rlsb(att))
      {
        ml.add_move(s, bitscan(att), captures ? MT.Cap : MT.Quiet);
      }
    }
  }

  void generate(bool captures)()
  {
    MoveList ml = state.ml;

    const ulong me = occ[color];
    const ulong opp = occ[color.opp()];
    const ulong o = me | opp;

    gen(PieceType.Knight, captures)();
    gen(PieceType.Bishop, captures)();
    gen(PieceType.Rook,   captures)();
    gen(PieceType.Queen,  captures)();
    gen(PieceType.King,   captures)();

    static if (!captures) // Castlings
    {
      if (color)
      {
        if ((state.castling & Castling.WK) && !(o & Span.WK))
          ml.add_move(E1, G1, MT.KCastle);

        if ((state.castling & Castling.WQ) && !(o & Span.WQ))
          ml.add_move(E1, C1, MT.QCastle);
      }
      else
      {
        if ((state.castling & Castling.BK) && !(o & Span.BK))
          ml.add_move(E8, G8, MT.KCastle);

        if ((state.castling & Castling.BQ) && !(o & Span.BQ))
          ml.add_move(E8, C8, MT.QCastle);
      }
    }

    Piece p = BP + color;
    if (color)
    {
      // TODO: apply static if on captures and quiets

      static if (!captures) // Forward & promotion
      {
        for (ulong bb = piece[p] & shift_d(~o); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (y_(s) == 6) ml.add_prom(s, s + 8);
          else            ml.add_move(s, s + 8);
        }
      }

      static if (captures) // Attacks
      {
        for (ulong bb = piece[p] & shift_dl(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (y_(s) == 6) ml.add_capprom(s, s + 7);
          else            ml.add_move(s, s + 7, MT.Cap);
        }

        for (ulong bb = piece[p] & shift_dr(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (y_(s) == 6) ml.add_capprom(s, s + 9);
          else            ml.add_move(s, s + 9, MT.Cap);
        }
      }

      static if (!captures) // Double move
      for (ulong bb = piece[p] & (~o >> 8) & (~o >> 16); bb; bb = rlsb(bb))
      {
        SQ s = bitscan(bb);
        if (y_(s) == 1) ml.add_move(s, s + 16, MT.Pawn2);
      }

      static if (captures)
      if (state.ep)
      {
        for (ulong bb = piece[p] & moves(WP - color, state.ep); bb; bb = rlsb(bb))
        {
          ml.add_move(bitscan(bb), state.ep, MT.Ep);
        }
      }
    }
    else
    {
      static if (!captures)
      for (ulong bb = piece[p] & shift_u(~o); bb; bb = rlsb(bb)) // Forward & promotion
      {
        SQ s = bitscan(bb);
        if (y_(s) == 1) ml.add_prom(s, s - 8);
        else            ml.add_move(s, s - 8);
      }

      static if (captures)
      {
        for (ulong bb = piece[p] & shift_ur(opp); bb; bb = rlsb(bb)) // Attacks
        {
          SQ s = bitscan(bb);
          if (y_(s) == 1) ml.add_capprom(s, s - 7);
          else            ml.add_move(s, s - 7, MT.Cap);
        }

        for (ulong bb = piece[p] & shift_ul(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (y_(s) == 1) ml.add_capprom(s, s - 9);
          else            ml.add_move(s, s - 9, MT.Cap);
        }
      }

      static if (!captures)
      for (ulong bb = piece[p] & (~o << 8) & (~o << 16); bb; bb = rlsb(bb)) // Double move
      {
        SQ s = bitscan(bb);
        if (y_(s) == 6) ml.add_move(s, s - 16, MT.Pawn2);
      }

      static if (captures)
      if (state.ep)
      {
        for (ulong bb = piece[p] & moves(WP - color, state.ep); bb; bb = rlsb(bb))
        {
          ml.add_move(bitscan(bb), state.ep, MT.Ep);
        }
      }
    }
  }
}

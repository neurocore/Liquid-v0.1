module board;
import std.array, std.ascii, std.string, std.conv;
import bitboard, square, consts;
import movelist, types, piece, solver;
import moves, utils, magics, tables;

struct State // 4 bytes
{
  align (1):
  SQ ep = SQ.None;
  Piece cap = Piece.NOP;
  Castling castling = Castling.ALL;
  u8 fifty = 0;
}

class Board
{
  void clear()
  {
    foreach (p; Piece.BP .. Piece.size) piece[p] = 0;
    foreach (c; Color.Black .. Color.size) occ[c] = Empty;
    foreach (x; SQ.A1 .. SQ.size) square[x] = Piece.NOP;
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
		return state.fifty;
	}

  State get_state() const @property
  {
    return state;
  }

  //Piece bb(char piece)(Color color)
  //{
  //  return mixin("piece " ~ op ~ " rhs");
  //}

  //Piece pie()
  //{
  //  return;
  //}

  bool is_attacked(SQ king, u64 occupied) const
  {
    Color col = color;
    if (Table.moves(cast(Piece)(WN ^ col), king) & piece[BN ^ col]) return true; // Knights
    if (Table.moves(cast(Piece)(WP ^ col), king) & piece[BP ^ col]) return true; // Pawns
    if (Table.moves(cast(Piece)(WK ^ col), king) & piece[BK ^ col]) return true; // King

    if (b_att(occupied, king) & (piece[BB ^ col] | piece[BQ ^ col])) return true; // Bishops & queens
    if (r_att(occupied, king) & (piece[BR ^ col] | piece[BQ ^ col])) return true; // Rooks & queens

    return false;
  }

  bool in_check(int opposite) const
  {
    Piece p = to_piece(King, cast(Color)(color ^ opposite));
    SQ king = bitscan(piece[p]);
    return is_attacked(king, occ[0] | occ[1]);
  }

  void place(bool full = false)(SQ sq, Piece p)
  {
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

  void remove(bool full = false)(SQ sq)
  {
    Piece p = square[sq];
    //if (p >= Piece.size)
    //{
    //  import std.stdio;
    //  writeln(this);
    //  writeln(sq);
    //  writeln(p);
    //}
    assert(p < Piece.size);

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

  void set(string fen = Pos.Init)
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

    state.castling = Castling.init;
    foreach (ch; parts[2]) // parsing castling
    {
      state.castling |= ch.to_castling();
    }

    state.ep = parts[3].toSQ(); // en passant

    if (parts.length < 5) return;

    if (isNumeric(parts[4])) // fifty rule counter
      state.fifty = to!u8(parts[4]);

    if (parts.length < 6) return;

    // full move counter - no need
  }

  string to_fen()
  {
    string fen;
    return fen;
  }

  override string toString() const
  {
    debug
    {
      import std.range, std.stdio;
      string str;
      foreach_reverse (int rank; 0..8)
      {
        str ~= format("%d | ", rank + 1);

        foreach (int file; 0..8)
        {
          SQ sq = to_sq(file, rank);
          Piece p = square[sq];
          str ~= to_char(p);
          str ~= ' ';
        }
        str ~= "\n";
      }
      str ~= "  +----------------   ";
      str ~= to!string(color) ~ " to move\n";
      str ~= "    a b c d e f g h   ";
      str ~= "[" ~ to_string(state.castling, ".") ~ "]";
      str ~= " / " ~ state.fifty.to!string;
      str ~= "\n\n";
      return str;
    }
    else return "";
  }

  Piece get_piece(SQ sq) const { return square[sq]; }
  Piece get_piece(Move move) const { return square[move.from]; }

  import std.stdio;

  bool make(const Move move, Undo * undo, bool self = false)
  {
    const SQ from = move.from;
    const SQ to = move.to;
    const MT mt = move.mt;
    const Piece p = square[from];

    undo.state = state;
    undo++;
    state.castling &= uncastle[from] & uncastle[to];

    //if ((undo - 1).state.castling != Castling.init
    //&&  state.castling == Castling.init)
    //{
    //  writeln((undo - 1).state.castling);
    //  writeln(state.castling);
    //  writeln(from, " - ", to);
    //  assert(false);
    //}
    
    state.cap = square[to];
    state.ep = A1;
    state.fifty++;

    //writeln("castling = ", state.castling);

    switch (mt)
    {
      case MT.Cap:
      {
        state.fifty = 0;
        remove(from);
        remove(to);
        place(to, p);
        break;
      }

      case MT.KCastle:
      {
        remove(from);
        remove(to.add(1));
        place(to, p);
        place(to.sub(1), to_piece(Rook, color));
        break;
      }

      case MT.QCastle:
      {
        remove(from);
        remove(to.sub(2));
        place(to, p);
        place(to.add(1), to_piece(Rook, color));
        break;
      }

      case MT.NProm:
      case MT.BProm:
      case MT.RProm:
      case MT.QProm:
      {
        state.fifty = 0;
        Piece prom = move.promoted(color);

        remove(from);
        place(to, prom);
        break;
      }

      case MT.NCapProm:
      case MT.BCapProm:
      case MT.RCapProm:
      case MT.QCapProm:
      {
        state.fifty = 0;
        Piece prom = move.promoted(color);

        remove(from);
        remove(to);
        place(to, prom);
        break;
      }

      case MT.Ep:
      {
        state.fifty = 0;
        const SQ cap = to_sq(file(to), rank(from));

        remove(cap);
        remove(from);
        place(to, p);
        break;
      }

      case MT.Pawn2: // ---------- FALL THROUGH! ------------
      {
        state.fifty = 0;
        state.ep = cast(SQ)((from + to) / 2);
        goto default;
      }

      default:
      {
        remove(from);
        place(to, p);

        if (p.be!Pawn) state.fifty = 0;
      }
    }

    color ^= 1;

    if (in_check(1))
    {
      unmake(move, undo);
      return false;
    }

    //switch (mt)
    //{
    //  case MT.KCastle:
    //  case MT.QCastle:
    //  {
    //    const u64 o = occ[0] | occ[1];
    //    const SQ mid = cast(SQ)((from + to) / 2);

    //    if (is_attacked(from, o)
    //    ||  is_attacked(mid, o)
    //    ||  is_attacked(to, o))
    //    {
    //      unmake(move, undo);
    //      return false;
    //    }
    //    break;
    //  }
    //  default: break;
    //}

    undo.curr = move;
    return true;
  }

  void unmake(const Move move, Undo * undo)
  {
    const SQ from = move.from;
    const SQ to = move.to;
    const MT mt = move.mt;
    const Piece p = square[to];

    color ^= 1;

    switch (mt)
    {
      case MT.Cap:
      {
        assert(state.cap != Piece.NOP);
        remove!false(to);
        place!false(from, p);
        place!false(to, state.cap);
        break;
      }

      case MT.KCastle:
      {
        remove!false(to.sub(1));
        remove!false(to);
        place!false(to.add(1), to_piece(Rook, color));
        place!false(from, p);
        break;
      }

      case MT.QCastle:
      {
        remove!false(to.add(1));
        remove!false(to);
        place!false(to.sub(2), to_piece(Rook, color));
        place!false(from, p);
        break;
      }

      case MT.NProm:
      case MT.BProm:
      case MT.RProm:
      case MT.QProm:
      {
        remove!false(to);
        place!false(from, to_piece(Pawn, color));
        break;
      }

      case MT.NCapProm:
      case MT.BCapProm:
      case MT.RCapProm:
      case MT.QCapProm:
      {
        remove!false(to);
        place!false(from, to_piece(Pawn, color));
        place!false(to, state.cap);
        break;
      }

      case MT.Ep:
      {
        const SQ cap = to_sq(file(to), rank(from));

        remove!false(to);
        place!false(cap, p.opp);
        place!false(from, p);
        break;
      }

      default:
      {
        remove!false(to);
        place!false(from, p);
      }
    }

    undo--;
    state = undo.state;
  }

  // Just playing around
  void ForBB(Func)(u64 bb, Func func)
  {
    for (u64 bb = piece[p]; bb; bb = rlsb(bb))
    {
      SQ s = bitscan(bb);
      func();
    }
  }

  u64 att_mask(bool captures)() const
  {
    return captures ? occ[color.opp] : ~(occ[0] | occ[1]);
  }

  u64 attack(PieceType pt)(SQ sq) const
  {
    if      (pt == Bishop) return b_att(occ[0] | occ[1], sq);
    else if (pt == Rook)   return r_att(occ[0] | occ[1], sq);
    else if (pt == Queen)  return q_att(occ[0] | occ[1], sq);

    return Table.moves(to_piece(pt, Black), sq);
  }

  u64 attack(Piece p, SQ sq) const
  {
    switch (p)
    {
      case BN: case WN: return attack!Knight(sq);
      case BB: case WB: return attack!Bishop(sq);
      case BR: case WR: return attack!Rook(sq);
      case BQ: case WQ: return attack!Queen(sq);
      case BK: case WK: return attack!King(sq);
      default: return Empty;
    }
  }

  void gen(PieceType pt, bool captures, ML)(ML ml) const
  {
    Piece p = to_piece(pt, color);
    u64 mask = att_mask!captures();

    for (u64 bb = piece[p]; bb; bb = rlsb(bb))
    {
      SQ s = bitscan(bb);
      for (u64 att = attack(p, s) & mask; att; att = rlsb(att))
      {
        ml.add_move(s, bitscan(att), captures ? MT.Cap : MT.Quiet);
      }
    }
  }

  void generate(bool captures, ML)(ML ml) const
  {
    const u64 me = occ[color];
    const u64 opp = occ[color.opp()];
    const u64 o = me | opp;

    gen!(PieceType.Knight, captures)(ml);
    gen!(PieceType.Bishop, captures)(ml);
    gen!(PieceType.Rook,   captures)(ml);
    gen!(PieceType.Queen,  captures)(ml);
    gen!(PieceType.King,   captures)(ml);

    //writeln(ml);

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

    Piece p = to_piece(Pawn, color);
    if (color)
    {
      // TODO: apply static if on captures and quiets

      static if (!captures) // Forward & promotion
      {
        for (u64 bb = piece[p] & shift_d(~o); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (rank(s) == 6) ml.add_prom(s, s.add(8));
          else              ml.add_move(s, s.add(8));
        }
      }

      static if (captures) // Attacks
      {
        for (u64 bb = piece[p] & shift_dl(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (rank(s) == 6) ml.add_capprom(s, s.add(9));
          else              ml.add_move(s, s.add(9), MT.Cap);
        }

        for (u64 bb = piece[p] & shift_dr(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (rank(s) == 6) ml.add_capprom(s, s.add(7));
          else              ml.add_move(s, s.add(7), MT.Cap);
        }
      }

      static if (!captures) // Double move
      for (u64 bb = piece[p] & (~o >> 8) & (~o >> 16); bb; bb = rlsb(bb))
      {
        SQ s = bitscan(bb);
        if (rank(s) == 1) ml.add_move(s, s.add(16), MT.Pawn2);
      }

      static if (captures)
      if (state.ep)
      {
        for (u64 bb = piece[p] & Table.moves(to_piece(Pawn, color.opp), state.ep); bb; bb = rlsb(bb))
        {
          ml.add_move(bitscan(bb), state.ep, MT.Ep);
        }
      }
    }
    else
    {
      static if (!captures)
      for (u64 bb = piece[p] & shift_u(~o); bb; bb = rlsb(bb)) // Forward & promotion
      {
        SQ s = bitscan(bb);
        if (rank(s) == 1) ml.add_prom(s, s.sub(8));
        else              ml.add_move(s, s.sub(8));
      }

      static if (captures)
      {
        for (u64 bb = piece[p] & shift_ur(opp); bb; bb = rlsb(bb)) // Attacks
        {
          SQ s = bitscan(bb);
          if (rank(s) == 1) ml.add_capprom(s, s.sub(9));
          else              ml.add_move(s, s.sub(9), MT.Cap);
        }

        for (u64 bb = piece[p] & shift_ul(opp); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (rank(s) == 1) ml.add_capprom(s, s.sub(7));
          else              ml.add_move(s, s.sub(7), MT.Cap);
        }
      }

      static if (!captures)
      for (u64 bb = piece[p] & (~o << 8) & (~o << 16); bb; bb = rlsb(bb)) // Double move
      {
        SQ s = bitscan(bb);
        if (rank(s) == 6) ml.add_move(s, s.sub(16), MT.Pawn2);
      }

      static if (captures)
      if (state.ep)
      {
        for (u64 bb = piece[p] & Table.moves(to_piece(Pawn, color.opp), state.ep); bb; bb = rlsb(bb))
        {
          ml.add_move(bitscan(bb), state.ep, MT.Ep);
        }
      }
    }
  }

private:
  int ply = 0;
  Color color = Color.White;
  u64[Piece.size] piece;
  u64[Color.size] occ;
  Piece[SQ.size] square;
  State state;
}

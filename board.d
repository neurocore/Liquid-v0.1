module board;
import std.algorithm : max;
import std.array, std.ascii, std.string;
import std.math.algebraic, std.conv;
import bitboard, square, consts;
import eval, movelist, types, piece;
import solver, app, moves, utils;
import hash, magics, tables, vals;

struct Key
{
  u64 hash;
  bool irrev;
}

struct State // 12 bytes
{
  align (1):
  SQ ep = SQ.None;
  Piece cap = Piece.NOP;
  Castling castling = Castling.ALL;
  u8 fifty = 0;
  u64 bhash = Empty;

  u64 hash() const @property
  {
    return bhash ^ hash_castle[castling] ^ hash_ep[ep];
  }
}

class Board
{
  void clear()
  {
    foreach (p; BP .. Piece.size) piece[p] = 0;
    foreach (c; Black .. Color.size) occ[c] = Empty;
    foreach (x; A1 .. SQ.size) square[x] = Piece.NOP;
    color = White;
    state = State();
    threefold = [];
  }

  Board dup() const
  {
    Board B = new Board;
    foreach (p; BP .. Piece.size) B.piece[p] = piece[p];
    foreach (c; Black .. Color.size) B.occ[c] = occ[c];
    foreach (x; A1 .. SQ.size) B.square[x] = square[x];
    B.color = color;
    B.state = state;
    B.threefold = threefold.dup;
    return B;
  }

  int eval(Eval E) const
  {
    return E.eval(this);
  }

  int phase() const
  {
    u64 queens = piece[BQ] | piece[WQ];
    u64 rooks  = piece[BR] | piece[WR];
    u64 lights = piece[BN] | piece[WN]
               | piece[BB] | piece[WB];

    int phase = Phase.Total
              - Phase.Queen * popcnt(queens)
              - Phase.Rook  * popcnt(rooks)
              - Phase.Light * popcnt(lights);

    return max(phase, 0);
  }

  bool is_draw() const
  {
    // Threefold repetition

    if (threefold.length >= 5)
    for (long i = threefold.length - 5; i >= 0; i -= 2)
    {
      const Key key = threefold[i];
      if (key.hash == state.hash) return true; // 2nd is enough
      if (key.irrev) break;
    }

    // Rule of fifty moves

    if (state.fifty == 100) return true;

    // Insufficient material

    int total = popcnt(occ[0] | occ[1]);

    if (total == 3)
    {
      u64 lights = piece[BN] | piece[WN] | piece[BB] | piece[WB];
      if (lights) return true; // KLK
    }
    else if (total == 4)
    {
      if (popcnt(piece[BN] | piece[WN]) == 2) // KNNK, KNKN
      {
        return true;
      }

      if (only_one(piece[BN] | piece[BB]) // KLKL
      &&  only_one(piece[WN] | piece[WB]))
      {
        return true;
      }
    }

    return false;
  }

  bool has_pieces(Color col) const
  {
    u64 pieces = occ[col] ^ piece[BK.of(col)] ^ piece[BP.of(col)];
    return cast(bool)pieces;
  }

  bool is_pawn_eg(Color col) const
  {
    return !has_pieces(col.opp) && (piece[WP.of(col)] != 0);
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

  bool is_attacked(SQ king, u64 o, int opp = 0) const
  {
    const Color c = cast(Color)(color ^ opp);

    if (Table.atts(BN.of(c), king) & piece[WN ^ c]) return true; // Knights
    if (Table.atts(BP.of(c), king) & piece[WP ^ c]) return true; // Pawns
    if (Table.atts(BK.of(c), king) & piece[WK ^ c]) return true; // King

    if (b_att(o, king) & (piece[WB ^ c] | piece[WQ ^ c])) return true; // Bishops & queens
    if (r_att(o, king) & (piece[WR ^ c] | piece[WQ ^ c])) return true; // Rooks & queens

    return false;
  }

  u64 get_attacks(u64 o, SQ sq) const
  {
    const u64 bq = piece[BB] | piece[WB] | piece[BQ] | piece[WQ];
    const u64 rq = piece[BR] | piece[WR] | piece[BQ] | piece[WQ];

    u64 att = Empty;
    att |= bq & b_att(o, sq);
    att |= rq & r_att(o, sq);
    att |= piece[BP] & Table.atts(WP, sq);
    att |= piece[WP] & Table.atts(BP, sq);
    att |= (piece[BN] | piece[WN]) & Table.atts(BN, sq);
    att |= (piece[BK] | piece[WK]) & Table.atts(BK, sq);
    return att;
  }

  bool in_check(int opp = 0) const
  {
    Piece p = to_piece(King, cast(Color)(color ^ opp));
    SQ king = bitscan(piece[p]);
    return is_attacked(king, occ[0] | occ[1], opp);
  }

  void place(bool full = true)(SQ sq, Piece p)
  {
    piece[p]     ^= sq.bit;
    occ[p.color] ^= sq.bit;
    square[sq]    = p;

    static if (full)
    {
      // state.pst += E->pst[p][sq];
      // state.mkey += matkey[p];

       state.bhash ^= hash_key[p][sq];
    }
  }

  void remove(bool full = true)(SQ sq)
  {
    import std.format, std.exception;
    Piece p = square[sq];
    enforce(p < Piece.size, format("no piece to remove\n%s\nSQ = %s", this, sq));

    piece[p]     ^= sq.bit;
    occ[p.color] ^= sq.bit;
    square[sq]    = Piece.NOP;

    static if (full)
    {
      // state.pst -= E->pst[p][sq];
      // state.mkey -= matkey[p];

       state.bhash ^= hash_key[p][sq];
    }
  }

  bool set(string fen = Pos.Init)
  {
    SQ sq = A8;

    string[] parts = fen.split(' ');
    if (parts.length < 4) return error("less than 4 parts");

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

    foreach (ch; parts[1]) // parsing color
      color = ch.to_color();

    state.castling = Castling.init;
    foreach (ch; parts[2]) // parsing castling
    {
      state.castling |= ch.to_castling();
    }

    state.ep = parts[3].to_sq; // en passant

    string fifty = parts.length > 4 ? parts[4] : "";
    state.fifty = fifty.safe_to!u8; // fifty move counter

    // full move counter - no need

    state.bhash ^= hash_wtm[color];
    threefold ~= Key(state.hash, true);

    return true;
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
        if (rank == 1) str ~= format!"  #%016x"(state.hash);
        str ~= "\n";
      }
      str ~= "  +----------------   ";
      str ~= to!string(color) ~ " to move\n";
      str ~= "    a b c d e f g h   ";
      str ~= "[" ~ to_string(state.castling, ".") ~ "]";
      str ~= " " ~ state.ep.to_str;
      str ~= " " ~ state.fifty.to!string;
      str ~= "\n\n";
      return str;
    }
    else return "";
  }

  Piece get_piece(SQ sq) const { return square[sq]; }
  Piece get_piece(Move move) const { return square[move.from]; }

  u64 calc_hash() const
  {
    u64 key = Empty;
    foreach (p; BP .. Piece.size)
      for (u64 bb = piece[p]; bb; bb = rlsb(bb))
      {
        SQ sq = bitscan(bb);
        key ^= hash_key[p][sq];
      }

    key ^= hash_castle[state.castling];
    key ^= hash_ep[state.ep];
    key ^= hash_wtm[color];

    return key;
  }

  int see(Move move) const
  {
    //import std.stdio;
    //assert(move.is_cap); // works also for pawn pushes (!prom)

    u64 least_valuable_piece(u64 attadef, Color col, ref int p)
    {
      for (p = BP.of(col); p <= BK.of(col); p += 2)
      {
        const u64 subset = attadef & piece[p];
        if (subset) return lsb(subset);
      }
      return Empty;
    }

    u64 consider_xrays(u64 o, SQ sq)
    {
      const u64 bq = piece[BB] | piece[WB] | piece[BQ] | piece[WQ];
      const u64 rq = piece[BR] | piece[WR] | piece[BQ] | piece[WQ];

      u64 att = Empty;
      att |= o & bq & b_att(o, sq);
      att |= o & rq & r_att(o, sq);
      return att;
    }

    const int[] value = [100, 100, 325, 325, 325, 325, 500, 500, 1000, 1000, 20000, 20000, 0, 0];
    int[32] gain;
    int d = 0;
    int p = square[move.from];

    u64 o       = occ[0] | occ[1];
    u64 xrayers = o ^ piece[BN] ^ piece[WN] ^ piece[BK] ^ piece[WK];
    u64 from_bb = move.from.bit;
    u64 attadef = get_attacks(o, move.to) | from_bb;
    gain[d]     = value[square[move.to]];

    do
    {
      //writeln(attadef.to_bitboard);
      //writeln(o.to_bitboard);
      //writefln("gain[%d] = %d", d, gain[d]);

      d++;
      gain[d]  = value[p] - gain[d - 1]; // speculative store, if defended
      attadef ^= from_bb; // reset bit in set to traverse
      o       ^= from_bb; // reset bit in temporary occupancy (for x-Rays)

      if (from_bb & xrayers) attadef |= consider_xrays(o, move.to);
      from_bb = least_valuable_piece(attadef, (cast(Piece)p).color.opp, p);
    }
    while (from_bb);

    while (--d) gain[d - 1] = -max(-gain[d - 1], gain[d]);
    return gain[0];
  }

  Move recognize(Move move)
  {
    const SQ from = move.from;
    const SQ to = move.to;
    const Piece p = square[from];
    const Piece cap = square[to];

    if (p == Piece.NOP) return Move.None;
    if (p.color() != color) return Move.None;
    if (cap.color() == color) return Move.None;

    MT mt = move.mt;

    if (cap != Piece.NOP) // capture
    {
      mt = cast(MT) (mt + MT.Cap); // cap || capprom
    }
    else if (p.pt() == Pawn && to == state.ep)
    {
      mt = MT.Ep; // ep
    }
    else
    {
      if (p.pt() == Pawn && abs(from - to) == 16) mt = MT.Pawn2; // p2
      else if (p.pt() == King)
      {
        if (color == White) // castlings
        {
          if (from == E1)
          {
            if (to == G1 && state.castling.has_wk()) mt = MT.KCastle;
            if (to == C1 && state.castling.has_wq()) mt = MT.QCastle;
          }
        }
        else
        {
          if (from == E8)
          {
            if (to == G8 && state.castling.has_bk()) mt = MT.KCastle;
            if (to == C8 && state.castling.has_bq()) mt = MT.QCastle;
          }
        }
      }
    }

    // pseudolegality test (can be disabled if you trust GUI)
    if (abs(from - to) != 8 && !mt.is_pawn2() && !mt.is_castle())
    {
      u64 att = attack(p, from) & to.bit;
      if (!att) return Move.None;
    }

    return Move(from, to, mt);
  }

  bool is_allowed(Move move) // pseudolegal
  {
    if (move.is_empty) return false;

    const SQ from = move.from;
    const SQ to = move.to;
    const MT mt = move.mt;
    const Piece p = square[from];

    if (p >= Piece.size) return false;         // piece is valid
    if (!(piece[p] & from.bit)) return false; // and placed on from
    if (p.color != color) return false;      // playing own pieces

    if (!mt.is_cap && square[to] < Piece.size) return false;

    if (mt.is_castle) // castlings
    {
      const u64 o = occ[0] | occ[1];

      if (p == WK)
      {
        if (from != E1) return false;
        if (to == G1) return (state.castling & Castling.WK) && !(o & Span.WK);
        if (to == C1) return (state.castling & Castling.WQ) && !(o & Span.WQ);
      }
      else if (p == BK)
      {
        if (from != E8) return false;
        if (to == G8) return (state.castling & Castling.BK) && !(o & Span.BK);
        if (to == C8) return (state.castling & Castling.BQ) && !(o & Span.BQ);
      }
      return false;
    }
    else if (p < BN) // pawn moves
    {
      if (!(Table.p_moves(p.color, from) & to.bit)) // not move forward
      {
        if (!(Table.atts(p, from) & to.bit)) return false; // not attack

        if (to != state.ep) // not en passant
        {
          if (!(to.bit & occ[color.opp])) return false; // not capturing
        }
        return true;
      }
    }
    else // piece moves
    {
      if (!(Table.atts(p, from) & to.bit)) return false; // piece can move
    }

    const u64 o = occ[0] | occ[1];
    if (Table.between(from, to) & o) return false; // something between

    return true;
  }

  Move san(string str)
  {
    // Castlings

    if (str == "O-O")
      return color == White
           ? Move(E1, G1, MT.KCastle)
           : Move(E8, G8, MT.KCastle);

    if (str == "O-O-O")
      return color == White
           ? Move(E1, C1, MT.QCastle)
           : Move(E8, C8, MT.QCastle);

    // Other cases

    int file = -1, rank = -1;
    Piece p = Piece.NOP;
    SQ from = SQ.None;
    SQ to = SQ.None;
    MT mt = MT.Quiet;
    u64 to_mask = Full;

    if (auto data = parse_san!"Nz0xa1"(str)) // usual piece move
    {
      auto pt = cast(PieceType)(data[0]);
      p = to_piece(pt, color);
      file = data[1];
      rank = data[2];
      if (file >= 0 && rank >= 0)
        from = to_sq(file, rank);
      to = to_sq(data[3], data[4]);
    }
    else if (auto data = parse_san!"axa0=Q"(str)) // pawn capture
    {
      p = to_piece(Pawn, color);
      file = data[0];

      if (data[2] < 0) // no rank
        to_mask &= file_bb[data[1]];
      else
        to = to_sq(data[1], data[2]);

      if (data[3] > 0) mt = cast(MT)(MT.NCapProm + data[3] - 1);
    }
    else if (auto data = parse_san!"a1=Q"(str)) // pawn move
    {
      p = to_piece(Pawn, color);
      to = to_sq(data[0], data[1]);

      if (color == White)
      {
        if (square[to - 8] == p)
        {
          from = to.sub(8);
          if (to.rank == 7)
            mt = cast(MT)(MT.NProm + data[2] - 1);
        }
        else if (to.rank == 3 && square[to - 16] == p)
        {
          from = to.sub(16);
          mt = MT.Pawn2;
        }
      }
      else
      {
        if (square[to + 8] == p)
        {
          from = to.add(8);
          if (to.rank == 0)
            mt = cast(MT)(MT.NProm + data[2] - 1);
        }
        else if (to.rank == 4 && square[to + 16] == p)
        {
          from = to.add(16);
          mt = MT.Pawn2;
        }
      }
    }
    else return Move.None;

    to_mask = to == SQ.None ? to_mask : to.bit;

    // Looking for 'from' square

    if (from == SQ.None)
    {
      u64 mask = Full;
      if (file >= 0) mask &= file_bb[file];
      if (rank >= 0) mask &= rank_bb[rank];

      for (u64 bb = piece[p] & mask; bb; bb = rlsb(bb))
      {
        SQ j = bitscan(bb);
        if (abs(j - to) != 8 || p.pt != Pawn)
        {
          u64 att = attack(p, j) & to_mask;
          if (att)
          {
            from = j;
            break;
          }
        }
      }
    }

    if (from == SQ.None) return Move.None;

    // Adding move type info

    if (to == state.ep && p.pt == Pawn) mt = MT.Ep;
    else if (square[to] != Piece.NOP) mt |= MT.Cap;

    return Move(from, to, mt);
  }

  bool make(const Move move, ref Undo * undo)
  {
    assert(!move.is_empty, "can't make empty move");

    const SQ from = move.from;
    const SQ to = move.to;
    const MT mt = move.mt;
    const Piece p = square[from];
    bool irreversible = true;

    undo.state = state;
    undo++;

    state.castling &= uncastle[from] & uncastle[to];    
    state.cap = square[to];
    state.ep = SQ.None;
    state.fifty++;

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
        import std.exception;
        enforce(square[to] == Piece.NOP);
        remove(from);
        place(to, p);

        if (p.be!Pawn)
          state.fifty = 0;
        else
          irreversible = false;
      }
    }

    color ^= 1;
    state.bhash ^= hash_wtm[0];
    threefold ~= Key(state.hash, irreversible);

    if (in_check(1))
    {
      unmake(move, undo);
      return false;
    }

    switch (mt)
    {
      case MT.KCastle:
      case MT.QCastle:
      {
        const u64 o = occ[0] | occ[1];
        const SQ mid = cast(SQ)((from + to) / 2);

        if (is_attacked(from, o, 1)
        ||  is_attacked(mid, o, 1)
        ||  is_attacked(to, o, 1))
        {
          unmake(move, undo);
          return false;
        }
        break;
      }
      default: break;
    }

    undo.curr = move;
    return true;
  }

  void unmake(const Move move, ref Undo * undo)
  {
    assert(!move.is_empty, "can't unmake empty move");

    const SQ from = move.from;
    const SQ to = move.to;
    const MT mt = move.mt;
    const Piece p = square[to];

    assert(threefold.length > 0);
    threefold.popBack();

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

  void make_null(ref Undo * undo)
  {
    undo.state = state;
    undo++;

    color ^= 1;

    state.ep = SQ.None;
    state.bhash ^= hash_wtm[0];

    threefold ~= Key(state.hash, true);
  }

  void unmake_null(ref Undo * undo)
  {
    color ^= 1;
    
    undo--;
    state = undo.state;

    assert(threefold.length > 0);
    threefold.popBack();
  }

  u64 att_mask(bool captures)() const
  {
    return captures ? occ[color.opp] : ~(occ[0] | occ[1]);
  }

  u64 attack(PieceType pt)(SQ sq) const
  {
    static if (pt == Bishop) return b_att(occ[0] | occ[1], sq);
    else   if (pt == Rook)   return r_att(occ[0] | occ[1], sq);
    else   if (pt == Queen)  return q_att(occ[0] | occ[1], sq);

    return Table.atts(to_piece(pt, Black), sq);
  }

  u64 attack(PieceType pt)(SQ sq, u64 o) const
  {
    static if (pt == Bishop) return b_att(o, sq);
    else   if (pt == Rook)   return r_att(o, sq);
    else   if (pt == Queen)  return q_att(o, sq);

    return Table.atts(to_piece(pt, Black), sq);
  }

  u64 attack(Piece p, SQ sq) const
  {
    switch (p)
    {
      case BB: case WB: return attack!Bishop(sq);
      case BR: case WR: return attack!Rook(sq);
      case BQ: case WQ: return attack!Queen(sq);
      default: return Table.atts(p, sq);
    }
  }

  u64 attack(Piece p, SQ sq, u64 o) const
  {
    switch (p)
    {
      case BB: case WB: return attack!Bishop(sq, o);
      case BR: case WR: return attack!Rook(sq, o);
      case BQ: case WQ: return attack!Queen(sq, o);
      default: return Table.atts(p, sq);
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

  void generate(bool captures, ML)(ML ml, PromMode pmode) const
  {
    const u64 me = occ[color];
    const u64 opp = occ[color.opp()];
    const u64 o = me | opp;

    gen!(PieceType.Knight, captures)(ml);
    gen!(PieceType.Bishop, captures)(ml);
    gen!(PieceType.Rook,   captures)(ml);
    gen!(PieceType.Queen,  captures)(ml);
    gen!(PieceType.King,   captures)(ml);

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
      static if (!captures) // Forward & promotion
      {
        for (u64 bb = piece[p] & shift_d(~o); bb; bb = rlsb(bb))
        {
          SQ s = bitscan(bb);
          if (rank(s) == 6) ml.add_prom(s, s.add(8), pmode);
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
        for (u64 bb = piece[p] & Table.atts(to_piece(Pawn, color.opp), state.ep); bb; bb = rlsb(bb))
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
        if (rank(s) == 1) ml.add_prom(s, s.sub(8), pmode);
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
        for (u64 bb = piece[p] & Table.atts(to_piece(Pawn, color.opp), state.ep); bb; bb = rlsb(bb))
        {
          ml.add_move(bitscan(bb), state.ep, MT.Ep);
        }
      }
    }
  }

public:
  Color color = Color.White;
  u64[Piece.size] piece;
  u64[Color.size] occ;
  Piece[SQ.size] square;
  State state = State();
  Key[] threefold;
}

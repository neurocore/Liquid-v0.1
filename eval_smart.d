module eval_smart;
import std.math : exp, sqrt;
import eval, tables, piece, square, consts;
import app, board, bitboard, types, utils;
import vals, moves, kpk;

enum PasserStatus { None, Candidate, Passer, Unstoppable, King, Kpk }

struct DebugPasser
{
  SQ sq;
  PasserStatus status;
  bool free, supported;
  int scale, val;
  u64 sentries;
}

struct EvalReport
{
  DebugPasser[] passers;
  Vals vals;

  string toString()
  {
    import std.format;
    string str = format("[Passers]\n");

    int passers_total = 0;
    foreach (passer; passers)
    {
      str ~= format("%s\n", passer); // ~ "\n" ~ passer.sentries.to_bitboard;
      passers_total += passer.val;
    }
    str ~= format("Total = %s\n", passers_total);
    return str;
  }
}

// from Toga, i suppose
enum AttWeight { Light = 2, Rook = 3, Queen = 5 };

const int[100] safety_table =
[
    0,   0,   1,   2,   3,   5,   7,   9,  12,  15,
   18,  22,  26,  30,  35,  39,  44,  50,  56,  62,
   68,  75,  82,  85,  89,  97, 105, 113, 122, 131,
  140, 150, 169, 180, 191, 202, 213, 225, 237, 248,
  260, 272, 283, 295, 307, 319, 330, 342, 354, 366,
  377, 389, 401, 412, 424, 436, 448, 459, 471, 483,
  494, 500, 500, 500, 500, 500, 500, 500, 500, 500,
  500, 500, 500, 500, 500, 500, 500, 500, 500, 500,
  500, 500, 500, 500, 500, 500, 500, 500, 500, 500,
  500, 500, 500, 500, 500, 500, 500, 500, 500, 500
];

const int[] weakness_push_table =
[
  128, 106, 86, 68, 52, 38, 26, 16, 8, 2
];

const int[Piece.size + 2] xray_cost =
[
  0, 0, 0, 0, 0, 0, 34, 34, 192, 192, 256, 256, 0, 0
];


struct EvalInfo
{
  int[Color.size] att_weight;
  int[Color.size] att_count;
  SQ[][Color.size] eg_weak;
  u64 pinned;

  void clear()
  {
    att_weight.zeros;
    att_count.zeros;
    eg_weak[0] = [];
    eg_weak[1] = [];
    pinned = Empty;
  }

  void add_attack(Color col, AttWeight amount, int count = 1)
  {
    att_weight[col] += count * amount;
    att_count[col] += count;
  }

  int king_safety(Color col) const
  {
    return att_count[col] > 2 ? safety_table[att_weight[col]] : 0;
  }

  int king_safety() const
  {
    return king_safety(White) - king_safety(Black);
  }

  void add_weak(Color col, SQ sq)
  {
    eg_weak[col] ~= sq;
  }

  int weak_push(Color col, SQ king, int bonus)
  {
    int max = 0;
    foreach (sq; eg_weak[col])
    {
      int val = weakness_push_table[k_dist(king, sq)];
      if (val > max) max = val;
    }
    return max * bonus / 128;
  }
}

class EvalSmart : Eval
{
  EvalInfo ei;
  EvalReport report;
  int[8] passer_scale;
  int[9] n_adj, r_adj;

  this(string tune = Tune.Def)
  {
    set(tune);
    init();
  }

  // [Factors]
  // (Complexity/10)(Importance/10)=(5I-2C)
  //
  // + material
  // + PST
  // + mobility
  // + tempo
  //

  // + 58=30 passers & candidates
  // + 15=23 bishop pair
  // + 25=23 rook on 7th
  // + 25=23 rook open files
  // + 78=26 tapered eval
  // + 46=22 forks
  // + 35=19 pawns doubled, isolated, backward
  // + 14=18 rook/knight adjustments
  // + 37=29 early queen penalty
  // + 14=18 sliding pieces support
  // + 24=16 50-moves rule
  // + 35=19 pawn eg key squares
  // + 57=25 xrays & pins

  // [king safety]
  // + 78=26 attacks counts
  // + 26=26 pawn shield
  // - 26=26 tropism to king
  // - 34=17 pawn storm

  // - 24=16 contact check
  // - 55=15 outposts
  // - 34=14 op blockage patterns
  // - 34=14 bad rook
  // - 33= 9 bad bishop

  // [Further improvements]
  //
  // ? soft mobility - don't count squares attacked by enemy pawns
  // ? virtual piece placement (like in Critter)
  // ? space
  // ? connectivity


  // [passers testbed]
  //
  // 2n1k3/p7/3B2K1/2P2p1p/8/4P1P1/5P1P/8 b - - 0 46; bm c8d6; c0 "Far passer not in king square"
  // 7K/8/k1P5/7p/8/8/8/8 w - -; bm h8g7; c0 "Reti etude"
  // 1k6/8/1P6/3P3P/2K5/5n2/8/8 w - - 1 10; bm d5d6; bm h5h6
  // 8/2p2pk1/5p2/P4Pp1/3P3p/P7/2PK1P2/8 b - - 0 31; c0 "Must eval for black win"

  // "taken from the book Pawn endings by A. Cetkov and
  // fundamental Chess Endings by K. Muller & F. Lamprecht"

  // 8/2k5/2p5/2Kp3p/3P3P/8/1P6/8 w - - 0 0
  // 8/p7/1p1k3p/2pPp1p1/P1P1P1P1/7P/8/5K2 w - - 0 0
  // 8/8/4k3/pp4Pp/4K2P/8/1P6/8 w - - 0 0
  // 8/8/1p6/3kPp2/5Pp1/1K4P1/8/8 w - - 0 0
  // k7/2p1pp2/2P3p1/4P1P1/5P2/p7/Kp3P2/8 w - - 0 0
  // 8/5K2/kp6/p1p5/P2p4/1P3P2/2P5/8 b - - 0 0
  // 1k6/1p2p2p/pK1p2pP/4P1P1/8/5P2/8/8 w - - 0 0
  // 8/1p4p1/2k2p1p/5P2/4P1PP/3K4/8/8 w - - 0 0
  // 8/6p1/p2k4/P3p3/2P1K3/8/7P/8 w - - 0 0
  // 8/8/1p4p1/2P5/4p2k/8/K5P1/8 w - - 0 0
  // 8/5k2/8/3ppP1p/2p3P1/1pP1K2P/1P6/8 b - - 0 0
  // 8/8/1p3p2/4k1pp/p3P2P/P3K1P1/1P6/8 w - - 0 0
  // 8/6pp/8/2K5/1p4P1/k6P/P7/8 b - - 0 0
  // 8/1p6/p3p3/4k1p1/1P6/2P4P/4K1P1/8 w - - 0 0
  // 8/3pkP2/8/1pP4P/5P1p/7K/6PP/8 w - - 0 0
  // 8/6p1/6pp/8/k4P2/6K1/6PP/8 w - - 0 0
  // 7k/8/5P2/7P/ppp5/8/8/K7 w - - 0 0
  // 8/6K1/8/ppp2k2/8/1P6/1P5P/8 w - - 0 0
  // 8/5pp1/8/k2p1Pp1/P5P1/3P4/8/3K4 w - - 0 0
  // 8/p7/1p4kp/3p4/3P4/P3K3/1P4P1/8 w - - 0 0
  // 8/8/3k4/4p2p/2P1K3/1p5P/1P6/8 w - - 0 0
  // 8/1pp5/p5p1/2Pp1k2/3P4/5K2/PP3P2/8 b - - 0 0
  // 8/5p2/3p2p1/3kp3/1p5P/1P2K1P1/2P5/8 w - - 0 0
  // 8/8/p5k1/2pP3p/1pP5/1P6/P7/6K1 w - - 0 0
  // 8/6pp/5p2/3k1PP1/5K1P/8/8/8 w - - 0 0
  // 1k6/8/p5p1/6p1/6P1/5P1P/6PK/8 w - - 0 0
  // 8/1K6/8/k4p2/4pp2/8/4PP2/8 w - - 0 0
  // 5k2/8/2p5/4p2p/3PP2P/4P3/7K/8 b - - 0 0

  int eval_explained(const Board B, ref EvalReport er)
  {
    int val = eval(B, -Val.Inf, Val.Inf);
    er = report;
    return val;
  }

  override int eval(const Board B, int alpha, int beta)
  {
    ei.clear();
    int val = 0;
    
    for (int i = 0; i < BK; i++) // material
    {
      const u64 bb = B.piece[i];
      val += score[i] * popcnt(bb);
    }

    const int margin = 200; // Lazy Eval
    if (val - margin > alpha
    &&  val + margin < beta)
    {
      // probably check here:
      // - far advanced opponent passer
      // - king in danger (not in endgame)
      return val;
    }

    val += evaluate(B); // collecting ei
    val += ei.king_safety();

    int score = (B.color == White ? val : -val) + term[Tempo];
    return score * (100 - B.state.fifty) / 100;
  }

  private int evaluate(const Board B)
  {
    Vals vals;
    vals += eval_xrays!White(B) - eval_xrays!Black(B);
    vals += evaluateP!White(B)  - evaluateP!Black(B);
    vals += evaluateN!White(B)  - evaluateN!Black(B);
    vals += evaluateB!White(B)  - evaluateB!Black(B);
    vals += evaluateR!White(B)  - evaluateR!Black(B);
    vals += evaluateQ!White(B)  - evaluateQ!Black(B);
    vals += evaluateK!White(B)  - evaluateK!Black(B);

    return vals.tapered(B.phase);
  }

  private Vals eval_xrays(Color col)(const Board B)
  {
    Vals vals;
    const u64 o = B.occ[0] | B.occ[1];
    u64 valuable = B.piece[WK.of(col)];

    foreach_reverse(pt; PieceType.Bishop .. PieceType.King)
    {
      Piece p = to_piece(pt, col);

      for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
      {
        SQ sq = bitscan(bb);
        u64 blockers = B.attack(p, sq) & o;
        u64 xray = B.attack(p, sq, o ^ blockers) & valuable;

        for (; xray; xray = rlsb(xray))
        {
          SQ j = bitscan(xray);
          Piece a = B.square[j];
          if (xray_cost[a] <= 0) continue;

          if (B.occ[col] & Table.between(sq, j)) // xray
          {
            vals += Vals.both(xray_cost[a] * term[XrayMul] / 256);
          }
          else // pin
          {
            ei.pinned |= B.occ[col.opp] & Table.between(sq, j);
          }
        }
      }
      valuable |= B.piece[to_piece(pt, col.opp)];
    }
    return vals;
  }

  private Vals evaluateP(Color col)(const Board B)
  {
    Piece p = to_piece(Pawn, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);

      // pst

      vals += pst[p][sq];

      u64 back_friendly = Table.front(col.opp, sq) & B.piece[p];
      u64 fore_friendly = Table.front(col, sq) & B.piece[p];

      u64 cannot_pass = Table.front(col, sq) & B.piece[p.opp];
      u64 has_support = Table.att_rear(col, sq) & B.piece[p];
      u64 has_sentry = Table.att_span(col, sq) & B.piece[p.opp];

      // isolated

      if (!(Table.isolator(sq) & B.piece[p]))
      {
        vals -= Vals.both(term[Isolated]);
      }

      // doubled

      if (back_friendly && !fore_friendly) // most advanced one
      {
        vals -= Vals.both(popcnt(back_friendly) * term[Doubled]);
      }

      // blocked weak

      if (cannot_pass && !has_support)
      {
        ei.add_weak(col, sq);
      }

      // backward

      if (!has_support && has_sentry)
      {
        bool developed = col ? sq.rank > 3 : sq.rank < 4;
        if (!developed) vals -= Vals.both(term[Backward]);

        ei.add_weak(col, sq);
      }

      // passers

      if (!cannot_pass && !fore_friendly)
      {
        vals += eval_passer!col(B, sq);
      }
    }
    return vals;
  }

  // [Passers]
  //
  //  |types|
  //
  // + Unstoppable - not blocked frontspan
  //               & opp has no pieces
  //               & opp king not in square
  //
  // + King passer - our king controls pawn frontspan up to promotion
  //               & our king is not blocking frontspan
  //               & our pawn is under defence
  //               & not works with a- and h-pawns (generally)
  //
  // + Free        - can make one more move forward, i.e.
  //               = isn't blocked stop
  //               & stop square is see-positive
  //
  // + Supported   - dangerous alliance
  //
  //  |factors|
  //
  // + Scale whole score by rank (non-linear)
  // + Add bonus/penalty for king distances to stop square
  // + Unstoppable passer will have huge bonus (rook..queen)

  private Vals eval_passer(Color col)(const Board B, SQ sq)
  {
    debug DebugPasser dpasser;
    debug dpasser.sq = sq;

    const SQ king = bitscan(B.piece[BK.of(col)]);
    const SQ kopp = bitscan(B.piece[WK.of(col)]);

    // kpk probe
    int kpk = 0;
    if (!B.has_pieces(col) && !B.has_pieces(col.opp))
    {
      int win = Kpk.probe!col(col, king, sq, kopp);
      if (win > 0)
      {
        int pawns = popcnt(B.piece[BP] | B.piece[WP]);
        if (pawns == 1)
        {
          kpk += term[Unstoppable];
        }
      }
    }

    int v = 0;
    const Piece p = BP.of(col);
    const u64 sentries = Table.att_span(col, sq) & B.piece[p.opp];
    int rank = col ? sq.rank : 7 - sq.rank;
    rank += rank == 1; // double pawn move
    rank += B.color == col; // tempo
    const int scale = passer_scale[rank];

    debug dpasser.scale = scale;
    debug dpasser.sentries = sentries;

    if (!sentries) // Passer
    {
      v += term[Passer] * scale / 256;
      debug dpasser.status = PasserStatus.Passer;

      if (!(Table.front(col, sq) & B.occ[col]) // Unstoppable
      &&  !B.has_pieces(col.opp))
      {
        SQ prom = to_sq(sq.file, col ? 7 : 0);
        int turn = cast(int)(B.color != col);

        // opp king is not in square
        if (k_dist(kopp, prom) - turn > k_dist(sq, prom))
        {
          v += term[Unstoppable];
          debug dpasser.status = PasserStatus.Unstoppable;
        }
      }
      else
      if (!(sq.bit & (FileA | FileH)) // King passer
      &&  !B.has_pieces(col.opp))
      {
        SQ prom = to_sq(sq.file, col ? 7 : 0);

        // own king controls all promote path
        if (king.file != sq.file
        &&  k_dist(king, sq) <= 1
        &&  k_dist(king, prom) <= 1)
        {
          v += term[Unstoppable];
          debug dpasser.status = PasserStatus.King;
        }
      }
      else // Bonuses for increasing passers potential
      {
        if (Table.psupport(col, sq) & B.piece[p]) // Supported
        {
          v += term[Supported] * scale / 256;
          debug dpasser.supported = true;
        }

        u64 o = B.occ[0] | B.occ[1];
        if (!(Table.front_one(col, sq) & o)) // Free passer
        {
          SQ stop = col ? sq.add(8) : sq.sub(8);
          Move move = Move(sq, stop);
          if (B.see(move) > 0)
          {
            v += term[FreePasser];
            debug dpasser.free = true;
          }
        }

        // King tropism to stop square

        SQ stop = col ? sq.add(8) : sq.sub(8);
        SQ king_own = bitscan(B.piece[BK.of(col)]);
        SQ king_opp = bitscan(B.piece[WK.of(col)]);
        int tropism = 0;

        tropism -=  5 * k_dist(king_own, stop);
        tropism += 20 * k_dist(king_opp, stop);

        if (tropism > 0) v += tropism;
      }
    }
    else if (only_one(sentries)) // Candidate
    {
      SQ j = bitscan(sentries); // simplest case
      if (Table.front(col.opp, j) & B.piece[p])
      {
        v += term[Candidate] * scale / 256;
        debug dpasser.status = PasserStatus.Candidate;
      }
    }

    v += kpk;

    debug if (kpk > 0) dpasser.status = PasserStatus.Kpk;
    debug dpasser.val = col ? v : -v;
    debug if (dpasser.status != PasserStatus.None)
    { 
      report.passers ~= dpasser;
    }

    return Vals(v / 2, v);
  }

  private Vals evaluateN(Color col)(const Board B)
  {
    Piece p = to_piece(Knight, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // king attacks

      const SQ ksq = bitscan(B.piece[WK.of(col)]);
      const u64 katt = att & Table.kingzone(col.opp, ksq);
      ei.add_attack(col, AttWeight.Light, popcnt(katt));

      // pst & mobility

      vals += pst[p][sq];
      if (!(ei.pinned & sq.bit))
      {
        vals += Vals.both(term[NMob] * popcnt(att) / 32);
      }

      // adjustments

      int pawns = popcnt(B.piece[BP.of(col)]);
      vals += Vals.both(n_adj[pawns]);

      // forks

      u64 fork = att & (B.piece[WR.of(col)]
                      | B.piece[WQ.of(col)]
                      | B.piece[WK.of(col)]);

      if (rlsb(fork)) vals += Vals.both(term[KnightFork]);

      // outposts

      // TODO
    }
    return vals;
  }

  private Vals evaluateB(Color col)(const Board B)
  {
    Piece p = to_piece(Bishop, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);
      //const u64 o = B.occ[0] | B.occ[1] ^ B.piece[BQ.of(col)];
      //const u64 att = B.attack(p, sq, o); // Buggy

      // king attacks

      const SQ ksq = bitscan(B.piece[WK.of(col)]);
      const u64 katt = att & Table.kingzone(col.opp, ksq);
      ei.add_attack(col, AttWeight.Light, popcnt(katt));

      // pst & mobility

      vals += pst[p][sq];
      if (!(ei.pinned & sq.bit))
      {
        vals += Vals.both(term[BMob] * popcnt(att) / 32);
      }

      // forks

      u64 valuable = B.piece[WR.of(col)]
                   | B.piece[WQ.of(col)]
                   | B.piece[WK.of(col)];

      u64 fork = att & valuable;

      if (rlsb(fork)) vals += Vals.both(term[BishopFork]);
    }

    // bishop pair

    if (popcnt(B.piece[p]) > 1) vals += Vals.both(term[BishopPair]);
    return vals;
  }

  private Vals evaluateR(Color col)(const Board B)
  {
    Piece p = to_piece(Rook, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);
      //const u64 o = B.occ[0] | B.occ[1] ^ B.piece[BQ.of(col)];
      //const u64 att = B.attack(p, sq, o); // Buggy

      // king attacks

      const SQ ksq = bitscan(B.piece[WK.of(col)]);
      const u64 katt = att & Table.kingzone(col.opp, ksq);
      ei.add_attack(col, AttWeight.Rook, popcnt(katt));

      // pst & mobility

      vals += pst[p][sq];
      if (!(ei.pinned & sq.bit))
      {
        vals += Vals.both(term[RMob] * popcnt(att) / 32);
      }

      // adjustments

      int pawns = popcnt(B.piece[BP.of(col)]);
      vals += Vals.both(r_adj[pawns]);

      // rook on 7th

      u64 own_pawns = B.piece[to_piece(Pawn, p.color)];
      u64 opp_pawns = B.piece[to_piece(Pawn, p.color.opp)];
      const int rook_rank = p.color == White ? 7 : 1;
      const int king_rank = p.color == White ? 8 : 0;

      if (sq.rank == rook_rank)
      {
        SQ opp_king = bitscan(B.piece[to_piece(King, p.color.opp)]);

        if (opp_king.rank == king_rank || popcnt(opp_pawns) > 1)
          vals += Vals(term[Rook7thOp], term[Rook7thEg]);
      }

      // rook on open/semi-files

      if (!(Table.front(p.color, sq) & own_pawns))
      {
        if (Table.front(p.color, sq) & opp_pawns)
          vals += Vals.both(term[RookSemi]);
        else
          vals += Vals.both(term[RookOpen]);
      }
    }

    return vals;
  }

  private Vals evaluateQ(Color col)(const Board B)
  {
    Piece p = to_piece(Queen, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // king attacks

      const SQ ksq = bitscan(B.piece[WK.of(col)]);
      const u64 katt = att & Table.kingzone(col.opp, ksq);
      ei.add_attack(col, AttWeight.Queen, popcnt(katt));

      // pst & mobility

      vals += pst[p][sq];
      if (!(ei.pinned & sq.bit))
      {
        vals += Vals.both(term[QMob] * popcnt(att) / 32);
      }

      // early queen

      u64 undeveloped;
      if (col == White)
      {
        if (sq.rank > 1)
        {
          undeveloped  = B.piece[WN] & ([B1, G1].bits);
          undeveloped |= B.piece[WB] & ([C1, F1].bits);
        }
      }
      else
      {
        if (sq.rank < 6)
        {
          undeveloped  = B.piece[BN] & ([B8, G8].bits);
          undeveloped |= B.piece[BB] & ([C8, F8].bits);
        }
      }
      const int penalty = popcnt(undeveloped);
      vals -= Vals.as_op(penalty * term[EarlyQueen]);
    }

    return vals;
  }

  private Vals evaluateK(Color col)(const Board B)
  {
    Piece p = to_piece(King, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);

      // pst

      vals += pst[p][sq];

      // pawn weakness

      const int push = ei.weak_push(col.opp, sq, term[WeaknessPush]);
      vals += Vals.as_eg(push);

      // pawn shield

      u64 pawns = B.piece[BP.of(col)];
      u64 row1 = col == White ? Rank2 : Rank7;
      u64 row2 = col == White ? Rank3 : Rank6;

      if (sq.file > 4)
      {
        if      (pawns & row1 & FileF) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileF) vals += Vals.as_op(term[Shield2]);

        if      (pawns & row1 & FileG) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileG) vals += Vals.as_op(term[Shield2]);

        if      (pawns & row1 & FileH) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileH) vals += Vals.as_op(term[Shield2]);
      }
      else
      {
        if      (pawns & row1 & FileA) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileA) vals += Vals.as_op(term[Shield2]);

        if      (pawns & row1 & FileB) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileB) vals += Vals.as_op(term[Shield2]);

        if      (pawns & row1 & FileC) vals += Vals.as_op(term[Shield1]);
        else if (pawns & row2 & FileC) vals += Vals.as_op(term[Shield2]);
      }
    }

    return vals;
  }

  override void init()
  {
    // Building piece adjustments arrays //////////////////////////

    for (int i = 0; i < 9; i++)
    {
      n_adj[i] = term[KnightAdj] * PAdj[i];
      r_adj[i] = -term[RookAdj] * PAdj[i];
    }

    // Setting material scores  ///////////////////////////////////

    score[WP] = 100;
    score[WN] = term[MatKnight];
    score[WB] = term[MatBishop];
    score[WR] = term[MatRook];
    score[WQ] = term[MatQueen];
    score[WK] = 20000;

    for (int i = 0; i < Piece.size; i += 2)
      score[i] = -score[i + 1];

    // Building piece-square table ////////////////////////////////

    foreach (sq; A1..SQ.size)
      foreach (p; BP..Piece.size)
        pst[p][sq] = Vals.init;

    // Pawns //////////////////////////////////////////////

    int p = WP; 

    // file
    foreach (sq; A1..SQ.size)
      pst[p][sq].op += PFile[sq.file] * term[PawnFile];

    // center control
    pst[p][D3].op += 10;
    pst[p][E3].op += 10;

    pst[p][D4].op += 20;
    pst[p][E4].op += 20;

    pst[p][D5].op += 10;
    pst[p][E5].op += 10;

    // Knights ////////////////////////////////////////////

    p = WN;

    // center
    foreach (sq; A1..SQ.size)
    {
      pst[p][sq].op += NLine[sq.file] * term[KnightCenterOp];
      pst[p][sq].op += NLine[sq.rank] * term[KnightCenterOp];
      pst[p][sq].eg += NLine[sq.file] * term[KnightCenterEg];
      pst[p][sq].eg += NLine[sq.rank] * term[KnightCenterEg];
    }

    // rank
    foreach (sq; A1..SQ.size)
      pst[p][sq].op += NRank[sq.rank] * term[KnightRank];

    // back rank
    foreach (sq; A1..A2)
      pst[p][sq].op -= term[KnightBackRank];

    // "trapped"
    pst[p][A8].op -= term[KnightTrapped];
    pst[p][H8].op -= term[KnightTrapped];

    // Bishops ////////////////////////////////////////////

    p = WP;

    // center
    foreach (sq; A1..SQ.size)
    {
      pst[p][sq].op += BLine[sq.file] * term[BishopCenterOp];
      pst[p][sq].op += BLine[sq.rank] * term[BishopCenterOp];
      pst[p][sq].eg += BLine[sq.file] * term[BishopCenterEg];
      pst[p][sq].eg += BLine[sq.rank] * term[BishopCenterEg];
    }

    // back rank
    foreach (sq; A1..A2)
      pst[p][sq].op -= term[BishopBackRank];

    // main diagonals
    for (int i = 0; i < 8; i++)
    {
      pst[p][to_sq(i, i)].op     += term[BishopDiagonal];
      pst[p][to_sq(i, 7 - i)].op += term[BishopDiagonal];
    }

    // Rooks //////////////////////////////////////////////

    p = WR;

    // file
    foreach (sq; A1..SQ.size)
      pst[p][sq].op += RFile[sq.file] * term[RookFileOp];

    // Queens /////////////////////////////////////////////

    p = WQ;

    // center
    foreach (sq; A1..SQ.size)
    {
      pst[p][sq].op += QLine[sq.file] * term[QueenCenterOp];
      pst[p][sq].op += QLine[sq.rank] * term[QueenCenterOp];
      pst[p][sq].eg += QLine[sq.file] * term[QueenCenterEg];
      pst[p][sq].eg += QLine[sq.rank] * term[QueenCenterEg];
    }

    // back rank
    foreach (sq; A1..A2)
      pst[p][sq].op -= term[QueenBackRank];

    // Kings //////////////////////////////////////////////

    p = WK;

    foreach (sq; A1..SQ.size)
    {
      pst[p][sq].op += KFile[sq.file] * term[KingFile];
      pst[p][sq].op += KRank[sq.rank] * term[KingRank];
      pst[p][sq].eg += KLine[sq.file] * term[KingCenterEg];
      pst[p][sq].eg += KLine[sq.rank] * term[KingCenterEg];
    }

    // Symmetrical copy for black

    for (int i = 0; i < 12; i += 2)
      foreach (sq; A1..SQ.size)
        pst[i][sq] = pst[i + 1][sq.opp];

    //import std.format;
    //for (int y = 7; y >= 0; y--)
    //{
    //  string row;
    //  for (int x = 0; x < 8; x++)
    //  {
    //    SQ sq = to_sq(x, y);
    //    row ~= format("%s ", pst[WK][sq].eg);
    //  }
    //  log(row);
    //}

    // Passers ////////////////////////////////////////////////////

    auto unzero = (double x) => x > 0 ? x : .001;
    auto pscore = (double m, double k, int rank)
    {
      auto nexp = (double k, int x) => 1 / (1 + exp(6 - k * x));
      return cast(int)(m * nexp(k, rank) / nexp(k, 6));
    };

    for (int rank = 0; rank < 8; rank++)
    {
      const double k = unzero(term[PasserK]) / 32.0;
      passer_scale[rank] = pscore(256, k, rank);
    }
  }
}

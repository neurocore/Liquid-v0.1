module eval_smart;
import std.math : exp;
import eval, tables, piece, square, consts;
import app, board, bitboard, types, utils;
import vals;

class EvalSmart : Eval
{
  int[SQ.size][Color.size] candidate, passer, supported;

  this(string tune = Tune.Def)
  {
    set(tune);
    log("[EvalSmart]");
    log(toString());
    init();

    //log(pst);
  }

  override void init()
  {
    // Setting piece scores  //////////////////////////////////////

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

    // Passers ////////////////////////////////////////////////////

    auto unzero = (double x) => x > 0 ? x : .001;
    auto pscore = (double m, double k, int rank)
    {
      auto nexp = (double k, int rank) => exp(k * rank) - 1;
      return cast(int)(m * nexp(k, rank) / nexp(k, 8));
    };

    double k, m;
    for (int rank = 0; rank < 8; rank++)
    {
      k = unzero(term[CandidateK]) / 32.0;
      m = term[Candidate];
      candidate[1][rank] = pscore(m, k, rank);

      k = unzero(term[PasserK]) / 32.0;
      m = term[Passer];
      passer[1][rank] = pscore(m, k, rank);

      k = unzero(term[PasserSupportK]) / 32.0;
      m = term[PasserSupport];
      supported[1][rank] = pscore(m, k, rank);
    }

    for (int rank = 0; rank < 8; rank++)
    {
      candidate[0][rank] = candidate[1][7 - rank];
         passer[0][rank] =    passer[1][7 - rank];
      supported[0][rank] = supported[1][7 - rank];
    }
  }

  // TODO: ability to self-explain position eval
  //       change type for Val and collect data
  //       into it (evaldebug mode)

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

  // - 88=24 king safety
  // - 26=26 tropism
  // - 57=25 xrays & pins
  // - 46=22 forks

  // - 35=19 pawns doubled, blocked, isolated, holes
  // - 24=16 contact check
  // - 34=14 bad rook
  // - 33= 9 bad bishop
  // - 53= 5 outposts

  // ? space
  // ? connectivity

  override int eval(const Board B) const
  {
    int val = 0;
    
    for (int i = 0; i < BK; i++)
    {
      const u64 bb = B.piece[i];
      val += score[i] * popcnt(bb);
    }

    val += evaluate!White(B) - evaluate!Black(B);
    return (B.color == White ? val : -val) + term[Tempo];
  }

  private int evaluate(Color col)(const Board B) const
  {
    Vals vals;
    vals += evaluateP!col(B);
    vals += evaluateK!col(B);
    vals += evaluateB!col(B);
    vals += evaluateR!col(B);
    vals += evaluateQ!col(B);

    int phase = B.phase(col);
    return vals.tapered(phase);
  }

  private Vals evaluateP(Color col)(const Board B) const
  {
    Piece p = to_piece(Pawn, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const Color col = p.color;

      // pst

      vals += pst[p][sq];

      // passers

      if (!(Table.front(col, sq) & B.piece[p.opp]))
      {
        u64 sentries = Table.att_span(col, sq) & B.piece[p.opp];
        if (!sentries)
        {
          if (Table.psupport(col, sq) & B.piece[p])
            vals += Vals.both(supported[col][sq.rank]);
          else
            vals += Vals.both(passer[col][sq.rank]);
        }
        else if (!rlsb(sentries))
          vals += Vals.both(candidate[col][sq.rank]);
      }

    }
    return vals;
  }

  private Vals evaluateN(Color col)(const Board B) const
  {
    Piece p = to_piece(Knight, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // pst & mobility

      vals += pst[p][sq];
      vals += Vals.both(term[NMob] * popcnt(att) / 32);

      // outposts

      // TODO
    }
    return vals;
  }

  private Vals evaluateB(Color col)(const Board B) const
  {
    Piece p = to_piece(Bishop, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // pst & mobility

      vals += pst[p][sq];
      vals += Vals.both(term[BMob] * popcnt(att) / 32);
    }

    // bishop pair

    if (popcnt(B.piece[p]) > 1) vals += Vals.both(term[BishopPair]);
    return vals;
  }

  private Vals evaluateR(Color col)(const Board B) const
  {
    Piece p = to_piece(Rook, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // pst & mobility

      vals += pst[p][sq];
      vals += Vals.both(term[RMob] * popcnt(att) / 32);

      // rook on 7th

      u64 own_pawns = B.piece[to_piece(Pawn, p.color)];
      u64 opp_pawns = B.piece[to_piece(Pawn, p.color.opp)];
      const int rook_rank = p.color == White ? 7 : 1;
      const int king_rank = p.color == White ? 8 : 0;

      if (sq.rank == rook_rank)
      {
        SQ opp_king = bitscan(B.piece[to_piece(King, p.color.opp)]);

        if (opp_king.rank == king_rank || popcnt(opp_pawns) > 1)
          vals += Vals.as_op(term[Rook7thOp]);
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

  private Vals evaluateQ(Color col)(const Board B) const
  {
    Piece p = to_piece(Queen, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);

      // pst & mobility

      vals += pst[p][sq];
      vals += Vals.as_eg(term[QMob] * popcnt(att) / 32);
    }

    return vals;
  }

  private Vals evaluateK(Color col)(const Board B) const
  {
    Piece p = to_piece(King, col);
    Vals vals;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);

      // pst

      vals += pst[p][sq];
    }

    return vals;
  }
}

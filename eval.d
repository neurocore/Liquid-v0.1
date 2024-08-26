module eval;
import std.string, std.format;
import board, piece, types, consts;
import app, utils, bitboard, square;

enum Stage { OP, EG };
mixin(GenAliases!Stage);

struct Vals
{
  int op, eg;
  Vals negate()
  {
    return Vals(-op, -eg);
  }
}

enum Term
{
  MatKnight, MatBishop, MatRook, MatQueen,
  PawnFile,
  KnightCenterOp, KnightCenterEg,
  KnightRank, KnightBackRank,
  KnightTrapped,
  BishopCenterOp, BishopCenterEg,
  BishopBackRank, BishopDiagonal,
  RookFileOp,
  QueenCenterOp, QueenCenterEg, QueenBackRank,
  KingFile, KingRank, KingCenterEg,
  Doubled, Isolated, Hole,
  NMob, BMob, RMob, QMob,
  BishopPair, BadBishop,
  KnightOutpost,
  RookSemi, RookOpen, Rook7thOp, Rook7thEg, BadRook,
  ContactCheckR, ContactCheckQ,
  Tempo,
  size
}
mixin(GenAliases!Term);
mixin(GenStrings!Term); // term_str

// from Fruit 2.1
const int[8] PFile = [-3, -1, +0, +1, +1, +0, -1, -3];
const int[8] NLine = [-4, -2, +0, +1, +1, +0, -2, -4];
const int[8] NRank = [-2, -1, +0, +1, +2, +3, +2, +1];
const int[8] BLine = [-3, -1, +0, +1, +1, +0, -1, -3];
const int[8] RFile = [-2, -1, +0, +1, +1, +0, -1, -2];
const int[8] QLine = [-3, -1, +0, +1, +1, +0, -1, -3];
const int[8] KLine = [-3, -1, +0, +1, +1, +0, -1, -3];
const int[8] KFile = [+3, +4, +2, +0, +0, +2, +4, +3];
const int[8] KRank = [+1, +0, -2, -3, -4, -5, -6, -7];


class Eval
{
  int[Term.size] term;
  int[Piece.size] score;
  Vals[SQ.size][Piece.size] pst;
  abstract int eval(const Board B) const;
  abstract void init();

  string get() const
  {
    string str;
    for (int i = 0; i < Term.size; i++)
      str ~= term_str[i] ~ ":" ~ format("%s", term[i]) ~ " ";
    return str.strip;
  }

  void set(string str)
  {
    int[string] values;
    string[] parts = str.split(" ");
    foreach (part; parts)
    {
      string[] termval = part.split(":");
      if (termval.length != 2) continue;

      values[termval[0]] = safe_to!int(termval[1]);
    }

    for (int i = 0; i < Term.size; i++)
    {
      string name = term_str[i];
      term[i] = name in values ? values[name] : 0;
    }
  }

  void set(Eval eval)
  {
    for (int i = 0; i < Term.size; i++)
      term[i] = eval.term[i];
    init();
  }

  override string toString() const
  {
    string str;
    for (int i = 0; i < Term.size; i++)
      str ~= format("%18s = %d\n", term_str[i], term[i]);
    return str;
  }
}

////////////////////////////////////////////

class EvalSimple : Eval
{
  override void init()
  {
    score = [-100, 100, -300, 300, -300, 300, -500, 500, -900, 900, -20000, 20000];
  }

  override int eval(const Board B) const
  {
    int val = 0;
    
    for (int i = 0; i < BK; i++)
    {
      const u64 bb = B.piece[i];
      val += score[i] * popcnt(bb);
    }

    val += evaluate!WP(B) - evaluate!BP(B);
    val += evaluate!WK(B) - evaluate!BK(B);
    val += evaluate!WB(B) - evaluate!BB(B);
    val += evaluate!WR(B) - evaluate!BR(B);
    val += evaluate!WQ(B) - evaluate!BQ(B);

    return B.color == White ? val : -val;
  }

  private int evaluate(Piece p)(const Board B) const
  {
    int val = 0;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);
      val += 3 * popcnt(att);
    }
    return val;
  }
}

////////////////////////////////////////////

class EvalSmart : Eval
{
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
    // Setting piece scores

    score[WP] = 100;
    score[WN] = term[MatKnight];
    score[WB] = term[MatBishop];
    score[WR] = term[MatRook];
    score[WQ] = term[MatQueen];
    score[WK] = 20000;

    for (int i = 0; i < Piece.size; i += 2)
      score[i] = -score[i + 1];

    // Building piece-square table

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
        pst[i][sq] = pst[i + 1][sq.opp];//.negate;
  }

  override int eval(const Board B) const
  {
    int val = 0;
    
    for (int i = 0; i < BK; i++)
    {
      const u64 bb = B.piece[i];
      val += score[i] * popcnt(bb);
    }

    val += evaluate!WP(B) - evaluate!BP(B);
    val += evaluate!WK(B) - evaluate!BK(B);
    val += evaluate!WB(B) - evaluate!BB(B);
    val += evaluate!WR(B) - evaluate!BR(B);
    val += evaluate!WQ(B) - evaluate!BQ(B);

    return (B.color == White ? val : -val) + term[Tempo];
  }

  private int evaluate(Piece p)(const Board B) const
  {
    int val = 0;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      const SQ sq = bitscan(bb);
      const u64 att = B.attack(p, sq);
      val += 3 * popcnt(att);
      val += pst[p][sq].op;
    }
    return val;
  }

  private int evaluate(Piece p : WP, BP)(const Board B) const
  {
    int val = 0;
    for (u64 bb = B.piece[p]; bb; bb = rlsb(bb))
    {
      //const SQ sq = bitscan(bb);
      //const u64 att = B.attack(p, sq);
      //val += 3 * popcnt(att);
      //val += pst[p][sq].op;
    }
    return val;
  }
}

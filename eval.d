module eval;
import std.string, std.format;
import board, piece, types, consts;
import app, utils, bitboard, square;
import vals;

enum Stage { OP, EG };
mixin(GenAliases!Stage);

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
  Doubled, Isolated, Backward,
  NMob, BMob, RMob, QMob,
  BishopPair, BadBishop,
  KnightOutpost,
  RookSemi, RookOpen, Rook7thOp, Rook7thEg, BadRook,
  KnightFork, BishopFork,
  KnightAdj, RookAdj, EarlyQueen,
  ContactCheckR, ContactCheckQ,
  Shield1, Shield2,
  Candidate, CandidateK, Passer, PasserK, PasserSupport, PasserSupportK,
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

// from CPW-Engine
const int[9] PAdj = [-5, -4, -3, -2, -1, 0, +1, +2, +3];

class Eval
{
  int[Term.size] term;
  int[Piece.size] score;
  Vals[SQ.size][Piece.size] pst;
  abstract int eval(const Board B);
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

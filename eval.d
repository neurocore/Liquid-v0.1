module eval;
import board, piece, types;
import bitboard, square;

class Eval
{
  abstract int eval(const Board B) const;
}

class EvalSimple : Eval
{
  override int eval(const Board B) const
  {
    const int[] score = [-100, 100, -300, 300, -300, 300, -500, 500, -900, 900];
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

  int evaluate(Piece p)(const Board B) const
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

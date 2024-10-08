module tables;
import std.typecons, std.math;
import types, square, piece;
import utils, bitboard;

alias Ray = Tuple!(int, int);
alias Rays = const(Ray[]);

Rays wp_offset = [[-1, 1], [1, 1]];
Rays bp_offset = [[-1,-1], [1,-1]];

Rays n_offset =
[
  [1, 2], [1,-2], [-1, 2], [-1,-2],
  [2, 1], [2,-1], [-2, 1], [-2,-1]
];

Rays k_offset =
[
  [-1, 1], [0, 1], [1, 1],
  [-1, 0],         [1, 0],
  [-1,-1], [0,-1], [1,-1]
];

Rays diag_offset = [[-1,-1], [-1, 1], [1,-1], [1, 1]];
Rays rook_offset = [[-1, 0], [0, 1], [1, 0], [0,-1]];

// front_one  front  att_span  att_rear  isolator  psupport
//
//   ---       -x-     x-x       ---       x-x       ---
//   -x-       -x-     x-x       ---       x-x       ---
//   -O-       -O-     -O-       xOx       xOx       xOx
//   ---       ---     ---       x-x       x-x       x-x
//   ---       ---     ---       x-x       x-x       ---
        
// isolator = att_span | att_rear
// psupport = rank & isolator

final class Table
{
  private this() {}; // instance creation is forbidden
  static this()
  {
    pmov_.zeros;
    att_.zeros;
    dir_.zeros;
    between_.zeros;
    front_one_.zeros;
    front_.zeros;
    att_span_.zeros;
    att_rear_.zeros;
    psupport_.zeros;
    isolator_.zeros;
    
    init_piece(WP, wp_offset);
    init_piece(BP, bp_offset);
    init_piece(WN, n_offset);
    init_piece(BN, n_offset);
    init_piece(WK, k_offset);
    init_piece(BK, k_offset);
    init_piece(WB, diag_offset, true);
    init_piece(BB, diag_offset, true);
    init_piece(WQ, diag_offset, true);
    init_piece(BQ, diag_offset, true);
    init_piece(WR, rook_offset, true);
    init_piece(BR, rook_offset, true);
    init_piece(WQ, rook_offset, true);
    init_piece(BQ, rook_offset, true);

    foreach (SQ sq; A1 .. SQ.size)
    {
      if (sq.rank > 0 && sq.rank < 7)
      {
        pmov_[0][sq] = sq.bit >> 8;
        pmov_[1][sq] = sq.bit << 8;
      }

      if (sq.rank == 6) pmov_[0][sq] |= sq.bit >> 16;
      if (sq.rank == 1) pmov_[1][sq] |= sq.bit << 16;

      front_one_[0][sq] = Empty;
      front_one_[1][sq] = Empty;
      if (rank(sq) < 7) front_one_[0][sq] = sq.bit >> 8;
      if (rank(sq) > 0) front_one_[1][sq] = sq.bit << 8;

      front_[0][sq] = Empty;
      front_[1][sq] = Empty;
      for (u64 bb = sq.bit >> 8; bb; bb >>= 8) front_[0][sq] |= bb;
      for (u64 bb = sq.bit << 8; bb; bb <<= 8) front_[1][sq] |= bb;

      if (sq.file > 0) isolator_[sq] |= file_bb[sq.file - 1];
      if (sq.file < 7) isolator_[sq] |= file_bb[sq.file + 1];
    }

    foreach (SQ sq; A1 .. SQ.size)
    {
      att_span_[0][sq]  = file(sq) > 0 ? front_[0][sq.sub(1)] : Empty;
      att_span_[0][sq] |= file(sq) < 7 ? front_[0][sq.add(1)] : Empty;

      att_span_[1][sq]  = file(sq) > 0 ? front_[1][sq.sub(1)] : Empty;
      att_span_[1][sq] |= file(sq) < 7 ? front_[1][sq.add(1)] : Empty;

      att_rear_[0][sq] = att_span_[0][sq] ^ isolator_[sq];
      att_rear_[1][sq] = att_span_[1][sq] ^ isolator_[sq];

      u64 adj = rank_bb[sq.rank] & isolator_[sq];
      psupport_[0][sq] = adj | att_[WP][sq];
      psupport_[1][sq] = adj | att_[BP][sq];
    }

    foreach (SQ i; A1 .. SQ.size)
    {
      foreach (SQ j; i.add(1) .. SQ.size) // j > i
      {
        dir_[i][j] = 0;
        between_[i][j] = Empty;
        int dx = file(j) - file(i);
        int dy = rank(j) - rank(i);

        if (abs(dx) == abs(dy) // Diagonal
        ||  !dx || !dy)        // Orthogonal
        {
          int sx = sgn(dx);
          int sy = sgn(dy);
          int dt = sgn(dx) + 8 * sgn(dy);
          dir_[i][j] = dt;

          for (int k = i + dt; k < j; k += dt)
            between_[i][j] |= (Bit << k);
        }

        dir_[j][i] = -dir_[i][j];
        between_[j][i] = between_[i][j];
      }
    }
  }

static:
  u64 p_moves(Color color, SQ sq)  { return pmov_[color][sq]; }
  u64 atts(Piece piece, SQ sq)     { return att_[piece][sq]; }
  int direction(SQ i, SQ j)        { return dir_[i][j]; }
  u64 between(SQ i, SQ j)          { return between_[i][j]; }
  u64 front_one(Color color, SQ j) { return front_one_[color][j]; }
  u64 front(Color color, SQ j)     { return front_[color][j]; }
  u64 att_span(Color color, SQ j)  { return att_span_[color][j]; }
  u64 att_rear(Color color, SQ j)  { return att_rear_[color][j]; }
  u64 psupport(Color color, SQ j)  { return psupport_[color][j]; }
  u64 isolator(SQ j)               { return isolator_[j]; }

private:
  void init_piece(Piece piece, Rays rays, bool slider = false)
  {
    foreach (SQ sq; A1 .. SQ.size)
    {
      foreach (Ray ray; rays)
      {
        int x = file(sq);
        int y = rank(sq);

        do
        {
          x += ray[0];
          y += ray[1];

          if (x < 0 || x > 7 || y < 0 || y > 7) break;

          att_[piece][sq] |= to_sq(x, y).bit;
        }
        while (slider);
      }
    }
  }

  u64[SQ.size + 2][SQ.size + 2] pmov_;
  u64[SQ.size + 2][Piece.size] att_;
  int[SQ.size + 2][SQ.size + 2] dir_;
  u64[SQ.size + 2][SQ.size + 2] between_;
  u64[SQ.size + 2][Color.size] front_one_;
  u64[SQ.size + 2][Color.size] front_;
  u64[SQ.size + 2][Color.size] att_span_;
  u64[SQ.size + 2][Color.size] att_rear_;
  u64[SQ.size + 2][Color.size] psupport_;
  u64[SQ.size + 2] isolator_;
}

module movelist;
import consts, square, moves;
import piece, board, solver;
import utils, types;

struct MoveVal
{
  Move move;
  i64 val;
}

// Iterable (in for) move list

class MoveListGen(bool simple = false)
{
  this()
  {
    hashmove_ = Move.None;
    moves_ = new MoveVal[Limits.Moves];
    clear();
  }

  void clear(Move hashmove = Move.None)
  {
    curr_ = last_ = first_ = moves_.ptr;
    hashmove_ = Move.None;
    correct_hash_ = false;

    if (hashmove != Move.None)
    {
      add(hashmove, Order.Hash);
      hashmove_ = hashmove;
    }
  }

  bool is_hash_correct() const
  {
    if (hashmove_.is_empty) return true;
    return correct_hash_;
  }

  bool   empty() const { return last_ == first_; }
  size_t count() const { return last_ -  first_; }

  ref Move front()
  {
    static if (simple) return first_.move;

    curr_ = first_;
    for (MoveVal * ptr = first_ + 1; ptr != last_; ++ptr)
    {
      if (ptr.val > curr_.val) curr_ = ptr;
    }
    return curr_.move;
  }

  void popFront()
  {
    static if (simple)
    {
      first_++;
    }
    else
    {
      remove(curr_);
    }
  }

  void add(Move move, i64 val = 0)
  {
    if (move == hashmove_)
    {
      correct_hash_ = true;
      return;
    }
    assert(last_ - first_ < Limits.Moves);
    last_.move = move;
    last_.val = val;
    ++last_;
  }

  void add_move(SQ from, SQ to, MT mt = MT.Quiet)
  {
    add(Move(from, to, mt));
  }

  void add_prom(SQ from, SQ to)
  {
    add(Move(from, to, MT.QProm));
    add(Move(from, to, MT.RProm));
    add(Move(from, to, MT.BProm));
    add(Move(from, to, MT.NProm));
  }

  void add_capprom(SQ from, SQ to)
  {
    add(Move(from, to, MT.QCapProm));
    add(Move(from, to, MT.RCapProm));
    add(Move(from, to, MT.BCapProm));
    add(Move(from, to, MT.NCapProm));
  }

  // r1bk2nQ/pppn3p/5p2/3q4/8/2B2N1P/PP3PP1/3RR1K1 b - - 1 23

  void value_moves(bool qs = false)(Board board, const Undo * undo, ref u64[64][64][2] history)
  {
    const int[] cost = [1, 1, 3, 3, 3, 3, 5, 5, 9, 9, 200, 200, 0, 0];
    const int[] prom = [0, cost[WN], cost[WB], cost[WR], cost[WQ], 0];

    for (MoveVal * ptr = first_; ptr != last_; ptr++)
    {
      if (ptr.move == hashmove_)      { ptr.val = Order.Hash;    continue; }
      if (ptr.move == undo.killer[0]) { ptr.val = Order.Killer1; continue; }
      if (ptr.move == undo.killer[1]) { ptr.val = Order.Killer2; continue; }

      const SQ from = ptr.move.from;
      const SQ to   = ptr.move.to;
      const MT mt   = ptr.move.mt;

      int a = cost[board[from]]; // attack
      int v = cost[board[to]];  // victim

      if (mt.is_prom)
      {
        int p = prom[mt.promoted];
        ptr.val = Order.WinCap + 100 * (p + v) - a;
      }
      else if (mt.is_ep)
      {
        ptr.val = Order.EqCap;
      }
      else if (mt.is_cap)
      {
        i64 order = compare(v, a, Order.BadCap, Order.EqCap, Order.WinCap);
        ptr.val = order + 100 * v - a; // MVV-LVA
      }
      else
      {
        ptr.val = history[board.color][from][to];
      }
    }
  }

  override string toString() const
  {
    import std.format;
    string str;
    for (const(MoveVal) * ptr = first_; ptr != last_; ptr++)
    {
      str ~= format("%v - %d\n", ptr.move, ptr.val);
    }
    return str ~ "\n";
  }

private:
  Move hashmove_;
  MoveVal[] moves_;
  MoveVal * first_, last_, curr_;
  int lower_bound_ = -int.max; // TODO: not implemented
  bool correct_hash_ = false;

  void remove(MoveVal * ptr)
  {
    *ptr = *(last_ - 1);
    --last_;
  }
}

alias MoveListSimple = MoveListGen!true;
alias MoveList = MoveListGen!false;

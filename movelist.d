module movelist;
import consts, square, moves;
import piece, board, solver;
import utils;

struct MoveVal
{
  Move move;
  int val;
}

// Iterable (in for) move list

class MoveListGen(bool simple = false)
{
  this(Move hashmove = Move())
  {
    this.hashmove = hashmove;
    this.moves = new MoveVal[Limits.Moves];
    clear();
  }

  void clear(Move hash_move = Move())
  {
    curr = last = first = moves.ptr;
    hashmove = Move();
    if (hash_move)
    {
      add(hash_move, 100000);
      hashmove = hash_move;
    }
  }

  bool   empty() const { return last == first; }
  size_t count() const { return last -  first; }

  ref Move front()
  {
    static if (simple) return first.move;

    curr = first;
    for (MoveVal * ptr = first + 1; ptr != last; ++ptr)
    {
      if (ptr.val > curr.val) curr = ptr;
    }
    return curr.move;
  }

  void popFront()
  {
    static if (simple)
    {
      first++;
    }
    else
    {
      remove(curr);
    }
  }

  void add(Move move, int val = 0)
  {
    if (move == hashmove) return;
    assert(last - first < Limits.Moves);
    last.move = move;
    last.val = val;
    ++last;
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

  void value_moves(bool qs = false)(Board board, const Undo * undo)
  {
    //const int[] val  = [100, 100, 300, 300, 350, 350, 500, 500, 900, 900, 20000, 20000, 0, 0];
    const int[] cost = [1, 1, 3, 3, 3, 3, 5, 5, 9, 9, 200, 200, 0, 0];
    const int[] prom = [0, cost[WN], cost[WB], cost[WR], cost[WQ], 0];

    for (MoveVal * ptr = first; ptr != last; ptr++)
    {
      if (ptr.move == hashmove)       { ptr.val = Order.Hash;    continue; }
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
        int order = compare(v, a, Order.BadCap, Order.EqCap, Order.WinCap);
        ptr.val = order + 100 * v - a; // MVV-LVA
      }
    }
  }

  override string toString() const
  {
    import std.format;
    string str;
    for (const(MoveVal) * ptr = first; ptr != last; ptr++)
    {
      str ~= format("%v - %i", ptr.move, ptr.val);
    }
    return str ~ "\n";
  }

private:
  Move hashmove;
  MoveVal[] moves;
  MoveVal * first, last, curr;
  int lower_bound = -int.max; // TODO: not implemented

  void remove(MoveVal * ptr)
  {
    *ptr = *(last - 1);
    --last;
  }
}

alias MoveListSimple = MoveListGen!true;
alias MoveList = MoveListGen!false;

module movelist;
import consts;
import square;
import moves;

alias Valuator = int function(Move);

struct MoveVal
{
  Move move;
  int val;
}

class MoveList
{
  this(Move hashmove = Move())
  {
    this.hashmove = hashmove;
  }

  void clear(Move hash_move = Move())
  {
    last = first = moves.ptr;
    hashmove = Move();
    if (!hash_move.is_empty)
    {
      add(hash_move, 100000);
      hashmove = hash_move;
    }
  }

  bool   empty() const { return last == first; }
  size_t count() const { return last -  first; }

  Move get_next_move()
  {
    if (empty()) return Move();
    return (first++).move;
  }

  Move get_best_move(int lower_bound = -int.max)
  {
    if (empty()) return Move();
    MoveVal * best = first;
    for (MoveVal * ptr = first + 1; ptr != last; ++ptr)
    {
      if (ptr.val > best.val)
      {
        best = ptr;
      }
    }
    Move move = best.move;
    remove(best);
    return move;
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

  void value_moves(Valuator valuator)
  {
    for (MoveVal * ptr = first; ptr != last; ptr++)
    {
      ptr.val = valuator(ptr.move);
    }
  }

  void print() const
  {
    import std.stdio;
    for (const(MoveVal) * ptr = first; ptr != last; ptr++)
    {
      writefln("%v - %i", ptr.move, ptr.val);
    }
    writeln();
  }

private:
  Move hashmove;
  MoveVal[Limits.Moves] moves;
  MoveVal * first, last;

  void remove(MoveVal * ptr)
  {
    *ptr = *(last - 1);
    --last;
  }
}

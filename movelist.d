module movelist;
import consts, square, moves;

alias Valuator = int function(Move);

struct MoveVal
{
  Move move;
  int val;
}

class MoveListGen(bool simple = false)
{
  this(Move hashmove = Move())
  {
    this.hashmove = hashmove;
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
    if (simple) return first.move;

    curr = first;
    for (MoveVal * ptr = first + 1; ptr != last; ++ptr)
    {
      if (ptr.val > curr.val) curr = ptr;
    }
    return curr.move;
  }

  void popFront()
  {
    if (simple)
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

  void value_moves(Valuator valuator)
  {
    for (MoveVal * ptr = first; ptr != last; ptr++)
    {
      ptr.val = valuator(ptr.move);
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
  MoveVal[Limits.Moves] moves;
  MoveVal * first, last, curr;
  bool simple = false;
  int lower_bound = -int.max; // TODO: not implemented

  void remove(MoveVal * ptr)
  {
    *ptr = *(last - 1);
    --last;
  }
}

alias MoveListSimple = MoveListGen!true;
alias MoveList = MoveListGen!false;

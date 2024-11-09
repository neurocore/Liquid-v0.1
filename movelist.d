module movelist;
import consts, square, moves;
import piece, board, solver;
import utils, types;

alias History = u64[64][64][2];

struct MoveVal
{
  Move move;
  i64 val;
}

enum PromMode
{
  N = 1 << 0,
  B = 1 << 1,
  R = 1 << 2,
  Q = 1 << 3,

  QS  =             Q,
  PVS = N |     R | Q,
  ALL = N | B | R | Q,
}

enum Step
{
  Hash,
  GenCaps, WinCaps, EqCaps,
  GenKillers, Killers,
  GenQuiets, Quiets, BadCaps,
  Done
}

class MoveList
{
  this()
  {
    moves = new MoveVal[Limits.Moves];
    clear();
  }

  void clear()
  {
    curr = last = first = moves.ptr;
  }

  bool   empty() const { return last == first; }
  size_t count() const { return last -  first; }

  void remove_curr()
  {
    remove(curr);
  }

  void reveal_pocket()
  {
    first = moves.ptr;
  }

  Move get_move(i64 lower_bound = -i64.max)
  {
    curr = first;
    for (MoveVal * ptr = first + 1; ptr != last; ++ptr)
    {
      if (ptr.val > curr.val) curr = ptr;
    }

    if (curr.val >= lower_bound) return curr.move;

    first = last; // putting all moves into pocket
    return Move.None;
  }

  Move[] get_moves()
  {
    Move[] moves;
    for (MoveVal * ptr = first; ptr != last; ++ptr)
    {
      moves ~= ptr.move;
    }
    return moves;
  }

  void swap(MoveVal * a, MoveVal * b) const
  {
    MoveVal t = *a;
    *a = *b;
    *b = t;
  }

  void add(Move move, i64 val = 0)
  {
    assert(last - first < Limits.Moves);
    last.move = move;
    last.val = val;
    ++last;
  }

  void add_move(SQ from, SQ to, MT mt = MT.Quiet)
  {
    add(Move(from, to, mt));
  }

  void add_prom(SQ from, SQ to, PromMode mode = PromMode.ALL)
  {
    if (mode & PromMode.Q) add(Move(from, to, MT.QProm));
    if (mode & PromMode.R) add(Move(from, to, MT.RProm));
    if (mode & PromMode.B) add(Move(from, to, MT.BProm));
    if (mode & PromMode.N) add(Move(from, to, MT.NProm));
  }

  void add_capprom(SQ from, SQ to, PromMode mode = PromMode.ALL)
  {
    if (mode & PromMode.Q) add(Move(from, to, MT.QCapProm));
    if (mode & PromMode.R) add(Move(from, to, MT.RCapProm));
    if (mode & PromMode.B) add(Move(from, to, MT.BCapProm));
    if (mode & PromMode.N) add(Move(from, to, MT.NCapProm));
  }

  void remove_move(Move move)
  {
    for (MoveVal * ptr = first; ptr < last; ++ptr)
    {
      if (ptr.move == move)
      {
        remove(ptr);
        break;
      }
    }
  }

  void remove_moves(Move[2] moves)
  {
    for (MoveVal * ptr = first; ptr < last; ++ptr)
    {
      foreach (move; moves)
      {
        if (ptr.move == move)
        {
          remove(ptr);
        }
      }
    }
  }

  void value_moves(bool att = false)(ref Board board, ref History history)
  {
    const int[] cost = [1, 1, 3, 3, 3, 3, 5, 5, 9, 9, 200, 200, 0, 0];
    const int[] prom = [0, cost[WN], cost[WB], cost[WR], cost[WQ], 0];

    for (MoveVal * ptr = first; ptr != last; ptr++)
    {
      const SQ from = ptr.move.from;
      const SQ to   = ptr.move.to;
      const MT mt   = ptr.move.mt;

      static if (att)
      {
        const int a = cost[board[from]]; // attack
        const int v = cost[board[to]];  // victim

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
          int score = board.see(ptr.move);
          i64 order = compare(score, 0, Order.BadCap, Order.EqCap, Order.WinCap);
          ptr.val = order + score;
        }
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
    for (const(MoveVal) * ptr = first; ptr != last; ptr++)
    {
      str ~= format("%v - %d\n", ptr.move, ptr.val);
    }
    return str ~ "\n";
  }

private:
  MoveVal[] moves;
  MoveVal * first, last, curr;

  void remove(MoveVal * ptr)
  {
    *ptr = *(last - 1);
    --last;
  }
}

// Iterable (in foreach loop) move series

class MoveSeries
{
  this(Board * board)
  {
    B = board;
    ml = new MoveList;
    hash_mv = Move.None;
  }

  void init(bool att = false, Move hashmove = Move.None, PromMode pmode = PromMode.ALL)
  {
    qs = att;
    this.pmode = pmode;
    step = qs ? Step.GenCaps : Step.Hash;
    hash_mv = Move.None;
    ml.clear();

    if (hashmove != Move.None)
    {
      ml.add(hashmove, Order.Hash);
      hash_mv = hashmove;
    }
  }

  bool empty() const { return step == Step.Done; }
  Step get_step() const { return step; }
  void popFront() { ml.remove_curr(); }

  void remove_hash_move()
  {
    if (!hash_mv.is_empty)
    {
      ml.remove_move(hash_mv);
    }
  }

  void remove_hash_and_killers()
  {
    remove_hash_move();
    ml.remove_moves(killer);
  }

  Move front()
  {
    switch (step)
    {
      case Step.Hash:
        //writeln("Step.Hash");
        step++;
        if (!hash_mv.is_empty) return hash_mv;
        goto case;

      case Step.GenCaps:
        //writeln("Step.GenCaps");
        step++;
        B.generate!1(ml, pmode);
        remove_hash_move();
        ml.value_moves!1(*B, history);
        goto case;

      case Step.WinCaps:
        //writeln("Step.WinCaps");
        if (!ml.empty)
        {
          Move mv = ml.get_move(Order.WinCap);
          if (!mv.is_empty) return mv;
        }
        ml.reveal_pocket();
        step++;
        goto case;

      case Step.EqCaps:
        //writeln("Step.EqCaps");
        if (!ml.empty)
        {
          Move mv = ml.get_move(Order.EqCap);
          if (!mv.is_empty) return mv;
        }
        if (qs)
        {
          ml.reveal_pocket();
          step = Step.BadCaps;
          goto case Step.BadCaps;
        }
        step++;
        goto case;

      case Step.GenKillers:
        //writeln("Step.GenKillers");
        if (B.is_allowed(killer[0])) ml.add(killer[0], Order.Killer1);
        if (B.is_allowed(killer[1])) ml.add(killer[1], Order.Killer2);
        step++;
        goto case;

      case Step.Killers:
        //writeln("Step.Killers");
        if (!ml.empty)
        {
          Move mv = ml.get_move(Order.Killer2);
          if (!mv.is_empty) return mv;
        }
        step++;
        goto case;

      case Step.GenQuiets:
        //writeln("Step.GenQuiets");
        step++;
        B.generate!0(ml, pmode);
        remove_hash_and_killers();
        ml.value_moves!0(*B, history);
        goto case;

      case Step.Quiets:
        //writeln("Step.Quiets");

        if (!ml.empty)
        {
          Move mv = ml.get_move(Order.Quiet);
          if (!mv.is_empty) return mv;
        }
        ml.reveal_pocket();
        step++;
        goto case;

      case Step.BadCaps:
        //writeln("Step.BadCaps");
        if (!ml.empty)
        {
          Move mv = ml.get_move();
          if (!mv.is_empty) return mv;
        }
        step++;
        goto default;

      default:
        //writeln("default");
        return Move.None;
    }

    return Move.None;
  }

public:
  Move[2] killer;
  History history;

private:
  Board * B;
  MoveList ml;
  PromMode pmode;
  Move hash_mv;
  Step step;
  bool qs;
}

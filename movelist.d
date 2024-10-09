module movelist;
import consts, square, moves;
import piece, board, solver;
import utils, types;

struct MoveVal
{
  Move move;
  i64 val;
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
  
  // [20241007]
  // not clearing ep square: ed Qd1 Kb8 Bb2 (c5d4 - illegal)
  // 2k2b1r/1p3ppp/q4n2/2pr4/Pp1Pp2P/1N2P1P1/1PQ2PR1/R1B1K3 b - d3 0 19

  // [20241009]
  // showing here mate in 2, but there is not (Re1+ missing passer)
  // 8/5R2/5p2/1p6/5k2/1P6/4r1p1/6K1 b - - 1 46 


  void value_moves(bool att = false)(ref Board board/*, ref u64[64][64][2] history*/)
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
          i64 order = compare(v, a, Order.BadCap, Order.EqCap, Order.WinCap);
          ptr.val = order + 100 * v - a; // MVV-LVA
        }
      }
      else
      {
        //ptr.val = history[board.color][from][to];
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

  void init(bool att = false, Move hashmove = Move.None)
  {
    qs = att;
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
  void popFront() { ml.remove_curr(); }

  // perft 6 - 119060302

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
        B.generate!1(ml);
        // TODO: remove hash move
        ml.value_moves!1(*B);
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
        if (!killer[0].is_empty) ml.add(killer[0], Order.Killer1);
        if (!killer[1].is_empty) ml.add(killer[1], Order.Killer2);
        step++;
        goto case;

      case Step.Killers:
        //writeln("Step.Killers");
        if (!ml.empty) return ml.get_move(Order.Killer2);
        step++;
        goto case;

      case Step.GenQuiets:
        //writeln("Step.GenQuiets");
        step++;
        B.generate!0(ml);
        // TODO: remove hash move and killers
        ml.value_moves!0(*B);
        goto case;

      case Step.Quiets:
        //writeln("Step.Quiets");
        if (!ml.empty) return ml.get_move();
        ml.reveal_pocket();
        step++;
        goto case;

      case Step.BadCaps:
        //writeln("Step.BadCaps");
        if (!ml.empty) return ml.get_move(Order.BadCap);
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

private:
  Board * B;
  MoveList ml;
  Move hash_mv;
  Step step;
  bool qs;
}

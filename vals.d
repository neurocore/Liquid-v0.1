module vals;
import std.format;

enum Phase
{
  Light = 1, Rook = 2, Queen = 4, Endgame = 7,
  Total = 2 * (Light * 4 + Rook * 2 + Queen)
};

struct Vals
{
  int op, eg;

  this(int op, int eg)
  {
    this.op = op;
    this.eg = eg;
  }

  static Vals both(int x)  { return Vals(x, x); }
  static Vals as_op(int x) { return Vals(x, 0); }
  static Vals as_eg(int x) { return Vals(0, x); }

  Vals opNeg()
  {
    return Vals(-op, -eg);
  }

  Vals opBinary(string oper)(Vals vals)
  {
    final switch(oper)
    {
      case "+": return Vals(op + vals.op, eg + vals.eg);
      case "-": return Vals(op - vals.op, eg - vals.eg);
    }
    return this;
  }

  Vals opBinary(string oper)(int k)
  {
    final switch(oper)
    {
      case "*": return Vals(op * k, eg * k);
      case "/": return Vals(op / k, eg / k);
    }
    return this;
  }

  bool opEquals(Vals vals)
  {
    return op == vals.op && eg == vals.eg;
  }

  bool opNotEquals(Vals vals)
  {
    return op != vals.op || eg != vals.eg;
  }

  void opAssign(Vals vals)
  {
    op = vals.op;
    eg = vals.eg;
  }

  Vals opOpAssign(string oper)(Vals vals)
  {
    final switch(oper)
    {
      case "+":
        op += vals.op;
        eg += vals.eg;
        break;

      case "-":
        op -= vals.op;
        eg -= vals.eg;
        break;
    }
    return this;
  }

  Vals opOpAssign(string oper)(int k)
  {
    final switch(oper)
    {
      case "*":
        op *= k;
        eg *= k;
        break;

      case "/":
        op /= k;
        eg /= k;
        break;
    }
    return this;
  }

  string toString() const
  {
    return format!"(%d, %d)"(op, eg);
  }

  int tapered(int phase)
  {
    return ((op * (Phase.Total - phase)) + eg * phase) / Phase.Total;
  }
}

module vals;
import std.format;

enum Phase
{
  Light = 1, Rook = 2, Queen = 4, Endgame = 7,
  Total = Light * 4 + Rook * 2 + Queen
};

struct Vals
{
  int op, eg;

  static Vals both(int x)  { return Vals(x, x); }
  static Vals as_op(int x) { return Vals(x, 0); }
  static Vals as_eg(int x) { return Vals(0, x); }

  Vals opNeg()
  {
    return Vals(-op, -eg);
  }

  Vals opAdd(Vals vals)
  {
    return Vals(op + vals.op, eg + vals.eg);
  }

  Vals opSub(Vals vals)
  {
    return Vals(op - vals.op, eg - vals.eg);
  }

  Vals opMul(int k)
  {
    return Vals(op * k, eg * k);
  }

  Vals opDiv(int k)
  {
    return Vals(op / k, eg / k);
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
    this.op = vals.op;
    this.eg = vals.eg;
  }

  Vals opOpAssign(string op)(Vals vals)
  {
    final switch(op)
    {
      case "+":
        this.op += vals.op;
        this.eg += vals.eg;
        break;

      case "-":
        this.op -= vals.op;
        this.eg -= vals.eg;
        break;
    }
    return this;
  }

  Vals opOpAssign(string op)(int k) if (op == "*")
  {
    final switch(op)
    {
      case "+":
        this.op *= k;
        this.eg *= k;
        break;

      case "-":
        this.op /= k;
        this.eg /= k;
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

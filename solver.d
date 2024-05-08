module solver;
import types, timer, piece, board;
import moves, consts, engine;

class Solver
{
  this(Engine engine)
  {
    this.engine = engine;
  }
  abstract Move get_move(MS time);
  void set(const ref Board board) {}
  u64 perft(int depth) { return 0; }
  void stop() {}
  void set_analysis(bool val) {}

protected:
  Engine engine = null;
}

class Reader : Solver
{
  this(Engine engine)
  {
    super(engine);
  }
  override Move get_move(MS time) { return Move(); }
}

struct Undo // Alpha-beta-like node state
{
  State state;
  // Val pst;
  // u64 hash;
  Move curr, best;
  Move[2] killer;
}

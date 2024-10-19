module solver;
import types, timer, piece, board, utils;
import moves, movelist, consts, engine;

class Solver
{
  this(Engine engine, shared Input input)
  {
    this.engine = engine;
    this.input = input;
  }
  abstract Move get_move(MS time);
  void set(const Board board) {}
  u64 perft(int depth) { return 0; }
  void stop() { thinking = false; }
  void set_analysis(bool val) { infinite = val; }

protected:
  Engine engine = null;
  shared Input input;
  bool thinking = false;
  bool infinite = false;
}

class Reader : Solver
{
  this(Engine engine, shared Input input)
  {
    super(engine, input);
  }
  override Move get_move(MS time) { return Move(); }
}

struct Undo // Alpha-beta-like node state
{
  State state = State.init;
  MoveSeries ms;
  // Vals pst;
  Move curr, best;
}

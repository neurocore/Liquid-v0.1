module solver;
import timer, piece, board, moves, consts, engine;

class Solver
{
  this(Engine engine)
  {
    this.engine = engine;
  }
  abstract Move get_move(MS time);
  void set(const ref Board board) {}
  ulong perft(int depth) { return 0; }
  void stop() {}
  void set_analysis(bool val) {}
  bool input_available() const { return true; }

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

module solver_pvs;
import solver;
import timer, board, moves, consts, engine;

class SolverPVS : Solver
{
  this(Engine engine)
  {
    super(engine);
  }
  override Move get_move(MS time) { return Move(); }
  override void set(const ref Board board) {}
  override ulong perft(int depth) { return 0; }
  override void stop() {}
  override void set_analysis(bool val) {}
  override bool input_available() const { return true; }
}

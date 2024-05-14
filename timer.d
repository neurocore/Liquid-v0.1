module timer;
import std.datetime.stopwatch;
import types, piece, consts;

alias MS = u64;

struct Timer
{
  private StopWatch sw = StopWatch(AutoStart.no);

  void start() { sw.start(); }
  void stop()  { sw.stop(); }
  MS getms() const
  {
    //sw.stop();
    return sw.peek.total!"msecs";
  }
}

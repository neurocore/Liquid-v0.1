module timer;
import piece, consts;

alias MS = ulong;

struct TimeControl
{
  this(MS[2] time, MS[2] inc, bool infinite = false)
  {
    time_ = time;
    inc_ = inc;
    infinite_ = infinite;
  }

  MS time(Color c) const { return time_[c]; }
  MS inc(Color c) const { return inc_[c]; }
  MS full_time(Color c) const { return time_[c] + inc_[c]; }
  bool infinite() const { return infinite_; }

private:
  MS[2] time_= [Time.Default, Time.Default];
  MS[2] inc_= [0, 0];
  bool infinite_ = false;
}

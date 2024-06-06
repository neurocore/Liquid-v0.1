module options;
import std.conv, std.format, std.range;
import utils;

enum OptionType { None, Check, Spin, Combo, Button, String }

string to_str(OptionType ot)
{
  switch(ot)
  {
    case OptionType.Check:  return "check";
    case OptionType.Spin:   return "spin";
    case OptionType.Combo:  return "combo";
    case OptionType.Button: return "button";
    case OptionType.String: return "string";
    default: return "unknown";
  }
}

abstract class Option
{
  protected OptionType type_ = OptionType.None;
  string val() const;
  string def() const;
  OptionType type() const { return type_; }
  void toString(scope Sink sink, Fmt fmt) const
  {
    if (fmt.spec == 'v')
    {
      sink(format("[%s]", val()));
    }
    else
    {
      sink(format("default %s", def()));
    }
  }
  void set(string val);
}

class OptionCheck : Option
{
  private bool val_, def_;
  override string val() const { return val_.to!string; }
  override string def() const { return def_.to!string; }

  this(bool val)
  {
    type_ = OptionType.Check;
    val_ = def_ = val;
  }

  override void set(string val)
  {
    if (val.empty()) return;
    bool i = cast(bool)val.safe_to!int;
    val_ = val.safe_to!bool(i);
  }
}

class OptionSpin : Option
{
  private int val_, def_;
  private int min_, max_;
  override string val() const { return val_.to!string; }
  override string def() const { return def_.to!string; }

  this(int val, int min, int max)
  {
    type_ = OptionType.Spin;
    val_ = def_ = val;
    min_ = min;
    max_ = max;
  }

  override void toString(scope Sink sink, Fmt fmt) const
  {
    if (fmt.spec == 'v')
    {
      sink(format("[%s | %s - %s]", val_, min_, max_));
    }
    else
    {
      sink(format("default %s min %s max %s", def_, min_, max_));
    }
  }

  override void set(string val)
  {
    if (val.empty()) return;
    val_ = val.safe_to!int;
    if (val_ < min_) val_ = min_;
    if (val_ > max_) val_ = max_;
  }
}

class OptionCombo : Option
{
  private int val_, def_;
  private string[] strings_;

  this(int val, string[] strings)
  {
    type_ = OptionType.Combo;
    val_ = def_ = val;
    strings_ = strings;
  }

  override string val() const { return strings_[val_]; }
  override string def() const { return strings_[def_]; }

  override void toString(scope Sink sink, Fmt fmt) const
  {
    import std.array;

    if (fmt.spec == 'v')
    {
      sink(format("[%s | %s]", val_, strings_.join(", ")));
    }
    else
    {
      sink(format("default %s var %s", def_, strings_.join(" var ")));
    }
  }

  override void set(string val)
  {
    import std.algorithm;
    if (strings_.canFind(val))
      val_ = cast(int)strings_.countUntil(val);
  }
}

class OptionButton : Option
{
  private string text_;
  override string val() const { return text_.to!string; }
  override string def() const { return text_.to!string; }

  this(string text)
  {
    type_ = OptionType.Button;
    text_ = text;
  }

  override void set(string val)
  {
    // Unable by design
  }
}

class OptionString : Option
{
  private string val_, def_;
  override string val() const { return val_.to!string; }
  override string def() const { return def_.to!string; }

  this(string val)
  {
    type_ = OptionType.String;
    val_ = def_ = val;
  }

  override void set(string val)
  {
    val_ = val;
  }
}

class Options
{
  bool flag_debug = true;
  private Option[string] options;
  private string[] order;

  this()
  {
    add("Hash", new OptionSpin(4, 1, 1024));
    add("NullMove", new OptionCheck(false));
    add("OwnBook", new OptionCheck(false));
    add("UCI_ShowCurrLine", new OptionCheck(true));
    add("TestButton", new OptionButton("I am a button!"));
    add("TestString", new OptionString("I am a string!"));
    add("TestCombo", new OptionCombo(0, ["A", "B", "C"]));
  }

  void add(string name, Option opt)
  {
    options[name] = opt;
    order ~= name;
  }

  void set(string name, string val)
  {
    if (!(name in options)) return;
    options[name].set(val);
  }

  void toString(scope Sink sink, Fmt fmt) const
  {
    string f = fmt.spec == 'v'
             ? "%s (%s) - %v"
             : "option name %s type %s %s";

    foreach (string name; order)
    {
      auto opt = options[name];
      sink(format(f ~ "\n", name, opt.type.to_str, opt));
    }
  }
}

module options;
import std.conv;
import std.variant;
import std.format;
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
  OptionType type() const { return type_; }
  void toString(scope Sink sink, Fmt fmt) const
  {
    string f = fmt.spec == 'v' ? "[%s]" : "default %s";
    sink(format(f, val()));
  }
}

class OptionCheck : Option
{
  private bool val_, def_;
  override string val() const { return val_.to!string; }

  this(bool val)
  {
    type_ = OptionType.Check;
    val_ = def_ = val;
  }
}

class OptionSpin : Option
{
  private int val_, def_;
  private int min_, max_;
  override string val() const { return val_.to!string; }

  this(int val, int min, int max)
  {
    type_ = OptionType.Spin;
    val_ = def_ = val;
    min_ = min;
    max_ = max;
  }

  override void toString(scope Sink sink, Fmt fmt) const
  {
    string f = fmt.spec == 'v'
             ? "[%s | %s - %s]"
             : "default %s min %s max %s";

    sink(format(f, val_, min_, max_));
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

  override string val() const
  {
    return strings_[val_];
  }

  override void toString(scope Sink sink, Fmt fmt) const
  {
    import std.array;

    if (fmt.spec == 'v')
    {
      sink(format("[%s | %s]", val_, strings_.join(", ")));
    }
    else
    {
      sink(format("default %s var %s", val(), strings_.join(" var ")));
    }
  }
}

class OptionButton : Option
{
  private string text_;
  override string val() const { return text_.to!string; }

  this(string text)
  {
    type_ = OptionType.Button;
    text_ = text;
  }

  override void toString(scope Sink sink, Fmt fmt) const
  {
    string f = fmt.spec == 'v' ? "[%s]" : "default %s";
    sink(format(f, text_));
  }
}

class OptionString : Option
{
  private string val_, def_;
  override string val() const { return val_.to!string; }

  this(string val)
  {
    type_ = OptionType.String;
    val_ = def_ = val;
  }
}

class Options
{
  bool flag_debug;
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

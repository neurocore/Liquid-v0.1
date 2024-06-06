module utils;
import std.stdio, std.format, std.conv;
import std.traits, std.typecons, std.regex;
import std.array, std.string, std.algorithm;

alias Sink = void delegate(const(char)[]);
alias Fmt = FormatSpec!char;

template GenAliases(T)
{
  import std.format, std.traits;

  string GenAliases()
  {
    string str;
    foreach (T member; EnumMembers!T)
    {
      string name = format("%s", member);
      if (name == "size") break;
      str ~= "alias " ~ name ~ " = " ~ T.stringof ~ "." ~ name ~ ";\n";
    }
    return str;
  }
}

void equal(T)(string name, T lhc, T rhc, string file = __FILE__, size_t line = __LINE__)
{
  string num = is(T == u64) ? "0x%016X" : "%d";

  if (lhc != rhc)
  {
    writefln("Equality failed: " ~ num ~ " == " ~ num, lhc, rhc);
    writeln("Name: ", name);
    writeln("File: ", file, " - line ", __LINE__, "\n");
    assert(false);
  }
}

// Template function to parse string based on scheme
template parse_san(string scheme)
{
  alias Data = int[];
  alias Handler = int function(char) pure nothrow @nogc @safe;

  private struct Wildcard
  {
    string rx;
    bool capture;
    Handler handler;
  }

  //  scheme | string recognized
  // --------+------------------------------------
  //  Naxa1  | Qcxe3+, Ngf3 (file disambiguation)
  //  axa=N  | ef=Q
  //  a1=N   | c8=R

  Data parse_san(string str)
  {
    const Wildcard[char] wildcards =
    [
      'N': Wildcard("([NBRQK])",  true, (char ch) => cast(int)(indexOf(" NBRQK", ch))),
      'Q': Wildcard("([NBRQK]?)", true, (char ch) => cast(int)(indexOf(" NBRQK", ch))),
      
      'a': Wildcard("([a-h])",  true, (char ch) => cast(int)(ch - 'a')),
      '1': Wildcard("([1-8])",  true, (char ch) => cast(int)(ch - '1')),
      'z': Wildcard("([a-h]?)", true, (char ch) => ch == ' ' ? -1 : cast(int)(ch - 'a')),
      '0': Wildcard("([1-8]?)", true, (char ch) => ch == ' ' ? -1 : cast(int)(ch - '1')),

      'O': Wildcard("[Oo0]", false, (char ch) => ch),
      'x': Wildcard("[x:]?", false, (char ch) => ch),
      '=': Wildcard("=?",    false, (char ch) => ch),
    ];

    // Converting to real regex

    Data data;
    string pattern = "^";
    Handler[] handlers;

    foreach (i; 0 .. scheme.length)
    {
      char ch = scheme[i];
      if (ch in wildcards)
      {
        pattern ~= wildcards[ch].rx;
        if (wildcards[ch].capture)
          handlers ~= wildcards[ch].handler;
      }
      else pattern ~= ch;
    }
    pattern ~= "[+#]?[!?]*$"; // ignore check/mate and marks
    auto rx = regex(pattern);

    // Parsing data from string

    auto the_match = match(str, rx);
    if (!the_match) return data;

    //debug writeln("scheme = ", scheme);
    //debug writeln("regex = ", rx);

    auto captures = the_match.captures;
    captures.popFront();

    foreach (m; captures)
    {
      Handler handler = handlers.front();
      handlers.popFront();

      data ~= handler(m.length > 0 ? m[0] : ' ');
    }
    return data;
  }
}

void todo(string text, string file = __FILE__, size_t line = __LINE__)
{
  //debug writefln("TODO: %s:%d - %s\n", file, line, text);
}

void error(string text)
{
  stderr.writeln("error: ", text, "\n");
}

bool input_available()
{
  return stdin.readln().length > 0;

  //char[1] buf;
  //return stdin.tryPeek!(char[1])(buf) != 0;
}

string highlight(string[] parts, int num)
{
  parts[num] = "[" ~ parts[num] ~ "]";
  return parts.join(" ");
}

T safe_to(T)(string s, T def = T.init)
{
  try
  {
    T value = s.to!T;
    return value;
  }
  catch (ConvException e)
  {
    return def;
  }
}

bool try_parse(T)(string s, out T value)
{
  try
  {
    value = s.to!T;
    return true;
  }
  catch (ConvException e)
  {
    return false;
  }
}

void zeros(T)(ref T obj)
{
  obj.each!"a = 0"; // no alloc
}

R compare(T, R)(T a, T b, R less, R equal, R more)
{
  return (a < b ? less : (a > b ? more : equal));
}

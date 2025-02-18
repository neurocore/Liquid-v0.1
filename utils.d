module utils;
import std.stdio, std.format, std.conv;
import std.traits, std.typecons, std.regex;
import std.array, std.string, std.algorithm;
import std.concurrency, core.thread;
import std.math: sqrt;
import app;

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

      // alias name = type.name;
      str ~= "alias " ~ name ~ " = " ~ T.stringof ~ "." ~ name ~ ";\n";
    }
    return str;
  }
}

template GenStrings(T)
{
  import std.format, std.traits, std.ascii;

  string GenStrings()
  {
    const string type = T.stringof;
    const string arr = type[0].toLower ~ type[1..$] ~ "_str";

    // string[] terms = [...];
    string str = "string[] " ~ arr ~ "= [";

    foreach (T member; EnumMembers!T)
    {
      string name = format("%s", member);
      if (name == "size") break;
      str ~= "\"" ~ name ~ "\", ";
    }
    return str ~ "];\n";
  }
}

void equal(T)(string name, T lhc, T rhc, string file = __FILE__, size_t line = __LINE__)
{
  string num = is(T == u64) ? "0x%016X" : "%d";

  if (lhc != rhc)
  {
    sayf("Equality failed: " ~ num ~ " == " ~ num, lhc, rhc);
    say("Name: ", name);
    say("File: ", file, " - line ", __LINE__, "\n");
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

    //log("scheme = ", scheme);
    //log("regex = ", rx);

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


// Template function to parse expr for bitboard building
// Syntax is simple: BN, WQ and so on are piece bitboards
//            occ, white, black are respective occupancies
// Other instructions are just passed through as is
//
// Example expression: (WN | WP) ^ occ
// Result: (piece[WN] | piece[WP]) ^ (occ[0] | occ[1])

template GenBitboardsExpr(string expr)
{
  import std.array, std.ascii;

  string exchange(string str)
  {
    const string[] pieces =
    [
      "BP", "BN", "BB", "BR", "BQ", "BK",
      "WP", "WN", "WB", "WR", "WQ", "WK",
    ];

    foreach (p; pieces)
    {
      str = str.replace(p, "piece[" ~ p ~ "]");
    }

    str = str.replace("Ps", "(piece[BP] | piece[WP])");
    str = str.replace("Ns", "(piece[BN] | piece[WN])");
    str = str.replace("Bs", "(piece[BB] | piece[WB])");
    str = str.replace("Rs", "(piece[BR] | piece[WR])");
    str = str.replace("Qs", "(piece[BQ] | piece[WQ])");
    str = str.replace("Ks", "(piece[BK] | piece[WK])");

    str = str.replace("Ls", "(piece[BB] | piece[WB] | piece[BN] | piece[WN])");
    
    str = str.replace("WL", "(piece[WN] | piece[WB])");
    str = str.replace("BL", "(piece[BN] | piece[BB])");

    str = str.replace("occ", "(occ[0] | occ[1])");
    str = str.replace("black", "occ[0]");
    str = str.replace("white", "occ[1]");

    return str;
  }

  string GenBitboardsExpr()
  {
    return exchange(expr);
  }
}

void todo(string text, string file = __FILE__, size_t line = __LINE__)
{
  //logf("TODO: %s:%d - %s\n", file, line, text);
}

bool error(string text)
{
  err("error: ", text, "\n");
  return false;
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

int sqrt(int x) { return cast(int)sqrt(cast(float)x); }


void async_input(shared Input i) { i.loop(); }

final shared class Input // rwqueue
{
  class Lock {}
  private Lock lock;
  private int size;
  private string[] queue;
  private size_t head, tail;
  private bool working = true;

  this(int size)
  {
    this.size = size;
    head = tail = 0;
    queue.length = size;
    lock = new shared Lock;
  }

  bool empty() const { return head == tail; }
  bool is_working() const { return working; }

  void loop()
  {
    string str;
    do
    {
      str = readln().chomp();
      push(str);
    }
    while (str != "quit");

    working = false;
  }

  void push(string str)
  {
    synchronized(lock)
    {
      queue[tail] = str;
      tail = (tail + 1) % size;
    }
  }

  string pop()
  {
    synchronized(lock)
    {
      string str;
      if (!empty)
      {
        str = queue[head];
        queue[head] = null;
        head = (head + 1) % size;
      }
      return str;
    }
  }
}

module utils;
import std.stdio, std.format;
import std.conv, std.traits;

alias Sink = void delegate(const(char)[]);
alias Fmt = FormatSpec!char;

template EnumAlias(alias EnumType)
{
  static foreach (member; EnumMembers!EnumType)
  {
    alias member = EnumType.member;
  }
}

void equal(T)(string name, T lhc, T rhc, string file = __FILE__, size_t line = __LINE__)
{
  string num = is(T == ulong) ? "0x%016X" : "%d";

  if (lhc != rhc)
  {
    writefln("Equality failed: " ~ num ~ " == " ~ num, lhc, rhc);
    writeln("Name: ", name);
    writeln("File: ", file, " - line ", __LINE__, "\n");
    assert(false);
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

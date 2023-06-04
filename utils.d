module utils;
import std.stdio, std.format;

alias Sink = void delegate(const(char)[]);
alias Fmt = FormatSpec!char;

void equal(ulong lhc, ulong rhc)
{
  import std.stdio;
  if (lhc == rhc) return;
  
  writefln("Equality failed: 0x%016X == 0x%016X", lhc, rhc);
  writeln("File: ", __FILE__, " Line: ", __LINE__);
  assert(lhc == rhc);
}

void todo(string text)
{
  version(Debug)
    writefln("TODO: %s:%d - %s\n", __FILE__, __LINE__, text);
}

void error(string text)
{
  stderr.writeln("error: ", text, "\n");
}

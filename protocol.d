module protocol;
import std.stdio;
import std.file;
import std.conv;
import engine;

abstract class Protocol
{
public:
  static Protocol * detect();
  void greet();
  bool parse(Engine E);
}

class UCI : Protocol
{
private:
  File log;

public:
  this()
  {
    log = File("log.txt", "w");
  }

  ~this()
  {
    log.close();
  }

  override void greet()
  {
    writeln("Hello from UCI!");
  }

  override bool parse(Engine E)
  {
    writeln("Parsing UCI protocol...");
    return true;
  }
}

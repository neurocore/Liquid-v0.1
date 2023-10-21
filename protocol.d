module protocol;
import std.stdio, std.format, std.array;
import std.file, std.conv;
import consts, command, options;

abstract class Protocol
{
public:
  static Protocol * detect();
  void greet();
  Cmd parse(string line, Options options);
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

  override Cmd parse(string line, Options options)
  {
    string[] parts = line.split(" ");
    if (parts.length <= 0) return new Cmd_Unknown(line);

    const string cmd = parts[0];

    if (cmd == "uci")
    {
      string str = format
      (
        "id name %s v%s\n" ~ "id %s\n" ~ "%s" ~ "uciok",
        Name, Vers, Auth, options
      );
      return new Cmd_Response(str);
    }
    else if (cmd == "quit" || cmd == "exit") return new Cmd_Quit;
    else if (cmd == "isready") return new Cmd_Response("readyok");
    else if (cmd == "setoptions") return new Cmd_Response("readyok");

    return new Cmd_Unknown(line);
  }
}

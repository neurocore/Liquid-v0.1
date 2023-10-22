module protocol;
import std.stdio, std.format, std.array;
import std.file, std.conv;
import consts, utils, moves;
import command, options;
import std.algorithm;

abstract class Protocol
{
public:
  static Protocol * detect();
  void greet();
  Cmd parse(string line, Options options);
}

class WordsReader
{
  this(string[] words)
  {
    this.words = words;
  }

  string get_word()
  {
    if (pos >= words.length) return "";
    return words[pos++];
  }

  string get_phrase(string[] stop_tokens = string[].init)
  {
    string[] phrase;
    for (int i = pos; i < words.length; i++)
    {
      string word = words[i];
      if (stop_tokens.canFind(word)) break;
      phrase ~= word;
    }
    pos += phrase.length;
    return phrase.join(" ");
  }

private:
  int pos = 0;
  string[] words;
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
    if (parts.length <= 0) return new Cmd_Bad(line, Bad.Empty);

    auto reader = new WordsReader(parts);
    const string cmd = reader.get_word();

    if (cmd == "uci")
    {
      string str = format
      (
        "id name %s v%s\n" ~ "id author %s\n" ~ "%s" ~ "uciok",
        Name, Vers, Auth, options
      );
      return new Cmd_Response(str);
    }
    else if (cmd == "quit") return new Cmd_Quit;
    else if (cmd == "isready") return new Cmd_Response("readyok");
    else if (cmd == "ucinewgame") return new Cmd_NewGame;
    else if (cmd == "stop") return new Cmd_Stop;
    else if (cmd == "debug")
    {
      if (parts.length < 2) return new Cmd_Bad(line ~ " ~~~", Bad.Incomplete);
      
      string op = reader.get_word();
      if (op == "on") return new Cmd_Debug(true);
      else if (op == "off") return new Cmd_Debug(false);
      return new Cmd_Bad(highlight(parts, 1), Bad.Invalid);
    }
    else if (cmd == "setoption")
    {
      if (parts.length < 3) return new Cmd_Bad(parts[0] ~ " [name <string>]", Bad.Incomplete);

      string op1 = reader.get_word();
      if (op1 != "name") return new Cmd_Bad(highlight(parts, 1), Bad.Invalid);
      string name = reader.get_phrase(["value"]);

      string op2 = reader.get_word();
      string val = op2 == "value" ? reader.get_phrase() : "";

      return new Cmd_Option(name, val);
    }
    else if (cmd == "position")
    {
      if (parts.length < 3) return new Cmd_Bad(parts[0] ~ " [fen <string> | moves <string>]", Bad.Incomplete);
      
      string fen, moves;
      string op = reader.get_word();

      if (op == "startpos")
      {
        fen = Pos.Init;
      }
      else if (op == "fen")
      {
        fen = reader.get_phrase(["moves"]);
        op = reader.get_word();
      }

      if (op == "moves")
      {
        moves = reader.get_phrase();
      }

      Move[] the_moves = moves.split(" ").map!(x => Move(x)).array;
      return new Cmd_Pos(fen, the_moves);
    }

    return new Cmd_Bad(highlight(parts, 0));
  }
}

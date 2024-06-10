module epd;
import std.stdio, std.array, std.string;
import std.ascii, std.file;
import app, moves, board, utils;

class EPD
{
  struct Problem
  {
    bool valid = false;
    Board board;
    string fen, id;
    string[10] comment;
    Move[] best, avoid;

    int fifty = 0;
    int depth = 0;
    int nodes = 0;
    int secs = 0;
    int eval = 0;

    this(string str)
    {
      string[] parts = str.split(' ');
      if (parts.length < 4) return;

      board = new Board;
      fen = parts[0..4].join(' ');
      if (!board.set(fen)) return;

      string ops_line = parts[4..$].join(' ');
      foreach (ops; ops_line.strip(";").split(';'))
      {
        string[] op = ops.strip.split(' ');
        if (op.length < 2) break;

        int val = 0;
        const string cmd = op[0];
        const string rest = op[1..$].join(' ').strip("\"");
        try_parse(rest, val);

        switch(cmd)
        {
          case "bm":
          {
            foreach (mv; op[1..$])
            {
              Move move = board.san(mv);
              if (move != Move.None)
                best ~= move;
            }
            break;
          }

          case "am":
          {
            foreach (mv; op[1..$])
            {
              Move move = board.san(mv);
              if (move != Move.None)
                avoid ~= move;
            }
            break;
          }

          case "id"  : id = rest;   break;
          case "acd" : depth = val; break;
          case "acn" : nodes = val; break;
          case "acs" : secs = val;  break;
          case "ce"  : eval = val;  break;
          case "hmvc": fifty = val; break;

          default:
          {
            if (cmd.length == 2 && cmd[0] == 'c' && cmd[1].isDigit)
            {
              const int i = cmd[1] - '0';
              comment[i] = rest;
            }
          }
        }
      }
      valid = true;
    }
  }

  this(string file)
  {
    auto f = File(file, "r");
    if (!file.exists)
    {
      err("file not found");
      return;
    }

    while (!f.eof)
    {
      string str = f.readln();
      Problem problem = Problem(str);
      if (problem.valid)
        problems ~= problem;
    }
  }

  const(Problem[]) list() const { return problems; }

private:
  Problem[] problems;
}

module consts;

const string Name = "Liquid";
const string Vers = "0.1";
const string Auth = "Nick Kurgin";

struct Time
{
  enum Default = 60000;
}

struct Limits
{
  enum Moves = 256;
  enum Plies = 128;
}

struct Val
{
  enum Draw  = 0;
  enum Inf   = 32767;
  enum Mate  = 32000;
}

struct Pos
{
  //enum Init = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
  enum Init = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
}

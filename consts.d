module consts;

enum Engine
{
  Name = "Liquid",
  Vers = "0.1",
  Auth = "Nick Kurgin",
}

enum TimeDefault = 60000;

enum Limits
{
  Moves = 256,
  Plies = 128,
}

enum Val : int
{
  Draw  = 0,
  Inf   = 32767,
  Mate  = 32000,
}

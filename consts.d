module consts;

const string Name = "Liquid";
const string Vers = "0.1";
const string Auth = "Nick Kurgin";

struct Time
{
  enum Def = 60000;
  enum Inc =  1000;
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

struct HashTables
{
  enum Size = 4;
}

struct Pos
{
  //enum Init = "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1";
  //enum Init = "r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10";
  enum Init = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";
  enum Fine = "8/k7/3p4/p2P1p2/P2P1P2/8/8/K7 w - -";
}

struct Tune
{
  enum Def = "MatKnight:320 "
           ~ "MatBishop:330 "
           ~ "MatRook:500 "
           ~ "MatQueen:900 "
           ~ "PawnFile:5 "
           ~ "KnightCenterOp:5 "
           ~ "KnightCenterEg:5 "
           ~ "KnightRank:5 "
           ~ "KnightBackRank:0 "
           ~ "KnightTrapped:100 "
           ~ "BishopCenterOp:2 "
           ~ "BishopCenterEg:3 "
           ~ "BishopBackRank:10 "
           ~ "BishopDiagonal:4 "
           ~ "RookFileOp:3 "
           ~ "QueenCenterOp:0 "
           ~ "QueenCenterEg:4 "
           ~ "QueenBackRank:5 "
           ~ "KingFile:10 "
           ~ "KingRank:10 "
           ~ "KingCenterEg:22 "
           ~ "Doubled:14 "
           ~ "Isolated:10 "
           ~ "Hole:10 "
           ~ "NMob:64 "
           ~ "BMob:64 "
           ~ "RMob:48 "
           ~ "QMob:4 "
           ~ "BishopPair:13 "
           ~ "BadBishop:38 "
           ~ "KnightOutpost:10 "
           ~ "RookSemi:10 "
           ~ "RookOpen:20 "
           ~ "Rook7thOp:20 "
           ~ "Rook7thEg:12 "
           ~ "BadRook:20 "
           ~ "KnightFork:20 "
           ~ "BishopFork:13 "
           ~ "HolePress:8 "
           ~ "ContactCheckR:100 "
           ~ "ContactCheckQ:180 "
           ~ "Shield1:10 "
           ~ "Shield2:3 "
           ~ "Shield3:15 "
           ~ "Candidate:100 "
           ~ "CandidateK:32 "
           ~ "Passer:200 "
           ~ "PasserK:32 "
           ~ "PasserSupport:300 "
           ~ "PasserSupportK:32 "
           ~ "PinMul:5 "
           ~ "XrayMul:3 "
           ~ "Tempo:15 ";
}

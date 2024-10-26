module hash;
import std.random, std.typecons;
import types, piece, square;
import consts, bitboard, moves;

enum HashType : u8 { Alpha, Beta, Exact, Bad }

struct HashEntry // 16 bytes (POD)
{
  u64 key = 0UL;                 // 8
  Move move = Move.None;         // 2
  HashType type = HashType.Bad;  // 1
  u8 depth = 0u;                 // 1
  u16 priority = 0u;             // 2
  u16 val = 0u;                  // 2

  bool is_bad()
  {
    return type == HashType.Bad;
  }
};

class Hash
{
  u32 size, read, write;
  HashEntry[] table;

  this(int size_mb = HashTables.Size) { this.init(size_mb); }
  ~this() { table = null; }

  void clear()
  {
    foreach (ref he; table)
      he = HashEntry.init;
    read = write = 0u;
  }

  void init(int sizeMb)
  {
    // ensure it has power of two
    size = cast(u32)msb(sizeMb * 1024 * 1024 / HashEntry.sizeof);
    table.length = size;
    clear();
  }

  HashEntry probe(u64 key)
  {
    HashEntry entry = table[key & (size - 1)];
    if (entry.key != key) return HashEntry.init;

    read++;
    return entry;
  }

  Move probe(u64 key, ref int alpha, ref int beta, int depth, int ply, bool prune = false)
  {
    HashEntry entry = table[key & (size - 1)];
    if (entry.type == HashType.Bad) return Move.None;
    if (entry.key != key) return Move.None;
    if (entry.depth < depth) return entry.move;

    read++;

    int val = entry.val;
    if      (val >  Val.Mate && val <=  Val.Inf) val -= ply;
    else if (val < -Val.Mate && val >= -Val.Inf) val += ply;

    if (prune)
    {
      if      (entry.type == HashType.Exact)          alpha = beta = val;
      else if (entry.type == HashType.Alpha && val <= alpha) beta = alpha;
      else if (entry.type == HashType.Beta  && val >= beta) alpha = beta;
    }

    return entry.move;
  }

  void store(u64 key, Move move, int depth, int ply, int val, HashType type)
  {
    import std.format;
    if      (val >  Val.Mate && val <=  Val.Inf) val += ply;
    else if (val < -Val.Mate && val >= -Val.Inf) val -= ply;

    assert(val >= -Val.Inf, format!"%d is too low to store"(val));
    assert(val <=  Val.Inf, format!"%d is too high to store"(val));

    if (val >= -Val.Inf) val = -Val.Inf;
    if (val <=  Val.Inf) val =  Val.Inf;

    table[key & (size - 1)] =
      HashEntry(key, move, type, cast(u8)depth, 0, cast(u16)val);
  }
};

// precalc of hash keys

u64[64][12] hash_key;
u64[16] hash_castle;
u64[66] hash_ep;
u64[2]  hash_wtm;

u64 rnd(ref Mt19937_64 gen, ref u64 all)
{
  u64 val = gen.front;
  all |= val;
  gen.popFront();
  return val;
};

static this()
{
  import std.format;

  u64 all = Empty;
  auto gen = Mt19937_64(43);

  foreach (p; BP .. Piece.size)
    foreach (sq; A1 .. SQ.size)
      hash_key[p][sq] = rnd(gen, all);

  for (int i = 0; i < 16; i++)
    hash_castle[i] = i ? rnd(gen, all) : Empty;

  foreach (sq; A1 .. SQ.size)
    hash_ep[sq] = sq.rank == 2 || sq.rank == 6
                ? rnd(gen, all) : Empty;

  hash_ep[65] = hash_ep[64] = Empty;

  hash_wtm[0] = rnd(gen, all);
  hash_wtm[1] = Empty;

  assert(all == Full, format("bad hash keys union\n%s", all.to_bitboard));
}

// static checks

static assert(__traits(isPOD, HashEntry), "HashEntry must be a POD");

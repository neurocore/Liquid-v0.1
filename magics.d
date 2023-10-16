module magics;
import square;
import bitboard;

// Black Magics were discovered by Volker Annuss

private enum { Rook, Bishop };

private struct Helper
{
  uint offset;
  ulong magic;
}

private immutable Helper[64][2] helpers =
[
  [
    Helper( 10890, 0x80280013ff84ffff ),
    Helper( 56054, 0x5ffbfefdfef67fff ),
    Helper( 67495, 0xffeffaffeffdffff ),
    Helper( 72797, 0x003000900300008a ),
    Helper( 17179, 0x0030018003500030 ),
    Helper( 63978, 0x0020012120a00020 ),
    Helper( 56650, 0x0030006000c00030 ),
    Helper( 15929, 0xffa8008dff09fff8 ),
    Helper( 55905, 0x7fbff7fbfbeafffc ),
    Helper( 26301, 0x0000140081050002 ),
    Helper( 78100, 0x0000180043800048 ),
    Helper( 86245, 0x7fffe800021fffb8 ),
    Helper( 75228, 0xffffcffe7fcfffaf ),
    Helper( 31661, 0x00001800c0180060 ),
    Helper( 38053, 0xffffe7ff8fbfffe8 ),
    Helper( 37433, 0x0000180030620018 ),
    Helper( 74747, 0x00300018010c0003 ),
    Helper( 53847, 0x0003000c0085ffff ),
    Helper( 70952, 0xfffdfff7fbfefff7 ),
    Helper( 49447, 0x7fc1ffdffc001fff ),
    Helper( 62629, 0xfffeffdffdffdfff ),
    Helper( 58996, 0x7c108007befff81f ),
    Helper( 36009, 0x20408007bfe00810 ),
    Helper( 21230, 0x0400800558604100 ),
    Helper( 51882, 0x0040200010080008 ),
    Helper( 11841, 0x0010020008040004 ),
    Helper( 25794, 0xfffdfefff7fbfff7 ),
    Helper( 49689, 0xfebf7dfff8fefff9 ),
    Helper( 63400, 0xc00000ffe001ffe0 ),
    Helper( 33958, 0x2008208007004007 ),
    Helper( 21991, 0xbffbfafffb683f7f ),
    Helper( 45618, 0x0807f67ffa102040 ),
    Helper( 70134, 0x200008e800300030 ),
    Helper( 75944, 0x0000008780180018 ),
    Helper( 68392, 0x0000010300180018 ),
    Helper( 66472, 0x4000008180180018 ),
    Helper( 23236, 0x008080310005fffa ),
    Helper( 19067, 0x4000188100060006 ),
    Helper(     0, 0xffffff7fffbfbfff ),
    Helper( 43566, 0x0000802000200040 ),
    Helper( 29810, 0x20000202ec002800 ),
    Helper( 65558, 0xfffff9ff7cfff3ff ),
    Helper( 77684, 0x000000404b801800 ),
    Helper( 73350, 0x2000002fe03fd000 ),
    Helper( 61765, 0xffffff6ffe7fcffd ),
    Helper( 49282, 0xbff7efffbfc00fff ),
    Helper( 78840, 0x000000100800a804 ),
    Helper( 82904, 0xfffbffefa7ffa7fe ),
    Helper( 24594, 0x0000052800140028 ),
    Helper(  9513, 0x00000085008a0014 ),
    Helper( 29012, 0x8000002b00408028 ),
    Helper( 27684, 0x4000002040790028 ),
    Helper( 27901, 0x7800002010288028 ),
    Helper( 61477, 0x0000001800e08018 ),
    Helper( 25719, 0x1890000810580050 ),
    Helper( 50020, 0x2003d80000500028 ),
    Helper( 41547, 0xfffff37eefefdfbe ),
    Helper(  4750, 0x40000280090013c1 ),
    Helper(  6014, 0xbf7ffeffbffaf71f ),
    Helper( 41529, 0xfffdffff777b7d6e ),
    Helper( 84192, 0xeeffffeff0080bfe ),
    Helper( 33433, 0xafe0000fff780402 ),
    Helper(  8555, 0xee73fffbffbb77fe ),
    Helper(  1009, 0x0002000308482882 ),
  ],
  [
    Helper( 66157, 0x107ac08050500bff ),
    Helper( 71730, 0x7fffdfdfd823fffd ),
    Helper( 37781, 0x0400c00fe8000200 ),
    Helper( 21015, 0x103f802004000000 ),
    Helper( 47590, 0xc03fe00100000000 ),
    Helper(   835, 0x24c00bffff400000 ),
    Helper( 23592, 0x0808101f40007f04 ),
    Helper( 30599, 0x100808201ec00080 ),
    Helper( 68776, 0xffa2feffbfefb7ff ),
    Helper( 19959, 0x083e3ee040080801 ),
    Helper( 21783, 0x040180bff7e80080 ),
    Helper( 64836, 0x0440007fe0031000 ),
    Helper( 23417, 0x2010007ffc000000 ),
    Helper( 66724, 0x1079ffe000ff8000 ),
    Helper( 74542, 0x7f83ffdfc03fff80 ),
    Helper( 67266, 0x080614080fa00040 ),
    Helper( 26575, 0x7ffe7fff817fcff9 ),
    Helper( 67543, 0x7ffebfffa01027fd ),
    Helper( 24409, 0x20018000c00f3c01 ),
    Helper( 30779, 0x407e0001000ffb8a ),
    Helper( 17384, 0x201fe000fff80010 ),
    Helper( 18778, 0xffdfefffde39ffef ),
    Helper( 65109, 0x7ffff800203fbfff ),
    Helper( 20184, 0x7ff7fbfff8203fff ),
    Helper( 38240, 0x000000fe04004070 ),
    Helper( 16459, 0x7fff7f9fffc0eff9 ),
    Helper( 17432, 0x7ffeff7f7f01f7fd ),
    Helper( 81040, 0x3f6efbbf9efbffff ),
    Helper( 84946, 0x0410008f01003ffd ),
    Helper( 18276, 0x20002038001c8010 ),
    Helper(  8512, 0x087ff038000fc001 ),
    Helper( 78544, 0x00080c0c00083007 ),
    Helper( 19974, 0x00000080fc82c040 ),
    Helper( 23850, 0x000000407e416020 ),
    Helper( 11056, 0x00600203f8008020 ),
    Helper( 68019, 0xd003fefe04404080 ),
    Helper( 85965, 0x100020801800304a ),
    Helper( 80524, 0x7fbffe700bffe800 ),
    Helper( 38221, 0x107ff00fe4000f90 ),
    Helper( 64647, 0x7f8fffcff1d007f8 ),
    Helper( 61320, 0x0000004100f88080 ),
    Helper( 67281, 0x00000020807c4040 ),
    Helper( 79076, 0x00000041018700c0 ),
    Helper( 17115, 0x0010000080fc4080 ),
    Helper( 50718, 0x1000003c80180030 ),
    Helper( 24659, 0x2006001cf00c0018 ),
    Helper( 38291, 0xffffffbfeff80fdc ),
    Helper( 30605, 0x000000101003f812 ),
    Helper( 37759, 0x0800001f40808200 ),
    Helper(  4639, 0x084000101f3fd208 ),
    Helper( 21759, 0x080000000f808081 ),
    Helper( 67799, 0x0004000008003f80 ),
    Helper( 22841, 0x08000001001fe040 ),
    Helper( 66689, 0x085f7d8000200a00 ),
    Helper( 62548, 0xfffffeffbfeff81d ),
    Helper( 66597, 0xffbfffefefdff70f ),
    Helper( 86749, 0x100000101ec10082 ),
    Helper( 69558, 0x7fbaffffefe0c02f ),
    Helper( 61589, 0x7f83fffffff07f7f ),
    Helper( 62533, 0xfff1fffffff7ffc1 ),
    Helper( 64387, 0x0878040000ffe01f ),
    Helper( 26581, 0x005d00000120200a ),
    Helper( 76355, 0x0840800080200fda ),
    Helper( 11140, 0x100000c05f582008 ),
  ]
];

private static class Magics
{
private:
  struct Entry
  {
    ulong * ptr;
    ulong notmask;
    ulong blackmagic;
  }

  static ulong[88507] attacks;
  static Entry[64][2] entries;

  static immutable Dir[4][2] dirs =
  [
    [Dir.U,  Dir.D,  Dir.L,  Dir.R], // Rook
    [Dir.DL, Dir.DR, Dir.UL, Dir.UR] // Bishop
  ];

  static ulong index_to_u64(int index, int bits, ulong mask)
  {
    ulong result = ~mask;
    for (int i = 0; i < bits; i++)
    {
      int j = bitscan(mask);
      if (index & (Bit << i)) result |= Bit << j;
      mask = rlsb(mask);
    }
    return result;
  }

  static ulong get_mask(bool bishop)(SQ sq)
  {
    ulong result = Empty;
    foreach (Dir dir; dirs[cast(int)bishop])
    {
      ulong pre = Empty;
      ulong bit = Bit << sq;

      while (true)
      {
        bit = shift(bit, dir);
        if (!bit) break;

        result |= pre;
        pre = bit;
      }
    }
    return result;
  }

  static ulong get_att(bool bishop)(SQ sq, ulong blocks)
  {
    ulong result = Empty;
    foreach (Dir dir; dirs[cast(int)bishop])
    {
      ulong bit = Bit << sq;
      while (true)
      {
        bit = shift(bit, dir);
        result |= bit;
        if (!bit || bit & blocks) break;
      }
    }
    return result;
  }

  static int transform(ulong blocks, ulong magic, int bits)
  {
    return cast(int) ((blocks * magic) >> (64 - bits));
  }

  static void build_magics()
  {
    foreach (sq; SQ.A1 .. SQ.size) // Rooks
    {
      ulong mask = get_mask!Rook(sq);
      ulong magic = entries[Rook][sq].blackmagic;
      int bits = popcnt(mask);

      for (int i = 0; i < (1 << bits); i++)
      {
        ulong blocks = index_to_u64(i, bits, mask);
        int offset = transform(blocks, magic, 12);
        ulong * ptr  = entries[Rook][sq].ptr;

        ptr[offset] = get_att!Rook(sq, blocks);
      }

      entries[Rook][sq].notmask = ~mask;
      entries[Rook][sq].blackmagic = magic;
    }

    foreach (sq; SQ.A1 .. SQ.size) // Bishops
    {
      ulong mask = get_mask!Bishop(sq);
      ulong magic = entries[Bishop][sq].blackmagic;
      int bits = popcnt(mask);

      for (int i = 0; i < (1 << bits); i++)
      {
        ulong blocks = index_to_u64(i, bits, mask);
        int offset = transform(blocks, magic, 9);
        ulong * ptr  = entries[Bishop][sq].ptr;

        ptr[offset] = get_att!Bishop(sq, blocks);
      }

      entries[Bishop][sq].notmask = ~mask;
      entries[Bishop][sq].blackmagic = magic;
    }
  }

  static this()
  {
    foreach (sq; SQ.A1 .. SQ.size)
    {
      Helper H = helpers[Rook][sq];
      auto ptr = &attacks[H.offset];
      auto mask = get_mask!Rook(sq);
      entries[Rook][sq] = Entry(ptr, ~mask, H.magic);
    }

    foreach (sq; SQ.A1 .. SQ.size)
    {
      Helper H = helpers[Bishop][sq];
      auto ptr = &attacks[H.offset];
      auto mask = get_mask!Bishop(sq);
      entries[Bishop][sq] = Entry(ptr, ~mask, H.magic);
    }

    build_magics();
  }
}

ulong r_att(ulong occ, SQ sq)
{
  ulong * ptr = Magics.entries[Rook][sq].ptr;
  occ        |= Magics.entries[Rook][sq].notmask;
  occ        *= Magics.entries[Rook][sq].blackmagic;
  occ       >>= 64 - 12;
  return ptr[occ];
}

ulong b_att(ulong occ, SQ sq)
{
  ulong * ptr = Magics.entries[Bishop][sq].ptr;
  occ        |= Magics.entries[Bishop][sq].notmask;
  occ        *= Magics.entries[Bishop][sq].blackmagic;
  occ       >>= 64 - 9;
  return ptr[occ];
}

ulong q_att(ulong occ, SQ sq)
{
  return r_att(occ, sq) | b_att(occ, sq);
}

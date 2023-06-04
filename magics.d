module magics;
import square;
import bitboard;

class Magics // Black Magics were discovered by Volker Annuss
{
private:
  struct Entry
  {
    ulong * ptr;
    ulong notmask;
    ulong blackmagic;
  }

  ulong[88507] att_table;
  Entry[64] b_table, r_table;

  enum Rook = 0;
  enum Bishop = 1;

  ulong index_to_u64(int index, int bits, ulong mask)
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

  Dir[4][2] dirs =
  [
    [Dir.U,  Dir.D,  Dir.L,  Dir.R], // Rook
    [Dir.DL, Dir.DR, Dir.UL, Dir.UR] // Bishop
  ];

  ulong get_mask(bool bishop)(SQ sq)
  {
    ulong result = Empty;
    foreach (Dir dir; dirs[+bishop])
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

  ulong get_att(bool bishop)(SQ sq, ulong blocks)
  {
    ulong result = Empty;
    foreach (Dir dir; dirs[+bishop])
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

  int transform(ulong blocks, ulong magic, int bits)
  {
    return cast(int) ((blocks * magic) >> (64 - bits));
  }

  void build_magics()
  {
    foreach (sq; SQ.A1 .. SQ.size) // Rooks
    {
      ulong mask = get_mask!Rook(sq);
      ulong magic = r_table[sq].blackmagic;
      int bits = popcnt(mask);

      for (int i = 0; i < (1 << bits); i++)
      {
        ulong blocks = index_to_u64(i, bits, mask);
        int offset = transform(blocks, magic, 12);
        ulong * ptr  = r_table[sq].ptr;

        ptr[offset] = get_att!Rook(sq, blocks);
      }

      r_table[sq].notmask = ~mask;
      r_table[sq].blackmagic = magic;
    }

    foreach (sq; SQ.A1 .. SQ.size) // Bishops
    {
      ulong mask = get_mask!Bishop(sq);
      ulong magic = b_table[sq].blackmagic;
      int bits = popcnt(mask);

      for (int i = 0; i < (1 << bits); i++)
      {
        ulong blocks = index_to_u64(i, bits, mask);
        int offset = transform(blocks, magic, 9);
        ulong * ptr  = b_table[sq].ptr;

        ptr[offset] = get_att!Bishop(sq, blocks);
      }

      b_table[sq].notmask = ~mask;
      b_table[sq].blackmagic = magic;
    }
  }

  this()
  {
    b_table = [
      Entry( &att_table[66157], Empty, 0x107ac08050500bff ),
      Entry( &att_table[71730], Empty, 0x7fffdfdfd823fffd ),
      Entry( &att_table[37781], Empty, 0x0400c00fe8000200 ),
      Entry( &att_table[21015], Empty, 0x103f802004000000 ),
      Entry( &att_table[47590], Empty, 0xc03fe00100000000 ),
      Entry( &att_table[  835], Empty, 0x24c00bffff400000 ),
      Entry( &att_table[23592], Empty, 0x0808101f40007f04 ),
      Entry( &att_table[30599], Empty, 0x100808201ec00080 ),
      Entry( &att_table[68776], Empty, 0xffa2feffbfefb7ff ),
      Entry( &att_table[19959], Empty, 0x083e3ee040080801 ),
      Entry( &att_table[21783], Empty, 0x040180bff7e80080 ),
      Entry( &att_table[64836], Empty, 0x0440007fe0031000 ),
      Entry( &att_table[23417], Empty, 0x2010007ffc000000 ),
      Entry( &att_table[66724], Empty, 0x1079ffe000ff8000 ),
      Entry( &att_table[74542], Empty, 0x7f83ffdfc03fff80 ),
      Entry( &att_table[67266], Empty, 0x080614080fa00040 ),
      Entry( &att_table[26575], Empty, 0x7ffe7fff817fcff9 ),
      Entry( &att_table[67543], Empty, 0x7ffebfffa01027fd ),
      Entry( &att_table[24409], Empty, 0x20018000c00f3c01 ),
      Entry( &att_table[30779], Empty, 0x407e0001000ffb8a ),
      Entry( &att_table[17384], Empty, 0x201fe000fff80010 ),
      Entry( &att_table[18778], Empty, 0xffdfefffde39ffef ),
      Entry( &att_table[65109], Empty, 0x7ffff800203fbfff ),
      Entry( &att_table[20184], Empty, 0x7ff7fbfff8203fff ),
      Entry( &att_table[38240], Empty, 0x000000fe04004070 ),
      Entry( &att_table[16459], Empty, 0x7fff7f9fffc0eff9 ),
      Entry( &att_table[17432], Empty, 0x7ffeff7f7f01f7fd ),
      Entry( &att_table[81040], Empty, 0x3f6efbbf9efbffff ),
      Entry( &att_table[84946], Empty, 0x0410008f01003ffd ),
      Entry( &att_table[18276], Empty, 0x20002038001c8010 ),
      Entry( &att_table[ 8512], Empty, 0x087ff038000fc001 ),
      Entry( &att_table[78544], Empty, 0x00080c0c00083007 ),
      Entry( &att_table[19974], Empty, 0x00000080fc82c040 ),
      Entry( &att_table[23850], Empty, 0x000000407e416020 ),
      Entry( &att_table[11056], Empty, 0x00600203f8008020 ),
      Entry( &att_table[68019], Empty, 0xd003fefe04404080 ),
      Entry( &att_table[85965], Empty, 0x100020801800304a ),
      Entry( &att_table[80524], Empty, 0x7fbffe700bffe800 ),
      Entry( &att_table[38221], Empty, 0x107ff00fe4000f90 ),
      Entry( &att_table[64647], Empty, 0x7f8fffcff1d007f8 ),
      Entry( &att_table[61320], Empty, 0x0000004100f88080 ),
      Entry( &att_table[67281], Empty, 0x00000020807c4040 ),
      Entry( &att_table[79076], Empty, 0x00000041018700c0 ),
      Entry( &att_table[17115], Empty, 0x0010000080fc4080 ),
      Entry( &att_table[50718], Empty, 0x1000003c80180030 ),
      Entry( &att_table[24659], Empty, 0x2006001cf00c0018 ),
      Entry( &att_table[38291], Empty, 0xffffffbfeff80fdc ),
      Entry( &att_table[30605], Empty, 0x000000101003f812 ),
      Entry( &att_table[37759], Empty, 0x0800001f40808200 ),
      Entry( &att_table[ 4639], Empty, 0x084000101f3fd208 ),
      Entry( &att_table[21759], Empty, 0x080000000f808081 ),
      Entry( &att_table[67799], Empty, 0x0004000008003f80 ),
      Entry( &att_table[22841], Empty, 0x08000001001fe040 ),
      Entry( &att_table[66689], Empty, 0x085f7d8000200a00 ),
      Entry( &att_table[62548], Empty, 0xfffffeffbfeff81d ),
      Entry( &att_table[66597], Empty, 0xffbfffefefdff70f ),
      Entry( &att_table[86749], Empty, 0x100000101ec10082 ),
      Entry( &att_table[69558], Empty, 0x7fbaffffefe0c02f ),
      Entry( &att_table[61589], Empty, 0x7f83fffffff07f7f ),
      Entry( &att_table[62533], Empty, 0xfff1fffffff7ffc1 ),
      Entry( &att_table[64387], Empty, 0x0878040000ffe01f ),
      Entry( &att_table[26581], Empty, 0x005d00000120200a ),
      Entry( &att_table[76355], Empty, 0x0840800080200fda ),
      Entry( &att_table[11140], Empty, 0x100000c05f582008 )
    ];

    r_table = [
      Entry( &att_table[10890], Empty, 0x80280013ff84ffff ),
      Entry( &att_table[56054], Empty, 0x5ffbfefdfef67fff ),
      Entry( &att_table[67495], Empty, 0xffeffaffeffdffff ),
      Entry( &att_table[72797], Empty, 0x003000900300008a ),
      Entry( &att_table[17179], Empty, 0x0030018003500030 ),
      Entry( &att_table[63978], Empty, 0x0020012120a00020 ),
      Entry( &att_table[56650], Empty, 0x0030006000c00030 ),
      Entry( &att_table[15929], Empty, 0xffa8008dff09fff8 ),
      Entry( &att_table[55905], Empty, 0x7fbff7fbfbeafffc ),
      Entry( &att_table[26301], Empty, 0x0000140081050002 ),
      Entry( &att_table[78100], Empty, 0x0000180043800048 ),
      Entry( &att_table[86245], Empty, 0x7fffe800021fffb8 ),
      Entry( &att_table[75228], Empty, 0xffffcffe7fcfffaf ),
      Entry( &att_table[31661], Empty, 0x00001800c0180060 ),
      Entry( &att_table[38053], Empty, 0xffffe7ff8fbfffe8 ),
      Entry( &att_table[37433], Empty, 0x0000180030620018 ),
      Entry( &att_table[74747], Empty, 0x00300018010c0003 ),
      Entry( &att_table[53847], Empty, 0x0003000c0085ffff ),
      Entry( &att_table[70952], Empty, 0xfffdfff7fbfefff7 ),
      Entry( &att_table[49447], Empty, 0x7fc1ffdffc001fff ),
      Entry( &att_table[62629], Empty, 0xfffeffdffdffdfff ),
      Entry( &att_table[58996], Empty, 0x7c108007befff81f ),
      Entry( &att_table[36009], Empty, 0x20408007bfe00810 ),
      Entry( &att_table[21230], Empty, 0x0400800558604100 ),
      Entry( &att_table[51882], Empty, 0x0040200010080008 ),
      Entry( &att_table[11841], Empty, 0x0010020008040004 ),
      Entry( &att_table[25794], Empty, 0xfffdfefff7fbfff7 ),
      Entry( &att_table[49689], Empty, 0xfebf7dfff8fefff9 ),
      Entry( &att_table[63400], Empty, 0xc00000ffe001ffe0 ),
      Entry( &att_table[33958], Empty, 0x2008208007004007 ),
      Entry( &att_table[21991], Empty, 0xbffbfafffb683f7f ),
      Entry( &att_table[45618], Empty, 0x0807f67ffa102040 ),
      Entry( &att_table[70134], Empty, 0x200008e800300030 ),
      Entry( &att_table[75944], Empty, 0x0000008780180018 ),
      Entry( &att_table[68392], Empty, 0x0000010300180018 ),
      Entry( &att_table[66472], Empty, 0x4000008180180018 ),
      Entry( &att_table[23236], Empty, 0x008080310005fffa ),
      Entry( &att_table[19067], Empty, 0x4000188100060006 ),
      Entry( &att_table[    0], Empty, 0xffffff7fffbfbfff ),
      Entry( &att_table[43566], Empty, 0x0000802000200040 ),
      Entry( &att_table[29810], Empty, 0x20000202ec002800 ),
      Entry( &att_table[65558], Empty, 0xfffff9ff7cfff3ff ),
      Entry( &att_table[77684], Empty, 0x000000404b801800 ),
      Entry( &att_table[73350], Empty, 0x2000002fe03fd000 ),
      Entry( &att_table[61765], Empty, 0xffffff6ffe7fcffd ),
      Entry( &att_table[49282], Empty, 0xbff7efffbfc00fff ),
      Entry( &att_table[78840], Empty, 0x000000100800a804 ),
      Entry( &att_table[82904], Empty, 0xfffbffefa7ffa7fe ),
      Entry( &att_table[24594], Empty, 0x0000052800140028 ),
      Entry( &att_table[ 9513], Empty, 0x00000085008a0014 ),
      Entry( &att_table[29012], Empty, 0x8000002b00408028 ),
      Entry( &att_table[27684], Empty, 0x4000002040790028 ),
      Entry( &att_table[27901], Empty, 0x7800002010288028 ),
      Entry( &att_table[61477], Empty, 0x0000001800e08018 ),
      Entry( &att_table[25719], Empty, 0x1890000810580050 ),
      Entry( &att_table[50020], Empty, 0x2003d80000500028 ),
      Entry( &att_table[41547], Empty, 0xfffff37eefefdfbe ),
      Entry( &att_table[ 4750], Empty, 0x40000280090013c1 ),
      Entry( &att_table[ 6014], Empty, 0xbf7ffeffbffaf71f ),
      Entry( &att_table[41529], Empty, 0xfffdffff777b7d6e ),
      Entry( &att_table[84192], Empty, 0xeeffffeff0080bfe ),
      Entry( &att_table[33433], Empty, 0xafe0000fff780402 ),
      Entry( &att_table[ 8555], Empty, 0xee73fffbffbb77fe ),
      Entry( &att_table[ 1009], Empty, 0x0002000308482882 )
    ];

    build_magics();
  }

  ulong r_att(ulong occ, SQ sq);
  ulong b_att(ulong occ, SQ sq);
  ulong q_att(ulong occ, SQ sq);

public:
  static Magics getInstance()
  {
    static Magics instance;
    return instance;
  }
}

ulong r_att(ulong occ, SQ sq)
{
  Magics magics = Magics.getInstance();
  ulong * ptr = magics.r_table[sq].ptr;
  occ        |= magics.r_table[sq].notmask;
  occ        *= magics.r_table[sq].blackmagic;
  occ       >>= 64 - 12;
  return ptr[occ];
}

ulong b_att(ulong occ, SQ sq)
{
  Magics magics = Magics.getInstance();
  ulong * ptr = magics.b_table[sq].ptr;
  occ        |= magics.b_table[sq].notmask;
  occ        *= magics.b_table[sq].blackmagic;
  occ       >>= 64 - 9;
  return ptr[occ];
}

ulong q_att(ulong occ, SQ sq)
{
  return r_att(occ, sq) | b_att(occ, sq);
}

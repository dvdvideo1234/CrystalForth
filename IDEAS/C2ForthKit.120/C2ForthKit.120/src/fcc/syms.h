#ifndef _syms_h
#define _syms_h

#define SYMNMLEN 8
#ifndef PACKED
#ifdef __GNUC__
#define PACKED __attribute__((packed))
#else
#define PACKED
#endif
#endif
#define SYMENT struct syment
#define SYMSZ sizeof(struct syment)
#define n_name     _n._n_name
#define n_nptr     _n._n_nptr[1]
#define n_zeroes   _n._n_n._n_zeroes
#define n_offset   _n._n_n._n_offset
#define T_NULL  0
#define T_VOID  1
#define T_CHAR  2
#define T_SHORT 3
#define T_INT   4
#define T_LONG  5
#define T_FLOAT 6
#define T_DOUBLE 7
#define T_STRUCT 8
#define T_UNION  9
#define T_ENUM   10
#define T_MOE    11
#define T_UCHAR  12
#define T_USHORT 13
#define T_UINT   14
#define T_ULONG  15
#define DT_NON    0
#define DT_PTR    1
#define DT_FCN    2
#define DT_ARY    3
#define C_NULL      0
#define C_AUTO      1
#define C_EXT       2
#define C_STAT      3
#define C_REG       4
#define C_EXTDEF    5
#define C_LABEL     6
#define C_ULABEL    7
#define C_MOS       8
#define C_ARG       9
#define C_STRTAG   10
#define C_MOU      11
#define C_UNTAG    12
#define C_TPDEF    13
#define C_USTATIC  14
#define C_ENTAG    15
#define C_MOE      16
#define C_REGPARM  17
#define C_FIELD    18
#define C_BLOCK   100
#define C_FCN     101
#define C_EFCN    102
#define C_EOS     103
#define C_FILE    104
#define C_LINE    105
#define N_DEBUG   (-2)
#define N_ABS     (-1)
#define N_UNDEF   0
#define AUXENT union auxent
struct syment
{
  union
    {
      char _n_name[SYMNMLEN] PACKED;
      struct
        {
          long _n_zeroes PACKED;
          long _n_offset PACKED;
        } _n_n;
      char *_n_nptr[2] PACKED;
    } _n;
    long n_value PACKED;
    short n_scnum PACKED;
    unsigned short n_type PACKED;
    char n_sclass PACKED;
    char n_numaux PACKED;
};
struct aux_file
{
  char x_name[18];
};
struct aux_tag
{
  long x_tagndx PACKED;
  unsigned short x_line PACKED;
  unsigned short x_size PACKED;
  long x_spare_1 PACKED;
  long x_endndx PACKED;
  short x_spare_2 PACKED;
};
struct aux_fun
{
  long x_tagndx PACKED;
  long x_fsize PACKED;
  long x_lnnoptr PACKED;
  long x_endndx PACKED;
  short x_spare_2 PACKED;
};
struct aux_arr
{
  long x_tagndx PACKED;
  unsigned short x_line PACKED;
  unsigned short x_size PACKED;
  unsigned short x_dim1 PACKED;
  unsigned short x_dim2 PACKED;
  unsigned short x_dim3 PACKED;
  unsigned short x_dim4 PACKED;
  short x_spare_2 PACKED;
};
union auxent
{
  struct aux_file file PACKED;
  struct aux_tag tag PACKED;
  struct aux_fun fun PACKED;
  struct aux_arr block PACKED;
};

#endif

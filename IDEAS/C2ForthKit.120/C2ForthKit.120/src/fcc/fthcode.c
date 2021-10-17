// fthcode.c - C2Forth code generator

/*
Copyright (c) 1998, 1999, 2000, 2003, 2007, 2012
MicroProcessor Engineering
133 Hill Lane
Southampton SO15 5AF
England

tel:   +44 (0)23 8063 1441
fax:   +44 (0)23 8033 9691
email: mpe@mpeforth.com
       tech-support@mpeforth.com
web:   http://www.mpeforth.com
Skype: mpe_sfp

From North America, our telephone and fax numbers are:
       011 44 23 8063 1441
       011 44 23 8033 9691
       901 313 4312 (North American access number to UK office)


To do
=====

Change history
==============
20121223 SFP001 Revert to previous option B
		Changed >>N to ARSHIFT
*/


// #define         TRACECODE_PROC
// #define         TRACECODE

#include "rcc.no"
#include "version.h"
#include <stdlib.h>
#include <string.h>
#include "c.h"
#include "syms.h"
#define signedp(x) ((1<<optype(x)) & ((1<<D)|(1<<F)|(1<<I)|(1<<S)|(1<<C)))
typedef struct
{
  int lev;
  unsigned long typecode;
  Type tag;
} type_info_t;
static void progbeg(int argc, char *argv[]);
static void progend();
static void defsymbol(Symbol p);
static void export(Symbol p);
static void import(Symbol p);
static void segment(int s);
static void global(Symbol p);
static void defconst(int ty, Value v);
static void address(Symbol q, Symbol p, int n);
static void defaddress(Symbol p);
static void defstring(int len, char *s);
static void space(int n);
static void function(Symbol f, Symbol caller[], Symbol callee[], int ncalls);
static void emit(Node p);
static Node gen(Node p);
static void gen_binary(Node p, char *insn);
static void gen_compare(Node p, char *uns_str, char *sgn_str);
static void genx(Node p);
static void gen_frame_fetch(int type, int signed, long offset);
static void gen_frame_store(int type, long offset);
static void gen_frame_addr(long offset);
static int is_const_address(Node x);
static int is_same_address(Node x, Node y);

static void local(Symbol p);
static void stabinit(char *file, int argc, char *argv[]);
static void stabline(Coordinate *cp);
static void stabblock(int brace, int lev, Symbol *p);
static void gettypeinfo(Type ty, type_info_t *info);
static void gettypecode(Type ty, type_info_t *info);
static char *tagname(Type ty);
static void emit_type(Type ty, int lev);
static int ntypes;
static void asgncode(Type ty, int lev);

static void dbxout(Type ty);

static void stabsym(Symbol p)
{
  type_info_t info;
  int sclass;
  char *xname;

  printf("\nSTABSYM: %s\n", p->x.name );

  if (p->generated || p->computed || p->sclass == EXTERN)
    return;

#if 0
  if (isfunc(p->type))
    return;
#endif

  asgncode(p->type, 0);
  dbxout(p->type);
  gettypeinfo(p->type, &info);

  xname = p->x.name;
  if (p->sclass == AUTO && p->scope == GLOBAL)
    sclass = C_EXT;
  else if (p->sclass == STATIC)
    sclass = C_STAT;
  else if (p->sclass == GLOBAL)
    sclass = C_EXT;
  else if (p->scope == PARAM)
    {
      sclass = C_ARG;
      xname = stringd(p->x.offset * 8);
    }
  else if (p->scope >= LOCAL)
    {
      sclass = C_AUTO;
      xname = stringd(p->x.offset * 8);
    }
  else
    assert(0);

  print("\tSYMBOL _%s VAL %s TYPE %u SCLASS %d SIZE %d",
        p->name,
        xname,
        info.typecode,
        sclass,
        p->type->size*8);
  if (info.tag)
    print(" TAG %s", tagname(info.tag));
  print("\n");
}

static void stabtype(Symbol p);
char *pic_release = VERSION;
char *pic_copyright = COPYRIGHT;
static Interface epicodeInterface =
{
  1, 1, 0,
4, 4, 0,
4, 4, 0,
4, 4, 0,
8, 8, 0,
4, 4, 0,
0, 1, 0,
    0,    /* 1 = little endian, 0 = big endian */
    0,    /* 1 = use RTS for mulops, 0 = use MUL/DIV/MOD */
    0,    /* 1 = use CALLB instruction, 0 = don't */
    0,    /* 1 = use ARGB instruction, 0 = don't */
    0,    /* 1 = stack function arguments left to right, 0 = right to left */
    0     /* 1 = generate DAGs, 0 = generate trees (i.e. undag) */,
  address,
  blockbeg,
  blockend,
  defaddress,
  defconst,
  defstring,
  defsymbol,
  emit,
  export,
  function,
  gen,
  global,
  import,
  local,
  progbeg,
  progend,
  segment,
  space,
  stabblock,
  0,         /* stabend */
  0,         /* stabfend */
  stabinit,  /* stabinit */
  stabline,  /* stabline */
  stabsym,
  stabtype,
};
extern Interface symbolicInterface;
extern Interface c40Interface;
Binding bindings[] = {
  "epicode",  &epicodeInterface,
  "symbolic", &symbolicInterface,
  NULL,       NULL
};

static int heads  = 0;
static int sframe = 1;          /* Use short-from frame tokens? */
static int revbin = 1;          /* Reverse constant arguments to binary ops? */

static Node *tail;
static char *currentfile;
static void
progbeg(int argc, char *argv[])
{
  /* Determine host byte ordering. */
  union {
    char c;
    int i;
  } u;
  int i;

  u.i = 0;
  u.c = 1;
  swap = (u.i == 1);

  for (i = 0; i < argc; i++)
    if (strcmp(argv[i], "-heads") == 0)
      heads = 1;
    else
    if (strcmp(argv[i], "-sframe") == 0)
      sframe = 0;
    else
    if (strcmp(argv[i], "-revbin") == 0)
      revbin = 0;

}
static void progend()
{
}

static void
defsymbol(Symbol p)
{
  if (p->scope == CONSTANTS)
    switch (ttob(p->type))
      {
        case U: p->x.name = stringf("%u", p->u.c.v.u); break;
        case C: p->x.name = stringf("%d", p->u.c.v.sc); break;
        case S: p->x.name = stringd(p->u.c.v.ss); break;
        case I: p->x.name = stringd(p->u.c.v.i); break;
        case P: p->x.name = stringf("%u", p->u.c.v.p); break;
        case F: {
                  unsigned long *v = (unsigned long*)&p->u.c.v.f;
                  p->x.name = stringd(*v);
                }
                break;
        case D: {
                  unsigned long *v = (unsigned long *)&p->u.c.v.d;
                  p->x.name = stringf("%u:%u", v[swap], v[!swap]);
                }
                break;
        default: assert(0);
      }
  else
    p->x.name = p->name;
  if (p->scope >= LABELS)
    p->x.name = stringf(p->generated ? "@%s" : "_%s", p->x.name);
}

static void export(Symbol p)
{
        print("\nPUBLIC %s\n", p->x.name);
}

static void import(Symbol p)
{
        print("EXTERN %s\n", p->x.name);
}

static void segment(int s)
{
}

static void global(Symbol p)
{
        print("LABEL  %s\n", p->x.name);
}

static void defconst(int ty, Value v)
{
        switch (ty)
        {
        case C:
                print("\t%d c,\n", (signed char)v.sc);
                break;
        case S:
                print("\t%d  ,\n", v.ss);
                break;
        case I:
                print("\t%d  ,\n", v.i);
                break;
        case U:
                print("\t%u  ,\n", v.u);
                break;
        case P:
                print("\t%u  ,\n", v.p);
                break;
        default:
                assert(0);
        }
}

static void
address(Symbol q, Symbol p, int n)
{
  if (p->scope == GLOBAL || p->sclass == STATIC || p->sclass == EXTERN)
    q->x.name = stringf("%s%s%d", p->x.name, n >= 0 ? "+" : "", n);
  else
    {
      q->x.offset = p->x.offset + n;
      q->x.name = stringd(q->x.offset);
    }
}

static void gen_name_offset( char *text )
{
        int     offset = 0;
        int     dir    = 1;

        while ( (*text!='\0') && (*text!='+') && (*text!='-') )
        {
                print("%c",*text++);
        }

        if (*text=='\0') { print(" #0 "); return; }

        while (*text!='\0')
        {
                dir = 1;
                if ( *text == '-' ) { dir = -1; text++; }
                if ( *text == '+' ) { dir = 1; text++; }
                if ( dir == 1 ) offset+=atoi(text);
                else offset-=atoi(text);
                while ( (*text!='\0') && (*text!='+') && (*text!='-') ) text++;
        }
        print(" #%d ", offset );
}

static void defaddress(Symbol p)
{
        print("\tCommaAddr ");
        gen_name_offset(p->x.name);
        print("\n");
}

static void defstring(int len, char *s)
{
        char    temp[80];

        while (len--)
        {
                sprintf(temp,"\t\t$%02X c,\n", (unsigned char)*s++ );
                print(temp);
        }
}

static void space(int n)
{
        print("\t#%d allot&erase\n", n);
}


int     current_local_frame_size;

static void
function(Symbol f, Symbol caller[], Symbol callee[], int ncalls)
{
  int i, paramoffset;
  int paramsize, localsize;

  /* Emit function name as a label. */
  print("FLABEL %s\n", f->x.name);
  print(":NONAME\n");

  /* First parameter is at frame+2*cellsize. */
  paramoffset = 2*inttype->size;
  for (i = 0; caller[i] && callee[i]; i++)
    {
      caller[i]->x.offset = callee[i]->x.offset = paramoffset;
      caller[i]->x.name = callee[i]->x.name = stringd(paramoffset);
      /* Thwart any attempt at register assignment */
      callee[i]->sclass = AUTO;
      paramoffset += roundup(caller[i]->type->size, inttype->size);
    }

  /* First local is placed below frame+0. */
  offset = 0;
  maxoffset = 0;

  /* Figure out whether this is a variadic (varargs) function.
     We need this to save the data stack depth on entry do the
     varargs functions can rummage through the data stack. If
     this is a variadic function, store the data stack depth
     in a temporary at frame-cell_size. */
  if (variadic(f->type))
    offset += inttype->size;

  /* Select code. */
  gencode(caller, callee);

  /* Construct the frame. */
  paramsize = roundup(paramoffset-2*inttype->size, inttype->size) / inttype->size;
  localsize = roundup(maxoffset, inttype->size) / inttype->size;

  if (paramsize > 0 || localsize > 0)
  {
// Option A
//       print("\n\tMAKELVS [ #%d w, #%d w, ]\n", paramsize, localsize );
// Option B		// SFP001
        print("\n\t{ ");
        for ( i = 0; i < paramsize ; i++ )
        print("$arg%d ", paramsize-1-i);
        if (localsize) print("| $loc[ %d ] -- }\n",localsize*inttype->size);
        else           print("| -- }\n");
        current_local_frame_size = localsize*inttype->size;
  }


  /* Store the stack depth for stdarg functions to mess with.  We always
     store it in a frame-cell_size. */
  if (variadic(f->type))
  {
        print("\tdepth "); gen_frame_store( !C, -4 );
  }

  /* Emit our chosen code. */
  emitcode();

//  if (localsize||paramsize) print("\n\tRELLVS\n");	// SFP001

  /* Clean up after function exit. */
  print("; drop\n\n");

}

/* emit - emit the dags on list p */
static void
emit(Node p)
{
  for (; p; p = p->x.next)
    if (p->op == LABEL+V)
      {
        assert(p->syms[0]);
        print("LABEL  %s\n", p->syms[0]->x.name);
#ifdef TRACECODE
        print("cr .\" Label %s - \" depth . ", p->syms[0]->x.name );
#endif
      }
    else
      genx(p);
}
static Node
gen(Node forest)
{
  int argoffset = 0;
  int n = 0;
  Node p, nodelist;

  tail = &nodelist;

  for (p = forest; p; p = p->link)
    {
      assert(p->count == 0);
      if (generic(p->op) == CALL)
        p->syms[0] = intconst(argoffset);
      else if (generic(p->op) == ASGN && generic(p->kids[1]->op) == CALL)
        p->kids[1]->syms[0] = intconst(argoffset);
      else if (generic(p->op) == ARG)
        argoffset += roundup(p->syms[0]->u.c.v.i, inttype->size);

      p->x.listed = 1;
      if (p->x.inst == 0)
        {
          p->x.inst = ++n;
          *tail = p;
          tail = &p->x.next;
        }
    }
  *tail = 0;
  return nodelist;
}
static void
gen_binary(Node p, char *insn)
{
  if ( revbin
  &&   (    p->op == ADDI       /* If it's a commutative operator and the   */
         || p->op == ADDU       /* the first operand is a constant whereas  */
         || p->op == ADDP       /* the second is *not*, then switch the     */
         || p->op == MULI       /* order of evaluation so that the optimser */
         || p->op == MULU )     /* can use ADDLIT, etc.                     */
  &&   generic(p->kids[0]->op) == CNST
  &&   generic(p->kids[1]->op) != CNST )
    genx(p->kids[1]),
    genx(p->kids[0]);
  else
    genx(p->kids[0]),
    genx(p->kids[1]);

  print("\t%s\n", insn);
}

static void gen_compare(Node p, char *sgn_str, char *uns_str)
{
        genx(p->kids[0]);
        genx(p->kids[1]);
        print("\t%s\n", signedp(p->op) ? sgn_str : uns_str);
        print("\tCompileCondBranch %s\n", p->syms[0]->x.name);
}

static void
genx(Node p)
{
  static int nesting;
  static int param_size = 0;
  nesting++;
  if (p)
    {
      if (glevel > 2)
        print("-- node %d %s count=%d\n", p->x.inst,
              opname(p->op), p->count);

      switch(p->op)
        {
        case CNSTC:
          print("\t#%d\n", p->syms[0]->u.c.v.sc);
          break;

        case CNSTS:
          print("\t#%d\n", p->syms[0]->u.c.v.ss);
          break;

        case CNSTI:
          print("\t#%d\n", p->syms[0]->u.c.v.i);
          break;

        case CNSTU:
          print("\t#%d\n", p->syms[0]->u.c.v.u);
          break;

        case CNSTP:
          print("\t#%d\n", p->syms[0]->u.c.v.p);
          break;

        case CNSTF:
        case CNSTD:
          assert(0);
        case BCOMU:
          genx(p->kids[0]);
          print("\tinvert\n");
          break;

        case NEGI:
          genx(p->kids[0]);
          print("\tnegate\n");
          break;

        case NEGF:
        case NEGD:
          assert(0);
        case ADDI:
        case ADDU:
        case ADDP:
          gen_binary(p, "+");
          break;

        case SUBI:
        case SUBU:
        case SUBP:
          gen_binary(p, "-");
          break;

        case MULI:
          gen_binary(p, "*");
          break;

        case MULU:
          gen_binary(p, "um* d>s");
          break;

        case DIVI:
          gen_binary(p, "/");
          break;

        case DIVU:
          gen_binary(p, "0 swap um/mod nip");
          break;

        case ADDF:
        case ADDD:
        case SUBF:
        case SUBD:
        case MULF:
        case MULD:
        case DIVF:
        case DIVD:
          assert(0);

        case MODI:
          gen_binary(p, "mod");
          break;

        case MODU:
          gen_binary(p, "0 swap um/mod drop");
          break;

        case LSHI:
        case LSHU:
          gen_binary(p, "lshift");
          break;

        case RSHI:
          gen_binary(p, "arshift");	// SFP001
//          gen_binary(p, ">>N");
          break;

        case RSHU:
          gen_binary(p, "rshift");
          break;

        case BANDU:
          gen_binary(p, "and");
          break;

        case BORU:
          gen_binary(p, "or");
          break;

        case BXORU:
          gen_binary(p, "xor");
          break;
        case ASGNB:
          /* structure assign. */
          assert(p->kids[1]->op == INDIRB);
          genx(p->kids[1]->kids[0]);
          genx(p->kids[0]);
          print("#%d move\n", p->syms[0]->u.c.v.i);
          break;

        case ASGNC:
        case ASGNS:
        case ASGNI:
        case ASGNP:
        case ASGNF:
        case ASGND:
          /* Optimize x = x + n to x+=n, for integers. */
          if (p->kids[1]->op == ADDI &&
              p->kids[1]->kids[0]->op == INDIRI &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t+!\n");
            }
          /* Optimize x = x - n to x-=n, for integers. */
          else if (p->kids[1]->op == SUBI &&
              p->kids[1]->kids[0]->op == INDIRI &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t-!\n");
            }
          /* Optimize x = x + n to x+=n, for unsigned integers. */
          else if (p->kids[1]->op == ADDU &&
              p->kids[1]->kids[0]->op == INDIRI &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t+!\n");
            }
          /* Optimize x = x - n to x-=n, for unsigned integers. */
          else if (p->kids[1]->op == SUBU &&
              p->kids[1]->kids[0]->op == INDIRI &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t-!\n");
            }
          /* Optimize x = x + n to x+=n, for pointers. */
          else if (p->kids[1]->op == ADDP &&
              p->kids[1]->kids[0]->op == INDIRP &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t+!\n");
            }
          /* Optimize x = x - n to x-=n, for pointers. */
          else if (p->kids[1]->op == SUBP &&
              p->kids[1]->kids[0]->op == INDIRP &&
              is_same_address(p->kids[0], p->kids[1]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[1]);
              genx(p->kids[0]);
              print("\t-!\n");
            }
          /* Optimize x = x + n to x+=n, for shorts. */
          else if (p->kids[1]->op == CVIS &&
                   p->kids[1]->kids[0]->op == ADDI &&
                   p->kids[1]->kids[0]->kids[0]->op == CVSI &&
                   p->kids[1]->kids[0]->kids[0]->kids[0]->op == INDIRS &&
                   is_same_address(p->kids[0],
                                   p->kids[1]->kids[0]->kids[0]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[0]->kids[1]);
              genx(p->kids[0]);
              print("\t+!\n");
            }
          /* Optimize x = x - n to x-=n, for shorts. */
          else if (p->kids[1]->op == CVIS &&
                   p->kids[1]->kids[0]->op == SUBI &&
                   p->kids[1]->kids[0]->kids[0]->op == CVSI &&
                   p->kids[1]->kids[0]->kids[0]->kids[0]->op == INDIRS &&
                   is_same_address(p->kids[0],
                                   p->kids[1]->kids[0]->kids[0]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[0]->kids[1]);
              genx(p->kids[0]);
              print("\t-!\n");
            }
          /* Optimize x = x + n to x+=n, for unsigned shorts. */
          else if (p->kids[1]->op == CVUS &&
                   p->kids[1]->kids[0]->op == ADDU &&
                   p->kids[1]->kids[0]->kids[0]->op == CVSU &&
                   p->kids[1]->kids[0]->kids[0]->kids[0]->op == INDIRS &&
                   is_same_address(p->kids[0],
                                   p->kids[1]->kids[0]->kids[0]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[0]->kids[1]);
              genx(p->kids[0]);
              print("\t+!\n");
            }
          /* Optimize x = x - n to x-=n, for unsigned shorts. */
          else if (p->kids[1]->op == CVUS &&
                   p->kids[1]->kids[0]->op == SUBU &&
                   p->kids[1]->kids[0]->kids[0]->op == CVSU &&
                   p->kids[1]->kids[0]->kids[0]->kids[0]->op == INDIRS &&
                   is_same_address(p->kids[0],
                                   p->kids[1]->kids[0]->kids[0]->kids[0]->kids[0]))
            {
              genx(p->kids[1]->kids[0]->kids[1]);
              genx(p->kids[0]);
              print("\t-!\n");
            }
          else if (p->kids[0]->op == ADDRLP || p->kids[0]->op == ADDRFP)
            {
              genx(p->kids[1]);
              gen_frame_store(optype(p->op), p->kids[0]->syms[0]->x.offset);
            }
          else
            {
              genx(p->kids[1]);
              genx(p->kids[0]);
              if (p->op == ASGNC)
                print("\tc!\n");
              else
                print("\t!\n");
            }
          break;
        case GTI:
        case GTU:
        case GTF:
        case GTD:
          gen_compare(p, ">", "u>");
          break;

        case LTI:
        case LTU:
        case LTF:
        case LTD:
          gen_compare(p, "<", "u<");
          break;

        case LEI:
        case LEU:
        case LEF:
        case LED:
          gen_compare(p, "<=", "u<=");
          break;

        case GEI:
        case GEU:
        case GEF:
        case GED:
          gen_compare(p, ">=", "u>=");
          break;

        case EQI:
        case EQF:
        case EQD:
          gen_compare(p, "=", "=");
          break;

        case NEI:
        case NEF:
        case NED:
          gen_compare(p, "<>", "<>");
          break;

        case CVCI:
          if (p->kids[0]->op == INDIRC)
            {
              if (p->kids[0]->kids[0]->op == ADDRLP || p->kids[0]->kids[0]->op == ADDRFP)
                gen_frame_fetch(C, 1, p->kids[0]->kids[0]->syms[0]->x.offset);
              else
                {
                  /* Fetch from memory and extend. */
                  genx(p->kids[0]->kids[0]);    /* generate thing to indirect */
                  print("\tc@s\n");
                }
            }
          else
            {
              /* Sign-extend from 8 to 32 bits. */
              genx(p->kids[0]);
              print("\tchar>cell\n");      /* Was << 24 followed by >> 24. */
            }
          break;

        case CVCU:
          if (p->kids[0]->op == INDIRC)
            {
              if (p->kids[0]->kids[0]->op == ADDRLP || p->kids[0]->kids[0]->op == ADDRFP)
                gen_frame_fetch(C, 0, p->kids[0]->kids[0]->syms[0]->x.offset);
              else
                {
                  /* Fetch from memory and extend. */
                  genx(p->kids[0]->kids[0]);    /* generate thing to indirect */
                  print("\tc@\n");
                }
            }
          else
            {
              /* Zero-extend from 8 to 24 bits. */
              genx(p->kids[0]);
              print("\t#255 and\n");
            }
          break;

        case CVDI:
        case CVDF:
        case CVFD:
        case CVID:
          assert(0);

        case CVIC:
        case CVIS:
        case CVUC:
        case CVUS:
        case CVIU:
        case CVUI:
        case CVPU:
        case CVUP:
          genx(p->kids[0]);
          break;

        case CVSI:
          genx(p->kids[0]);
          if (shorttype->size != inttype->size)
            assert(0);
          break;

        case CVSU:
          genx(p->kids[0]);
          if (unsignedshort->size != unsignedtype->size)
            assert(0);
          break;
        case JUMPV:
          if (p->kids[0]->op == ADDRGP)
            print("\tCompileBranch %s\n", p->kids[0]->syms[0]->x.name);
          else
            {
              genx(p->kids[0]);
              print("\tCompileJump\n");
            }
          break;

        case ARGI:
        case ARGP:
        case ARGF:
        case ARGD:
        case ARGB:
          param_size += roundup(p->syms[0]->u.c.v.i, inttype->size);
          genx(p->kids[0]);
          break;

        case RETI:
        case RETF:
        case RETD:
          genx(p->kids[0]);
          break;

        case ADDRLP:
        case ADDRFP:
          gen_frame_addr(p->syms[0]->x.offset);
          break;

        case ADDRGP:
          print("\tCompileAddrLit ");
          gen_name_offset( p->syms[0]->x.name );
          print("\n");
          break;

        case CALLI:
        case CALLF:
        case CALLD:
        case CALLV:
          if (p->kids[0]->op == ADDRGP)
            {
              Type fty;
              print("\tCompileCall %s\n", p->kids[0]->syms[0]->x.name);
              fty = p->kids[0]->syms[0]->type;
              if (isfunc(fty) && variadic(fty) && !fty->u.f.oldstyle)
                {
                  long bytes, ndrop;
                  Type *proto;
                  for (proto = fty->u.f.proto, bytes = 0;
                       proto && *proto && *proto != voidtype;
                       proto++)
                    bytes += roundup((*proto)->size, inttype->size);

                  ndrop = param_size - bytes;
                  if (ndrop < 0)
                    ndrop = 0;
                  ndrop /= inttype->size;
                  if (ndrop > 0)
                    {
                      while (ndrop-- > 0)
                        if (nesting > 1 && p->op != CALLV)
                          print("nip\n");
                        else
                          print("\tdrop\n");
                    }
                }
            }
          else
            {
              genx(p->kids[0]);
              print("\texecute\t\\ Was ICALL \n");
            }
          if (nesting == 1 && p->op != CALLV)
            /* Drop value for CALL without ASGN. */
            print("\tdrop\n");

          /* Reset parameter size. */
          param_size = 0;
          break;

        case INDIRB:
          genx(p->kids[0]);
          break;

        case INDIRC:
        case INDIRS:
        case INDIRI:
        case INDIRP:
        case INDIRF:
        case INDIRD:
          if (p->kids[0]->op == ADDRLP || p->kids[0]->op == ADDRFP)
            gen_frame_fetch(optype(p->op),
                            signedp(optype(p->op)),
                            p->kids[0]->syms[0]->x.offset);
          else if (p->op == INDIRC)
            {
              genx(p->kids[0]);
              print("\tc@s\n");
            }
          else
            {
              genx(p->kids[0]);
              print("\t@\n");
            }
          break;

        default:
          print("/* HELP!  Not handled in pic::genx: opname = %s */\n",
                opname(p->op));
          assert(0);
        }
    }
  nesting--;
}


static void gen_frame_addr(long offset)
{
// Option A
//        print("\n\t[ #%d lv, ]\n", offset );
// Option B		// SFP001
        if ( offset > 0 )               // argument
        {
                if (offset&3) { fprintf(stderr,"Bang, non-cell aligned frame access on argument"); assert(0); }
                print("\taddr $arg%d ", (offset-8)/inttype->size );
        } else {                        // local
                print("\t$loc[ %d + ", current_local_frame_size+offset );
        }
}

static void gen_frame_bytefetch(int op, int signextend, long offset)
{
        gen_frame_addr( offset );
        if (signextend) print("c@s"); else print("c@");
        print("\n");
}

static void gen_frame_cellfetch(int op, long offset)
{
        if (offset & 0x3) error("misaligned frame store detected\n");
        gen_frame_addr( offset ); print("\t@\n");
}

static void gen_frame_bytestore(int op, long offset)
{
        gen_frame_addr( offset );
        print("\tc!\n");
}

static void gen_frame_cellstore(int op, long offset)
{
        if (offset & 0x3) error("misaligned frame store detected\n");
        gen_frame_addr( offset ); print("\t!\n");
}

static void gen_frame_fetch(int op, int signextend, long offset)
{
        if (op == C) gen_frame_bytefetch(op,signextend,offset);
        else         gen_frame_cellfetch(op,offset);
}

static void gen_frame_store(int op, long offset)
{
        if (op == C)    gen_frame_bytestore(op,offset);
        else            gen_frame_cellstore(op,offset);
}




static int
is_const_address(Node x)
{
  return x->op == ADDRGP || x->op == ADDRLP || x->op == ADDRFP;
}
static int
is_same_address(Node x, Node y)
{
  return is_const_address(x) && is_const_address(y) && x->syms[0] == y->syms[0];
}
static void
local(Symbol p)
{
  /* Decline all front-end attempts to put things in registers. */
  if (p->sclass == REGISTER)
    p->sclass = AUTO;

  offset = roundup(offset, p->type->align);  /* align within frame. */
  offset += p->type->size;
  p->x.offset = -offset;
  p->x.name = stringd(-offset);
}
static void
stabinit(char *file, int argc, char *argv[])
{
  if (file)
    {
      print("\tFILE \"%s\"\n", file);
      currentfile = file;
    }
}
static void
stabline(Coordinate *cp)
{
  if (cp->file && cp->file != currentfile)
    {
      print("\tFILE \"%s\"\n", cp->file);
      currentfile = cp->file;
    }
  print("\tLINE %d\n", cp->y);
}
static void
stabblock(int brace, int lev, Symbol *p)
{
  if (lev > 0)
    if (brace == '{')
      print("\tBEGINBLOCK\n");
    else
      print("\tENDBLOCK\n");

  if (brace == '{')
    while (*p)
     stabsym(*p++);
}

static void
gettypeinfo(Type ty, type_info_t *info)
{
  info->lev = 0;
  info->typecode = 0;
  info->tag = NULL;
  gettypecode(ty, info);
}
static void
gettypecode(Type ty, type_info_t *info)
{
  if (isconst(ty) || isvolatile(ty))
    gettypecode(ty->type, info);
  else
    switch (ty->op)
    {
    case VOID:
      /* void is mapped to T_NULL. */
      info->typecode = T_NULL;
      break;

    case CHAR:
      if (ty == unsignedchar)
        info->typecode = T_UCHAR;
      else
        info->typecode = T_CHAR;
      break;

    case SHORT:
      if (ty == unsignedshort)
        info->typecode = T_USHORT;
      else
        info->typecode = T_SHORT;
      break;

    case INT:
      info->typecode = T_INT;
      break;

    case UNSIGNED:
      info->typecode = T_UINT;
      break;

    case FLOAT:
      info->typecode = T_FLOAT;
      break;

    case DOUBLE:
      info->typecode = T_DOUBLE;
      break;

    case POINTER:
      gettypecode(ty->type, info);
      if (info->lev < 6)
        info->typecode |= ((unsigned long)DT_PTR) << (info->lev*2+4);
      info->lev++;
      break;

    case FUNCTION:
      gettypecode(ty->type, info);
      if (info->lev < 6)
        info->typecode |= ((unsigned long)DT_FCN) << (info->lev*2+4);
      info->lev++;
      break;

    case ARRAY:  /* array includes subscript as an int range */
      gettypecode(ty->type, info);
      if (info->lev < 6)
        info->typecode |= ((unsigned long)DT_ARY) << (info->lev*2+4);
      info->lev++;
      break;

    case STRUCT:
      info->typecode = T_STRUCT;
      info->tag = ty;
      break;

    case UNION:
      info->typecode = T_UNION;
      info->tag = ty;
      break;

    case ENUM:
      info->typecode = T_ENUM;
      info->tag = ty;
      break;

    default:
      assert(0);
    }
}
static char *
tagname(Type ty)
{
  /* <ust be static because we return a pointer to it. */
  static char buf[128];

  if ('0' <= ty->u.sym->name[0] && ty->u.sym->name[0] <= '9')
    return strcat(strcpy(buf, "@fake"), ty->u.sym->name);
  else
    return strcat(strcpy(buf, "_"), ty->u.sym->name);
}
static void
emit_type(Type ty, int lev)
{
  int tc = ty->x.typeno;

  if (isconst(ty) || isvolatile(ty)) {
    emit_type(ty->type, lev);
    ty->x.typeno = ty->type->x.typeno;
    ty->x.printed = 1;
    return;
  }
  if (tc == 0) {
    ty->x.typeno = tc = ++ntypes;
/*              fprint(2,"`%t'=%d\n", ty, tc); */
  }
  if (ty->x.printed)
    return;
  ty->x.printed = 1;
  switch (ty->op) {
  case VOID:
  case CHAR:
  case SHORT:
  case INT:
  case UNSIGNED:
  case FLOAT:
  case DOUBLE:
  case POINTER:
  case FUNCTION:
  case ARRAY:
    break;

  case STRUCT: case UNION:
    {
      Field p;
#if 0
      if (!ty->u.sym->defined)
        {
          print("=x%c%s:", ty->op == STRUCT ? 's' : 'u', ty->u.sym->name);
          break;
        }
#endif
      if (lev > 0 && (*ty->u.sym->name < '0' || *ty->u.sym->name > '9'))
        {
          ty->x.printed = 0;
          break;
        }
      print("\t%s %s %d\n",
            ty->op == STRUCT ? "STRUCTTAG" : "UNIONTAG",
            tagname(ty),
            ty->size*8);
      for (p = fieldlist(ty); p; p = p->link)
        if (p->name)
          {
            type_info_t info;
            gettypeinfo(p->type, &info);
            print("\tMEMBER _%s", p->name);
            if (p->lsb)
              print(" VAL %d TYPE %d SCLASS %d SIZE %d\n",
                    8*p->offset + (IR->little_endian ? fieldright(p) : fieldleft(p)),
                    info.typecode,
                    ty->op == STRUCT ? C_MOS : C_MOU,
                    fieldsize(p));
            else
              print(" VAL %d TYPE %d SCLASS %d SIZE %d\n",
                    8*p->offset,
                    info.typecode,
                    ty->op == STRUCT ? C_MOS : C_MOU,
                    8*p->type->size);
          }
      print("\tENDSTRUCTTAG\n");
    }
    break;
  case ENUM:
    {
      Symbol *p;
      if (lev > 0 && (*ty->u.sym->name < '0' || *ty->u.sym->name > '9')) {
        ty->x.printed = 0;
        break;
      }
      print("\t%ENUMTAG %s %d\n", tagname(ty), ty->size*8);
      for (p = ty->u.sym->u.idlist; *p; p++)
        print("\tMEMBER _%s VAL %d TYPE %d SCLASS %d SIZE %d\n",
              (*p)->name,
              (*p)->u.value,
              ty->size,
              C_MOE,
              ty->size*8);
      print("\tENDSTRUCTTAG\n");
      break;
    }
  default:
    assert(0);
  }
}
static void
dbxout(Type ty)
{
  ty = unqual(ty);
  if (!ty->x.printed) {
#if 0
    print(".stabs \"");
    if (ty->u.sym && !(isfunc(ty) || isarray(ty) || isptr(ty)))
      print("%s", ty->u.sym->name);
    print(":%c", isstruct(ty) || isenum(ty) ? 'T' : 't');
#endif
    emit_type(ty, 0);
#if 0
    print("\",%d,0,0,0\n", N_LSYM);
#endif
  }
}
static void
asgncode(Type ty, int lev)
{
  if (ty->x.marked || ty->x.typeno)
    return;
  ty->x.marked = 1;
  switch (ty->op)
    {
    case VOLATILE: case CONST: case VOLATILE+CONST:
      asgncode(ty->type, lev);
      ty->x.typeno = ty->type->x.typeno;
      break;
    case POINTER: case FUNCTION: case ARRAY:
      asgncode(ty->type, lev + 1);
      break;
    case VOID: case CHAR: case SHORT: case INT: case UNSIGNED:
    case FLOAT: case DOUBLE:
      break;
    case STRUCT: case UNION:
      {
        Field p;
        for (p = fieldlist(ty); p; p = p->link)
          asgncode(p->type, lev + 1);
      }
      /*FALLTHROUGH*/
    case ENUM:
      if (ty->x.typeno == 0)
        ty->x.typeno = ++ntypes;
      if (lev > 0 && (*ty->u.sym->name < '0' || *ty->u.sym->name > '9'))
        dbxout(ty);
      break;
    default:
      assert(0);
    }
}

static void
stabtype(Symbol p)
{
  if (p->type)
    if (p->sclass == 0)
      {
        asgncode(p->type, 0);
        dbxout(p->type);
      }
    else if (p->sclass == TYPEDEF)
      {
        type_info_t info;
        asgncode(p->type, 0);
        dbxout(p->type);
        gettypeinfo(p->type, &info);
        print("\tSYMBOL _%s VAL 0 TYPE %u SCLASS %d SIZE %d",
              p->name, info.typecode, C_TPDEF, p->type->size*8);
        if (info.tag)
          print(" TAG %s", tagname(info.tag));
        print("\n");
    }
}

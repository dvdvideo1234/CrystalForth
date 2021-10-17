typedef struct {
	unsigned char max_unaligned_load;
	void (*blkfetch) ARGS((int size, int off, int reg, int tmp));
	void (*blkstore) ARGS((int size, int off, int reg, int tmp));
	void (*blkloop)  ARGS((int dreg, int doff,
			       int sreg, int soff,
			       int size, int tmps[]));
	void (*_label) ARGS((Node));
	int (*_rule) ARGS((void*, int));
	short **_nts;
	void (*_kids) ARGS((Node, int, Node*));
	char **_opname;
	char *_arity;
	char **_string;
	char **_templates;
	char *_isinstruction;
	char **_ntname;
	void (*emit2) ARGS((Node));
	void (*doarg) ARGS((Node));
	void (*target) ARGS((Node));
	void (*clobber) ARGS((Node));
} Xinterface;
extern int     askregvar  ARGS((Symbol, Symbol));
extern void    blkcopy    ARGS((int, int, int,
                                int, int, int[]));
extern int     getregnum  ARGS((Node));
extern int     mayrecalc  ARGS((Node));
extern int     mkactual   ARGS((int, int));
extern void    mkauto     ARGS((Symbol));
extern Symbol  mkreg      ARGS((char *, int, int, int));
extern Symbol  mkwildcard ARGS((Symbol *));
extern int     move       ARGS((Node));
extern int     notarget   ARGS((Node));
extern void    parseflags ARGS((int, char **));
extern int     range      ARGS((Node, int, int));
extern unsigned regloc    ARGS((Symbol));  /* omit */
extern void    rtarget    ARGS((Node, int, Symbol));
extern void    setreg     ARGS((Node, Symbol));
extern void    spill      ARGS((unsigned, int, Node));

extern int      argoffset, maxargoffset;
extern int      bflag, dflag;
extern int      dalign, salign;
extern int      framesize;
extern unsigned freemask[], usedmask[];
extern int      offset, maxoffset;
extern Symbol   rmap[];
extern int      swap;
extern unsigned tmask[], vmask[];
typedef struct {
	unsigned listed:1;
	unsigned registered:1;
	unsigned emitted:1;
	unsigned copy:1;
	unsigned equatable:1;
	unsigned mayrecalc:1;
	void *state;
	short inst;
	Node kids[3];
	Node prev, next;
	Node prevuse;
	short argno;
	int m_mode;
	int m_tmp;
} Xnode;
enum { MODE_TMP, MODE_TMP_INDIR, MODE_SYM, MODE_SYM_INDIR, MODE_LIT };
typedef struct {
	Symbol vbl;
	short set;
	short number;
	unsigned mask;
} *Regnode;
enum { IREG=0, FREG=1 };
typedef struct {
	char *name;
	unsigned int eaddr;  /* omit */
	int offset;
	Node lastuse;
	int usecount;
	Regnode regnode;
	Symbol *wildcard;
} Xsymbol;
enum { RX=2 };
typedef struct {
	int offset;
	unsigned freemask[2];
} Env;

#define BURG_MAX SHRT_MAX

enum { VREG=(38<<4) };

/* Exported for the front end */
extern void             blockbeg        ARGS((Env *));
extern void             blockend        ARGS((Env *));
extern void             emit            ARGS((Node));
extern Node             gen             ARGS((Node));

/* Why are these exported? */
extern unsigned         emitasm         ARGS((Node, int));
extern unsigned         emitbin         ARGS((Node, int));

#ifdef NDEBUG
#define debug(f,x)
#else
#define debug(f,x) if(f)x
#endif

/* TSEPOS 2 11 1 */
#include "c.h"

#define readsreg(p) \
	(generic((p)->op)==INDIR && (p)->kids[0]->op==VREG+P)

#define relink(a, b) ((b)->x.prev = (a), (a)->x.next = (b))

int offset;

int maxoffset;

int framesize;
int argoffset;

int maxargoffset;

int dalign, salign;
int bflag = 0;  /* omit */
int dflag = 0;

int swap;

unsigned (*emitter) ARGS((Node, int)) = emitasm;
static char NeedsReg[] = {
	0,                      /* unused */
	1,                      /* CNST */
	0, 0,                   /* ARG ASGN */
	1,                      /* INDIR  */
	1, 1, 1, 1,             /* CVC CVD CVF CVI */
	1, 1, 1, 1,             /* CVP CVS CVU NEG */
	1,                      /* CALL */
	1,                      /* LOAD */
	0,                      /* RET */
	1, 1, 1,                /* ADDRG ADDRF ADDRL */
	1, 1, 1, 1, 1,          /* ADD SUB LSH MOD RSH */
	1, 1, 1, 1,             /* BAND BCOM BOR BXOR */
	1, 1,                   /* DIV MUL */
	0, 0, 0, 0, 0, 0,       /* EQ GE GT LE LT NE */
	0, 0,                   /* JUMP LABEL   */
};
Symbol rmap[16];
Node head;

unsigned freemask[2];
unsigned usedmask[2];
unsigned tmask[2];
unsigned vmask[2];
static Symbol   askfixedreg     ARGS((Symbol));
static Symbol   askreg          ARGS((Symbol, unsigned*));
static void     blkunroll       ARGS((int, int, int, int, int, int, int[]));
static void     docall          ARGS((Node));
static void     dumpcover       ARGS((Node, int, int));
static void     dumpregs        ARGS((char *, char *, char *));
static void     dumprule        ARGS((int));
static void     dumptree        ARGS((Node));
static void     genreload       ARGS((Node, Symbol, int));
static void     genspill        ARGS((Symbol, Node, Symbol));
static Symbol   getreg          ARGS((Symbol, unsigned*, Node));
static int      getrule         ARGS((Node, int));
static void     linearize       ARGS((Node, Node));
static int      moveself        ARGS((Node));
static void     prelabel        ARGS((Node));
static Node*    prune           ARGS((Node, Node*));
static void     putreg          ARGS((Symbol));
static void     ralloc          ARGS((Node));
static void     reduce          ARGS((Node, int));
static int      reprune         ARGS((Node*, int, int, Node));
static int      requate         ARGS((Node));
static Node     reuse           ARGS((Node, int));
static void     rewrite         ARGS((Node));
static Symbol   spillee         ARGS((Symbol, Node));
static void     spillr          ARGS((Symbol, Node));
static int      trashes         ARGS((Node, Node));
static int      uses            ARGS((Node, unsigned));

Symbol mkreg(fmt, n, mask, set) char *fmt; {
	Symbol p;

	NEW0(p, PERM);
	p->x.name = stringf(fmt, n);
	NEW0(p->x.regnode, PERM);
	p->x.regnode->number = n;
	p->x.regnode->mask = mask<<n;
	p->x.regnode->set = set;
	return p;
}
Symbol mkwildcard(syms) Symbol *syms; {
	Symbol p;

	NEW0(p, PERM);
	p->x.name = "wildcard";
	p->x.wildcard = syms;
	return p;
}
void mkauto(p) Symbol p; {
	assert(p->sclass == AUTO);
	offset = roundup(offset + p->type->size, p->type->align);
	p->x.offset = -offset;
	p->x.name = stringd(-offset);
}
void blockbeg(e) Env *e; {
	e->offset = offset;
	e->freemask[IREG] = freemask[IREG];
	e->freemask[FREG] = freemask[FREG];
}
void blockend(e) Env *e; {
	if (offset > maxoffset)
		maxoffset = offset;
	offset = e->offset;
	freemask[IREG] = e->freemask[IREG];
	freemask[FREG] = e->freemask[FREG];
}
int mkactual(align, size) {
	int n = roundup(argoffset, align);

	argoffset = n + size;
	return n;
}
static void docall(p) Node p; {
	p->syms[0] = intconst(argoffset);
	if (argoffset > maxargoffset)
		maxargoffset = argoffset;
	argoffset = 0;
}
void blkcopy(dreg, doff, sreg, soff, size, tmp) int tmp[]; {
	assert(size >= 0);
	if (size == 0)
		return;
	else if (size <= 2)
		blkunroll(size, dreg, doff, sreg, soff, size, tmp);
	else if (size == 3) {
		blkunroll(2, dreg, doff,   sreg, soff,	 2, tmp);
		blkunroll(1, dreg, doff+2, sreg, soff+2, 1, tmp);
	}
	else if (size <= 16) {
		blkunroll(4, dreg, doff, sreg, soff, size&~3, tmp);
		blkcopy(dreg, doff+(size&~3),
	                sreg, soff+(size&~3), size&3, tmp);
	}
	else
		(*IR->x.blkloop)(dreg, doff, sreg, soff, size, tmp);
}
static void blkunroll(k, dreg, doff, sreg, soff, size, tmp)
int tmp[]; {
	int i;

	assert(IR->x.max_unaligned_load);
	if (k > IR->x.max_unaligned_load
	&& (k > salign || k > dalign))
		k = IR->x.max_unaligned_load;
	for (i = 0; i+k < size; i += 2*k) {
		(*IR->x.blkfetch)(k, soff+i,   sreg, tmp[0]);
		(*IR->x.blkfetch)(k, soff+i+k, sreg, tmp[1]);
		(*IR->x.blkstore)(k, doff+i,   dreg, tmp[0]);
		(*IR->x.blkstore)(k, doff+i+k, dreg, tmp[1]);
	}
	if (i < size) {
		(*IR->x.blkfetch)(k, i+soff, sreg, tmp[0]);
		(*IR->x.blkstore)(k, i+doff, dreg, tmp[0]);
	}
}
void parseflags(argc, argv) int argc; char *argv[]; {
	int i;

	for (i = 0; i < argc; i++)
		if (strcmp(argv[i], "-d") == 0)
			dflag = 1;
		else if (strcmp(argv[i], "-b") == 0)	/* omit */
			bflag = 1;			/* omit */
}
static int getrule(p, nt) Node p; {
	int rulenum;

	assert(p);
	rulenum = (*IR->x._rule)(p->x.state, nt);
	assert(rulenum);
	return rulenum;
}
static void reduce(p, nt) Node p; {
	int rulenum, i;
	short *nts;
	Node kids[10];

	p = reuse(p, nt);
	rulenum = getrule(p, nt);
	nts = IR->x._nts[rulenum];
	(*IR->x._kids)(p, rulenum, kids);
	for (i = 0; nts[i]; i++)
		reduce(kids[i], nts[i]);
	if (IR->x._isinstruction[rulenum]) {
		assert(p->x.inst == 0 || p->x.inst == nt);
		p->x.inst = nt;
		if (p->syms[RX] && p->syms[RX]->temporary) {
			p->syms[RX]->x.usecount++;
			debug(dflag, fprint(2, "(using %s)\n", p->syms[RX]->name));
		}
	}
}
static Node reuse(p, nt) Node p; {
	struct _state {
		short cost[1];
	};
	Symbol r = p->syms[RX];

	if (generic(p->op) == INDIR && p->kids[0]->op == VREG+P
	&& r->u.t.cse && p->x.mayrecalc
	&& ((struct _state*)r->u.t.cse->x.state)->cost[nt] == 0)
		return r->u.t.cse;
	else
		return p;
}

int mayrecalc(p) Node p; {
	Node q;

	assert(p && p->syms[RX]);
	if (!p->syms[RX]->u.t.cse)
		return 0;
	for (q = head; q && q->x.listed; q = q->link)
		if (generic(q->op) == ASGN
		&& trashes(q->kids[0], p->syms[RX]->u.t.cse))
			return 0;
	p->x.mayrecalc = 1;
	return 1;
}
static int trashes(p, q) Node p, q; {
	assert(p);
	if (!q)
		return 0;
	else if (p->op == q->op && p->syms[0] == q->syms[0])
		return 1;
	else
		return trashes(p, q->kids[0]) || trashes(p, q->kids[1]);
}
static Node *prune(p, pp) Node p, pp[]; {
	if (p == NULL)
		return pp;
	p->x.kids[0] = p->x.kids[1] = NULL;
	if (p->x.inst == 0)
		return prune(p->kids[1], prune(p->kids[0], pp));
	else if (p->syms[RX] && p->syms[RX]->temporary
	&& p->syms[RX]->x.usecount < 2) {
		p->x.inst = 0;
		debug(dflag, fprint(2, "(clobbering %s)\n", p->syms[RX]->name));
		return prune(p->kids[1], prune(p->kids[0], pp));
	}
	else {
		prune(p->kids[1], prune(p->kids[0], &p->x.kids[0]));
		*pp = p;
		return pp + 1;
	}
}

#define ck(i) return (i) ? 0 : BURG_MAX

int range(p, lo, hi) Node p; {
	Symbol s = p->syms[0];

	switch (p->op) {
	case ADDRFP:  ck(s->x.offset >= lo && s->x.offset <= hi);
	case ADDRLP:  ck(s->x.offset >= lo && s->x.offset <= hi);
	case CNSTC:   ck(s->u.c.v.sc >= lo && s->u.c.v.sc <= hi);
	case CNSTI:   ck(s->u.c.v.i  >= lo && s->u.c.v.i  <= hi);
	case CNSTS:   ck(s->u.c.v.ss >= lo && s->u.c.v.ss <= hi);
	case CNSTU:   ck(s->u.c.v.u  >= lo && s->u.c.v.u  <= hi);
	case CNSTP:   ck(s->u.c.v.p  == 0  && lo <= 0 && hi >= 0);
	}
	return BURG_MAX;
}
static void dumptree(p) Node p; {
	fprint(2, "%s(", IR->x._opname[p->op]);
	if (IR->x._arity[p->op] == 0 && p->syms[0])
		fprint(2, "%s", p->syms[0]->name);
	else if (IR->x._arity[p->op] == 1)
		dumptree(p->kids[0]);
	else if (IR->x._arity[p->op] == 2) {
		dumptree(p->kids[0]);
		fprint(2, ", ");
		dumptree(p->kids[1]);
	}
	fprint(2, ")");
}
static void dumpcover(p, nt, indent) Node p; {
	int rulenum, i;
	short *nts;
	Node kids[10];

	p = reuse(p, nt);
	rulenum = getrule(p, nt);
	nts = IR->x._nts[rulenum];
	fprint(2, "dumpcover(%x) = ", p);
	for (i = 0; i < indent; i++)
		fprint(2, " ");
	dumprule(rulenum);
	(*IR->x._kids)(p, rulenum, kids);
	for (i = 0; nts[i]; i++)
		dumpcover(kids[i], nts[i], indent+1);
}

static void dumprule(rulenum) {
	assert(rulenum);
	fprint(2, "%s / %s", IR->x._string[rulenum],
		IR->x._templates[rulenum]);
	if (!IR->x._isinstruction[rulenum])
		fprint(2, "\n");
}
unsigned emitasm(p, nt) Node p; {
	int rulenum;
	short *nts;
	char *fmt;
	Node kids[10];

	p = reuse(p, nt);
	rulenum = getrule(p, nt);
	nts = IR->x._nts[rulenum];
	fmt = IR->x._templates[rulenum];
	assert(fmt);
	if (IR->x._isinstruction[rulenum] && p->x.emitted)
		outs(p->syms[RX]->x.name);
	else if (*fmt == '#')
		(*IR->x.emit2)(p);
	else {
		if (*fmt == '?') {
			fmt++;
			assert(p->kids[0]);
			if (p->syms[RX] == p->kids[0]->syms[RX])
				while (*fmt++ != '\n')
					;
		}
		for ((*IR->x._kids)(p, rulenum, kids); *fmt; fmt++)
		        if (*fmt == '\\')
			  {
			    fmt++;
			    if (*fmt)
			      *bp++ = *fmt;
			  }
			else if (*fmt != '%')
				*bp++ = *fmt;
			else if (*++fmt == 'F')
				print("%d", framesize);
			else if (*fmt >= '0' && *fmt <= '9')
				emitasm(kids[*fmt - '0'], nts[*fmt - '0']);
			else if (*fmt >= 'a' && *fmt < 'a' + NELEMS(p->syms))
				outs(p->syms[*fmt - 'a']->x.name);
			else
				*bp++ = *fmt;
	}
	return 0;
}
void emit(p) Node p; {
	for (; p; p = p->x.next) {
		if (p->x.equatable && requate(p) || moveself(p))
			;
		else
			(*emitter)(p, p->x.inst);
		p->x.emitted = 1;
	}
}
static int moveself(p) Node p; {
	return p->x.copy
	&& p->syms[RX]->x.name == p->x.kids[0]->syms[RX]->x.name;
}
int move(p) Node p; {
	p->x.copy = 1;
	return 1;
}
static int requate(q) Node q; {
	Symbol src = q->x.kids[0]->syms[RX];
	Symbol tmp = q->syms[RX];
	Node p;
	int n = 0;

	debug(dflag, fprint(2, "(requate(%x): tmp=%s src=%s)\n", q, tmp->x.name, src->x.name));
	for (p = q->x.next; p; p = p->x.next)
		if (p->syms[RX] == src && !moveself(p) && !readsreg(p)) {
			debug(dflag, fprint(2, "(requate arm 1)\n"));
			return 0;
		}
		else if (generic(p->op) == CALL && p->x.next) {
			debug(dflag, fprint(2, "(requate arm 2)\n"));
			return 0;
		}
		else if (p->op == LABEL+V && p->x.next) {
			debug(dflag, fprint(2, "(requate arm 3)\n"));
			return 0;
		}
		else if (p->syms[RX] == tmp && readsreg(p)) {
			debug(dflag, fprint(2, "(requate arm 4)\n"));
			n++;
		}
		else if (p->syms[RX] == tmp) {
			debug(dflag, fprint(2, "(requate arm 5)\n"));
			break;
		}
	debug(dflag, fprint(2, "(requate arm 6)\n"));
	assert(n > 0);
	for (p = q->x.next; p; p = p->x.next)
		if (p->syms[RX] == tmp && readsreg(p)) {
			p->syms[RX] = src;
			if (--n <= 0)
				break;
		}
	return 1;
}
static void prelabel(p) Node p; {
	if (p == NULL)
		return;
	prelabel(p->kids[0]);
	prelabel(p->kids[1]);
	if (NeedsReg[opindex(p->op)])
		setreg(p, rmap[optype(p->op)]);
	switch (generic(p->op)) {
	case ADDRF: case ADDRL:
		if (p->syms[0]->sclass == REGISTER)
			p->op = VREG+P;
		break;
	case INDIR:
		if (p->kids[0]->op == VREG+P)
			setreg(p, p->kids[0]->syms[0]);
		break;
	case ASGN:
		if (p->kids[0]->op == VREG+P) {
			debug(dflag, fprint(2, "(cse=%x)\n", p->kids[0]->syms[0]->u.t.cse));
			rtarget(p, 1, p->kids[0]->syms[0]);
		}
		break;
	}
	(IR->x.target)(p);
}
void setreg(p, r) Node p; Symbol r; {
	p->syms[RX] = r;
}
void rtarget(p, n, r) Node p; Symbol r; {
	Node q = p->kids[n];

	assert(q);
	assert(r->sclass == REGISTER || r->x.wildcard == 0);
	assert(q->syms[RX]);
	if (q->syms[RX]->x.wildcard == 0) {
		q = newnode(LOAD + optype(q->op),
			q, NULL, q->syms[0]);
		if (r->u.t.cse == p->kids[n])
			r->u.t.cse = q;
		p->kids[n] = p->x.kids[n] = q;
		q->x.kids[0] = q->kids[0];
	}
	setreg(q, r);
	debug(dflag, fprint(2, "(targeting %x->x.kids[%d]=%x to %s)\n", p, n, p->kids[n], r->x.name));
}
static void rewrite(p) Node p; {
	assert(p->x.inst == 0);
	prelabel(p);
	debug(dflag, dumptree(p));
	debug(dflag, fprint(2, "\n"));
	(*IR->x._label)(p);
	debug(dflag, dumpcover(p, 1, 0));
	reduce(p, 1);
}
Node gen(forest) Node forest; {
	int i;
	struct node sentinel;
	Node dummy, p;

	head = forest;
	for (p = forest; p; p = p->link) {
		assert(p->count == 0);
		if (generic(p->op) == CALL)
			docall(p);
		else if (   generic(p->op) == ASGN
		&& generic(p->kids[1]->op) == CALL)
			docall(p->kids[1]);
		else if (generic(p->op) == ARG)
			(*IR->x.doarg)(p);
		rewrite(p);
		p->x.listed = 1;
	}
	for (p = forest; p; p = p->link)
		prune(p, &dummy);
	relink(&sentinel, &sentinel);
	for (p = forest; p; p = p->link)
		linearize(p, &sentinel);
	forest = sentinel.x.next;
	assert(forest);
	sentinel.x.next->x.prev = NULL;
	sentinel.x.prev->x.next = NULL;
	for (p = forest; p; p = p->x.next)
		for (i = 0; i < NELEMS(p->x.kids) && p->x.kids[i]; i++) {
			assert(p->x.kids[i]->syms[RX]);
			if (p->x.kids[i]->syms[RX]->temporary) {
				p->x.kids[i]->x.prevuse =
					p->x.kids[i]->syms[RX]->x.lastuse;
				p->x.kids[i]->syms[RX]->x.lastuse = p->x.kids[i];
			}
		}
	for (p = forest; p; p = p->x.next)
		if (p->x.copy && p->x.kids[0]->syms[RX]->u.t.cse) {
			Symbol dst = p->syms[RX];
			Symbol temp = p->x.kids[0]->syms[RX];
			Node q;

			assert(temp->x.lastuse);
			for (q = temp->u.t.cse; q; q = q->x.next)
				if (p != q && dst == q->syms[RX]
				|| (q->op == LABELV || q->op == JUMPV || generic(q->op)==RET ||
				    generic(q->op)==EQ || generic(q->op)==NE || generic(q->op)==LE ||
				    generic(q->op)==LT || generic(q->op)==GE || generic(q->op)==GT ||
				    (generic(q->op) == CALL && dst->sclass != REGISTER)))
					break;
			if (!q)
				for (q = temp->x.lastuse; q; q = q->x.prevuse)
					q->syms[RX] = dst;
		}
	for (p = forest; p; p = p->x.next) {
		ralloc(p);
		if (p->x.listed && NeedsReg[opindex(p->op)]
		&& rmap[optype(p->op)]) {
			assert(generic(p->op) == CALL || generic(p->op) == LOAD);
			putreg(p->syms[RX]);
		}
	}
	return forest;
}
int notarget(p) Node p; {
	return p->syms[RX]->x.wildcard ? 0 : BURG_MAX;
}
static void putreg(r) Symbol r; {
	assert(r && r->x.regnode);
	freemask[r->x.regnode->set] |= r->x.regnode->mask;
	debug(dflag, dumpregs("(freeing %s)\n", r->x.name, NULL));
}
static Symbol askfixedreg(s) Symbol s; {
	Regnode r = s->x.regnode;
	int n = r->set;

	if (r->mask&~freemask[n])
		return NULL;
	else {
		freemask[n] &= ~r->mask;
		usedmask[n] |=  r->mask;
		return s;
	}
}
static Symbol askreg(rs, rmask) Symbol rs; unsigned rmask[]; {
	int i;

	if (rs->x.wildcard == NULL)
		return askfixedreg(rs);
	for (i = 31; i >= 0; i--) {
		Symbol r = rs->x.wildcard[i];
		if (r && !(r->x.regnode->mask&~rmask[r->x.regnode->set])
		&& askfixedreg(r))
			return r;
	}
	return NULL;
}

static Symbol getreg(s, mask, p)
Symbol s; unsigned mask[]; Node p; {
	Symbol r = askreg(s, mask);
	if (r == NULL) {
		r = spillee(s, p);
		assert(r);
		spill(r->x.regnode->mask, r->x.regnode->set, p);
		r = askreg(s, mask);
		assert(r);
	}
	assert(r->x.regnode);
	r->x.regnode->vbl = NULL;
	return r;
}
int askregvar(p, regs) Symbol p, regs; {
	Symbol r;

	assert(p);
	if (p->sclass != REGISTER)
		return 0;
	else if (!isscalar(p->type)) {
		p->sclass = AUTO;
		return 0;
	}
	else if (p->temporary && p->u.t.cse) {
		p->x.name = "?";
		return 1;
	}
	else if (r = askreg(regs, vmask)) {
		p->x.regnode = r->x.regnode;
		p->x.regnode->vbl = p;
		p->x.name = r->x.name;
		debug(dflag, dumpregs("(allocating %s to symbol %s)\n", p->x.name, p->name));
		return 1;
	}
	else {
		p->sclass = AUTO;
		return 0;
	}
}
static void linearize(p, next) Node next, p; {
	int i;

	for (i = 0; i < NELEMS(p->x.kids) && p->x.kids[i]; i++)
		linearize(p->x.kids[i], next);
	relink(next->x.prev, p);
	relink(p, next);
	debug(dflag, fprint(2, "(listing %x)\n", p));
}
static void ralloc(p) Node p; {
	int i;
	unsigned mask[2];

	mask[0] = tmask[0];
	mask[1] = tmask[1];
	assert(p);
	debug(dflag, fprint(2, "(rallocing %x)\n", p));
	for (i = 0; i < NELEMS(p->x.kids) && p->x.kids[i]; i++) {
		Node kid = p->x.kids[i];
		Symbol r = kid->syms[RX];
		assert(r && kid->x.registered);
		if (r->sclass != REGISTER && r->x.lastuse == kid)
			putreg(r);
	}
	if (!p->x.registered && NeedsReg[opindex(p->op)]
	&& rmap[optype(p->op)]) {
		Symbol sym = p->syms[RX], set = sym;
		assert(sym);
		if (sym->temporary && sym->u.t.cse)
			set = rmap[optype(p->op)];
		assert(set);
		if (set->sclass != REGISTER) {
			Symbol r;
			if (*IR->x._templates[getrule(p, p->x.inst)] == '?')
				for (i = 1; i < NELEMS(p->x.kids) && p->x.kids[i]; i++) {
					Symbol r = p->x.kids[i]->syms[RX];
					assert(p->x.kids[i]->x.registered && r && r->x.regnode);
					mask[r->x.regnode->set] &= ~r->x.regnode->mask;
				}
			r = getreg(set, mask, p);
			if (sym->temporary && sym->u.t.cse) {
				Node q;
				r->x.lastuse = sym->x.lastuse;
				for (q = sym->x.lastuse; q; q = q->x.prevuse) {
					q->syms[RX] = r;
					q->x.registered = 1;
					if (q->x.copy)
						q->x.equatable = 1;
				}
			} else {
				p->syms[RX] = r;
				r->x.lastuse = p;
			}
			debug(dflag, dumpregs("(allocating %s to node %x)\n", r->x.name, (char *) p));
		}
	}
	p->x.registered = 1;
	(*IR->x.clobber)(p);
}
static Symbol spillee(set, here) Node here; Symbol set; {
	Symbol bestreg = NULL;
	int bestdist = -1, i;

	assert(set);
	if (!set->x.wildcard)
		return set;
	for (i = 31; i >= 0; i--) {
		Symbol ri = set->x.wildcard[i];
		if (ri && ri->x.regnode->mask&tmask[ri->x.regnode->set]) {
			Regnode rn = ri->x.regnode;
			Node q = here;
			int dist = 0;
			for (; q && !uses(q, rn->mask); q = q->x.next)
				dist++;
			if (q && dist > bestdist) {
				bestdist = dist;
				bestreg = ri;
			}
		}
	}
	return bestreg;
}
static int uses(p, mask) Node p; unsigned mask; {
	int i;
	Node q;

	for (i = 0; i < NELEMS(p->x.kids) && (q = p->x.kids[i]); i++)
		if (q->x.registered && mask&q->syms[RX]->x.regnode->mask)
			return 1;
	return 0;
}
static void spillr(r, here) Symbol r; Node here; {
	int i;
	Node p = r->x.lastuse;
	Symbol tmp = newtemp(AUTO, optype(p->op));
	assert(p);
	while (p->x.prevuse) {
		assert(r == p->syms[RX]);
		p = p->x.prevuse;
	}
	assert(p->x.registered && !readsreg(p));
	genspill(r, p, tmp);
	for (p = here->x.next; p; p = p->x.next)
		for (i = 0; i < NELEMS(p->x.kids) && p->x.kids[i]; i++) {
			Node k = p->x.kids[i];
			if (k->x.registered && k->syms[RX] == r)
				genreload(p, tmp, i);
		}
	putreg(r);
}
static void genspill(r, last, tmp) Symbol r, tmp; Node last; {
	Node p, q;
	Symbol s;
	unsigned ty;

	debug(dflag, fprint(2, "(spilling %s to local %s)\n", r->x.name, tmp->x.name));
	debug(dflag, fprint(2, "(genspill: "));
	debug(dflag, dumptree(last));
	debug(dflag, fprint(2, ")\n"));
	ty = optype(last->op);
	if (ty == U)
		ty = I;
	NEW0(s, FUNC);
	s->sclass = REGISTER;
	s->x.name = r->x.name;
	s->x.regnode = r->x.regnode;
	s->x.regnode->vbl = s;
	q = newnode(ADDRLP, NULL, NULL, s);
	q = newnode(INDIR + ty, q, NULL, NULL);
	p = newnode(ADDRLP, NULL, NULL, tmp);
	p = newnode(ASGN + ty, p, q, NULL);
	rewrite(p);
	prune(p, &q);
	q = last->x.next;
	linearize(p, q);
	for (p = last->x.next; p != q; p = p->x.next) {
		ralloc(p);
		assert(!p->x.listed || !NeedsReg[opindex(p->op)] || !rmap[optype(p->op)]);
	}
}

static void genreload(p, tmp, i) Node p; Symbol tmp; {
	Node q;
	int ty;

	debug(dflag, fprint(2, "(replacing %x with a reload from %s)\n", p->x.kids[i], tmp->x.name));
	debug(dflag, fprint(2, "(genreload: "));
	debug(dflag, dumptree(p->x.kids[i]));
	debug(dflag, fprint(2, ")\n"));
	ty = optype(p->x.kids[i]->op);
	if (ty == U)
		ty = I;
	q = newnode(ADDRLP, NULL, NULL, tmp);
	p->x.kids[i] = newnode(INDIR + ty, q, NULL, NULL);
	rewrite(p->x.kids[i]);
	prune(p->x.kids[i], &q);
	reprune(&p->kids[1], reprune(&p->kids[0], 0, i, p), i, p);
	prune(p, &q);
	linearize(p->x.kids[i], p);
}
static int reprune(pp, k, n, p) Node p, *pp; {
	Node q = *pp;

	if (q == NULL || k > n)
		return k;
	else if (q->x.inst == 0)
		return reprune(&q->kids[1],
			reprune(&q->kids[0], k, n, p), n, p);
	else if (k == n) {
		debug(dflag, fprint(2, "(reprune changes %x from %x to %x)\n", pp, *pp, p->x.kids[n]));
		*pp = p->x.kids[n];
		return k + 1;
	} else
		return k + 1;
}
void spill(mask, n, here) unsigned mask; Node here; {
	int i;
	Node p;

	usedmask[n] |= mask;
	if (mask&~freemask[n])
		for (p = here; p; p = p->x.next)
			for (i = 0; i < NELEMS(p->x.kids) && p->x.kids[i]; i++) {
				Symbol r = p->x.kids[i]->syms[RX];
				if (p->x.kids[i]->x.registered && r->x.regnode->set == n
				&& r->x.regnode->mask&mask)
					spillr(r, here);
			}
}
static void dumpregs(msg, a, b) char *a, *b, *msg; {
	fprint(2, msg, a, b);
	fprint(2, "(free[0]=%x)\n", freemask[0]);
	fprint(2, "(free[1]=%x)\n", freemask[1]);
}

int getregnum(p) Node p; {
	assert(p && p->syms[RX] && p->syms[RX]->x.regnode);
	return p->syms[RX]->x.regnode->number;
}


unsigned regloc(p) Symbol p; {
	assert(p && p->sclass == REGISTER && p->sclass == REGISTER && p->x.regnode);
	return p->x.regnode->set<<8 | p->x.regnode->number;
}


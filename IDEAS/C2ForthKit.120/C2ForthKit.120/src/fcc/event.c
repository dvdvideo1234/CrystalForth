/* TSEPOS 2 11 1 */
#include "c.h"

struct entry {
	Apply func;
	void *cl;
};

Events events;

void attach(func, cl, list) Apply func; void *cl; List *list; {
	struct entry *p;

	NEW(p, PERM);
	p->func = func;
	p->cl = cl;
	*list = append(p, *list);
}
void apply(list, arg1, arg2) List list; void *arg1, *arg2; {
	if (list) {
		List lp = list;
		do {
			struct entry *p = lp->x;
			(*p->func)(p->cl, arg1, arg2);
			lp = lp->link;
		} while (lp != list);
	}
}

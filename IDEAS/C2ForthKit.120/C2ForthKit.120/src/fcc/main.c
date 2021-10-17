/* TSEPOS 2 11 1 */
#include "c.h"

static void compile ARGS((char *));
static int doargs ARGS((int, char **));
static void emitYYnull ARGS((void));
static void typestab ARGS((Symbol, void *));

Interface *IR = NULL;

static char *infile, *outfile;

/*!!! PLC: */
int Aflag = 2;                  /* >= 0 if -A specified */
#if 0
int Aflag;                      /* >= 0 if -A specified */
#endif

int Pflag;                      /* != 0 if -P specified */
int glevel;                     /* == [0-9] if -g[0-9] specified */
int xref;                       /* != 0 for cross-reference data */
Symbol YYnull;                  /* symbol for _YYnull if -n specified */

int main(argc, argv) char *argv[]; {
        {

                int i, j;

                /* Default. */
                IR = bindings[0].ir;

                for (i = argc - 1; i > 0; i--)
                        if (strncmp(argv[i], "-target=", 8) == 0)
                                break;
                if (i > 0) {
                        for (j = 0; bindings[j].name; j++)
                                if (strcmp(&argv[i][8], bindings[j].name) == 0)
                                        break;
                        if (bindings[j].ir)
                                IR = bindings[j].ir;
                        else {
                                fprint(2, "%s: unknown target `%s'\n", argv[0],
                                        &argv[i][8]);
                                exit(1);
                        }
                }
        }
        if (!IR) {
                int i;
                fprint(2, "%s: must specify one of\n", argv[0]);
                for (i = 0; bindings[i].name; i++)
                        fprint(2, "\t-target=%s\n", bindings[i].name);
                exit(1);
        }
        typeInit();
        argc = doargs(argc, argv);
        if (infile && strcmp(infile, "-") != 0)
                if ((infd = open(infile, 0)) < 0) {
                        fprint(2, "%s: can't read `%s'\n",
                                argv[0], infile);
                        exit(1);
                }
        if (outfile && strcmp(outfile, "-") != 0)
                if ((outfd = creat(outfile, 0666)) < 0) {
                        fprint(2, "%s: can't write `%s'\n",
                                argv[0], outfile);
                        exit(1);
                }
        inputInit();
        outputInit();
        t = gettok();
        (*IR->progbeg)(argc, argv);
        if (glevel && IR->stabinit)
                (*IR->stabinit)(firstfile, argc, argv);
        program();
        if (events.end)
                apply(events.end, NULL, NULL);
        memset(&events, 0, sizeof events);
        emitYYnull();
        if (glevel || xref) {
                Symbol symroot = NULL;
                Coordinate src;
                foreach(types,       GLOBAL, typestab, &symroot);
                foreach(identifiers, GLOBAL, typestab, &symroot);
                src.file = firstfile;
                src.x = 0;
                src.y = lineno;
                if ((glevel > 2 || xref) && IR->stabend)
                        (*IR->stabend)(&src, symroot,
                                xltoa(&loci,    PERM),
                                xltoa(&symbols, PERM), NULL);
                else if (IR->stabend)
                        (*IR->stabend)(&src, NULL, NULL, NULL, NULL);
        }
        finalize();
        (*IR->progend)();
        outflush();
        close(infd);
        close(outfd);
        deallocate(PERM);
        return errcnt > 0;
}
/* compile - compile str */
static void compile(str) char *str; {
        inputstring(str);
        t = gettok();
        program();
}

/* doargs - process program arguments, removing top-half arguments from argv */
static int doargs(argc, argv) char *argv[]; {
        int i, j, x;

        for (i = j = 1; i < argc; i++)
                if (strcmp(argv[i], "-g") == 0)
                        glevel = 2;
                else if (strncmp(argv[i], "-g", 2) == 0
                && argv[i][2] && argv[i][2] >= '0' && argv[i][2] <= '9') {
                        glevel = argv[i][2] - '0';
                        /* if (glevel >= 4)
                                IR->stabinit = cdbstabinit; */
                } else if (strcmp(argv[i], "-x") == 0)
                        xref++;
                else if (strcmp(argv[i], "-A") == 0)
                        Aflag++;
                else if (strcmp(argv[i], "-P") == 0)
                        Pflag++;
                else if (strcmp(argv[i], "-w") == 0)
                        wflag++;
                else if (strcmp (argv[i], "-b")    == 0
                ||       strcmp (argv[i], "-C")    == 0
                ||       strncmp(argv[i], "-a", 2) == 0)
                        profInit(argv[i]);
                else if (strcmp(argv[i], "-n") == 0) {
                        if (!YYnull) {
                                YYnull = install(string("_YYnull"), &globals, GLOBAL, PERM);
                                YYnull->type = ftype(voidtype, inttype);
                                YYnull->sclass = STATIC;
                                (*IR->defsymbol)(YYnull);
                        }
                } else if (strncmp(argv[i], "-target=", 8) == 0)
                        ;
                else if (strncmp(argv[i], "-t", 2) == 0)
                        traceInit(&argv[i][2]);
                else if (strcmp(argv[i], "-V") == 0) {

/* Added by PLC. */
                        extern char *pic_release,*pic_copyright;
                        fprint(2, "PRACTICAL C Compiler - Release %s\n",pic_release);
                        fprint(2, "%s\n",pic_copyright);
/* Removed by PLC. */
#ifdef PLC
                        int i;
                        fprint(2, "%s %s targets:\n", argv[0], rcsid);
                        for (i = 0; bindings[i].name; i++)
                                fprint(2, "\t%s%s\n", bindings[i].name,
                                        IR == bindings[i].ir ? "*" : "");
#endif
                } else if (strncmp(argv[i], "-s", 2) == 0)
                        density = strtod(&argv[i][2], NULL);
                else if (strncmp(argv[i], "-e", 2) == 0) {
                        if ((x = strtol(&argv[i][2], NULL, 0)) > 0)
                                errlimit = x;
                } else if (strcmp(argv[i], "-nodag") == 0)
                        IR->wants_dag = !IR->wants_dag;
                else if (strcmp(argv[i], "-") == 0 || *argv[i] != '-') {
                        if (infile == 0)
                                infile = argv[i];
                        else if (outfile == 0)
                                outfile = argv[i];
                        else
                                argv[j++] = argv[i];
                } else {
                        if (strcmp(argv[i], "-XP") == 0)
                                argv[i] = "-p";
                        else if (strncmp(argv[i], "-X", 2) == 0)
                                *++argv[i] = '-';
                        argv[j++] = argv[i];
                }
        argv[j] = 0;
        return j;
}

/* emitYYnull - compile definition for _YYnull, if referenced */
static void emitYYnull() {
        if (YYnull && YYnull->ref > 0.0) {
                Aflag = 0;
                YYnull->defined = 0;
                YYnull = 0;
                compile(stringf("static char *_YYfile = \"%s\";\n", file));
                compile("static void _YYnull(int line,...) {\nchar buf[200];\nsprintf(buf, \"null pointer dereferenced @%s:%d\\n\", _YYfile, line);\nwrite(2, buf, strlen(buf));\nabort();\n}\n");





        } else if (YYnull) {
                YYnull->sclass = EXTERN;
                YYnull->ref = 1;
        }
}

/* typestab - emit stab entries for p */
static void typestab(p, cl) Symbol p; void *cl; {
        if (*(Symbol *)cl == 0 && p->sclass && p->sclass != TYPEDEF)
                *(Symbol *)cl = p;
        if ((p->sclass == TYPEDEF || p->sclass == 0) && IR->stabtype)
                (*IR->stabtype)(p);
}

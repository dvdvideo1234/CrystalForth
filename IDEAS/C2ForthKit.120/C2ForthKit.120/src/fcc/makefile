# TSEPOS 29 13 28 #

CC      =       cl /nologo /Zp1 /ML /W3 /GX /O2 /D "WIN32" /D "_CONSOLE" /c

OBJS   =        ALLOC.obj               \
                DAG.obj                 \
                DECL.obj                \
                ENODE.obj               \
                FTHCODE.obj             \
                ERROR.obj               \
                EVENT.obj               \
                EXPR.obj                \
                GEN.obj                 \
                INIT.obj                \
                INPUT.obj               \
                LIST.obj                \
                MAIN.obj                \
                OUTPUT.obj              \
                PROF.obj                \
                PROFIO.obj              \
                RCCLEX.obj              \
                SIMP.obj                \
                STMT.obj                \
                STRING.obj              \
                SYM.obj                 \
                SYMBOLIC.obj            \
                TRACE.obj               \
                TREE.obj                \
                TYPES.obj

all:    ..\..\bin\fcc.exe

..\..\bin\fcc.exe:        $(OBJS)
                cl -o fcc.exe $(OBJS)
                move /y fcc.exe ..\..\bin\fcc.exe

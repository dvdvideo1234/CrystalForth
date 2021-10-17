# TSEPOS 29 13 28 #

CC      =       cl /nologo /Zp1 /ML /W3 /GX /O2 /D "WIN32" /D "_CONSOLE" /c

OBJS    =       cpp.obj                 \
                eval.obj                \
                getopt.obj              \
                hideset.obj             \
                include.obj             \
                cpplex.obj              \
                macro.obj               \
                nlist.obj               \
                tokens.obj              \
                unix.obj

all:    ..\..\bin\cpp.exe

..\..\bin\cpp.exe:        $(OBJS)
                cl -o cpp.exe $(OBJS)
                move /y cpp.exe ..\..\bin\cpp.exe

# TSEPOS 13 19 12 #

BINDIR  =       ..\bin
INCDIR  =       ..\include

CPP     =       $(BINDIR)\cpp
FCC     =       $(BINDIR)\fcc -l
CPPOPTS =       -Ddouble=int -DIEEE_ARITHMETIC -D__LCCC__ -D__PRACTICAL__ -D__STDC__ -I$(INCDIR) -I.

default:
        $(CPP) $(CPPOPTS) $(TARG).c $(TARG).i
        $(FCC) $(TARG).i $(TARG).cxx
        del $(TARG).i












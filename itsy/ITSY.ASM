
INCLUDE ITSY.IMC

DTOP = 10000  ;-1EA7H
DPTR = DTOP

LISTGEN = 01
DBG_FLAG= 01

IF LISTGEN
   DIVE EQU ENTRYB
ELSE 
   DIVE EQU DUCK
ENDIF

; REGISTER usage
top = Bx  ; AX DATA STACK TOP REGISTER
ip  = SI  ; BX INSTRUCTION POINTER
dsp = BP  ; SI DATA STACK POINTER
rsp = sp  ; SP RETURN STACK POINTER
NXT   EQU PW [DSP]
topL= BL  ; AX DATA STACK TOP REGISTER
topH= BH  ; AX DATA STACK TOP REGISTER
wA  = di  ; DI WORK REGISTER
W   = AX
WL  = AL
WH  = AH
ar  = DX  ; DX ARITHMETIC ( ADDRESS ) register 



MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

MADR = 65535-15 ;

        org 0100h

BUF_ @TIB,66        ;   82 B TEST INPUT BUFFER
BUF_ @FIB,66        ;   66 B FILE INPUT BUFFER
BUF_ _@BCK,40       ;   40 B BACKWORD STACK
BUF_ _@FWD,50       ;   50 B FOREWORD STACK
BUF_ _@FLS,60       ;   40 B FILE STACK
BUF_ @TBUF,258     ;  256 B TEXT BUFFER 
BUF_ @R_TOP,10      ;  512 B RSTACK
BUF_ _@R_BTM,512    ;  512 
BUF_ @S_TOP,16      ;  512 B DSTACK
BUF_ _@S_BTM,512    ;  
BUF_ _@MACTOP,16    ; 4096 B = MACROS NAMES
BUF_ _@MACADR,2464  ; 2464 B = MACROSES
BUF_ @VOCTOP,4096   ; 4096 B = 4 BUFFERS * 1024 B IO


Start   Label byte

IF LISTGEN
  ENTRYB '',Start0
ENDIF

; -------------------
; Initialisation
; -------------------

@ABORT:
  MOV ax,0
  ORG $-2
PRIM 'BYE',_BYE,0,0
  mov PW [val_+_LTIB],ax
  mov sp,@R_TOP
  mov bp,@S_TOP
  CALL  DORET
  DW _LPAR
_interpret:
  DW _TEXT_IN,_EVAL,_JUMP,_interpreT  

  
  ;mov si,OFFSET _interpret
  ;JJ @next1
          DW DOVAR-2
        vaLUe 'DICT',_DICT,0,@VOCTOP
        
        vaLUe '#tib',_LTIB,0,0

          DW DOVAR-2
        POINT 'LOCATE',_LOCATE,0,@LOCINI

        VECTOR 'TEXT>',_TEXT_IN,0,_INI

        constant '0',_0,0,0

doGETP:   ; 0117
  PUSH IP
doGETADR:
  MOV  IP,[WA]
@next1:           ; 11A
  JMP NEXT

prim 'ABORT',_abort,0,@ABORT

;  mov   bx,1000h     ; only 64k allocate
;  mov   ah,4ah
;  int   21h
;        jmp SHORT @aborT

; -------------------
; Variables &  constantS
; -------------------

        vaLUe '>IN',_ETIB,0,0

        vaLUe 'BASE',_base,0,10

        PRIM ',',_comma,0,@COMMA
        vaLUe 'DP',_dp,0,ENDADR

        vaLUe 'DP+',_dpOFFS,0,0

        constant 'TIB',_tib,0,@TIB

        constant 'FIB',_Fib,0,@Fib

        constant 'TBUF',_TBUF,0,@TBUF

        constant 'BL',_BL,0,' '

; -------------------
; Stack
; -------------------

prim 'DUP',_DUP,0,DODUP

prim 'POP',_POP,0,DOPOP

prim 'PUSH',_PUSH,0,DOPUSH

prim 'DROP',_DROP,0,DODROP

prim 'NIP',_NIP,0,DONIP

prim 'OVER',_OVER,0,DOOVER

prim 'SWAP',_swap,0,@CALL
  XCHG TOP,NXT
  RET

PRIM 'LIT',_LIT,0,@CALLPH
  LODSW
  RET

; -------------------
; Maths / Logic
; -------------------

prim 'XOR',_XOR,0,@DRCALL
  XOR BX,AX
      IF DBG_FLAG EQ 0 
@DBG:  
      ENDIF
  RET
  
prim 'AND',_AND,0,@DRCALL
  AND BX,AX
  RET
  
prim '-',_MINUS,0,@DRCALL
  SUB BX,AX
  RET
  
prim '+',_plus,0,@DRCALL
  ADD BX,AX
  RET
  
  
; -------------------
; String & ARRAY
; -------------------

PRIM 'OPER',_OPER,0,@WARY
  DW _NUMBER,  _PERFORM  ; INTERP
  DW _COMPNUM, _@COMMA ; COMPILE
  
prim 'C@',_c@,0,@C@

prim '>NUM',_tonum,0,@PAR
  PUSH  CX CX 
  MOV SI,BX
  XCHG  AX,CX
  LODSB

  POP   DI BX
  MOV   CX,AX
  
  PUSH  DSP
  MOV   BP,Pw[val_+_base] ; BASE IN BP
@@numl: 
    jCXZ @@numz
  LODSB
@@nums: 
  cmp al,'9'+1
    jc @@numg
  AND al,0DFH
  cmp al,'A'
    jc @@numh
  sub al,7
@@numg: sub al,48
  cmp   aX,BP
    jnc @@numh
  push  Ax
  MOV   AX,BX  
  xchg  ax,DI
  mul   BP
  xchg  ax,DI
  mul   BP
  xchg  ax,BX
  POP   AX
  add   Bx,Ax
  adC   DI,dx
  dec   Cx
    JJ   @@numl
@@numh: 
  DEC   SI
@@numz: 
  POP   DSP
  push  Bx
  push  di
  push  SI
  push  cx
_@RETPAR:  
  POP   BX
_@RETPARZ:  
  X
  POP   IP DX
    jmp next

COLON 'NUM',_NUMBER,0
  DW _?STRSKIP,_NOP,_TONUM,_IF,@EXIT2
_@ONERR   dw _aborT
@EXIT2: DW _DROP
@EXIT1: DW _DROP,_RET 
  
COLON 'NUMC',_COMPNUM,0
  DW _?STRSKIP,_NOP,_NUMBER,_COMPILE,_LIT,_COMMA,_RET
  
; -----------------------
; Terminal Input / Output
; -----------------------

acc1:	
  ;MOV   AL,7
  ;call outchar
acc:
  call getchar   
	cmp  al,8
        jne  acc2
        jCXz   acc1
  ;CLC
  dec  Cx
  dec  DI
	push ax
  call outchar
  mov  al,' '
outc2:
  call outchar
  pop  ax
outchar:
@COUT:
  MOV   AH,0EH
  INT   10H
  RET

  prim 'EMIT',_emit,0,@DRCALL
  ;CALL  @REGS
  j outchar
  ;CALL  outchar
  ;CALL  @REGS
  ;RET

acc2:	
  cmp  al,13
        jne  acc3
  mov  Bx,Cx
  ;STC
  ret
  ;JMP @SPDOT

acc3:	
  cmp  al,' '
        jc   acc1
  STOSB
  inc  Cx
  jmp outchar

  PRIM '(DK',_DKEY,0,@CALLZPH
GETCHAR:
  mov ah,7
  int 021h
  RET

prim '(PARS',_PARSPRIM,0,@PAR
  PUSH  TOP
  POP   CX DI AX  
  SUB   DI,CX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   DI
  INC   CX
@@SKIPX:
  PUSH  DI    ;  START OF THE SOURCE
  JCXZ  @@WEX
  REPNE SCASB
  JNE   @@WEX
  DEC   DI      ; END OF THE SOURCE
@@WEX:          ; CX REST LEN OF BUF
  MOV   BX,CX
  POP   AX
  SUB   DI,AX
  PUSH  AX DI 
  JMP   _@RETPARZ
  
COLON 'PARS',_PARS,0
  DW  _ETIB,_LTIB,_PARSPRIM,TO_+_LTIB,_RET
  
COLON 'WORD',_word,0
  DW  _PARS
COLON 'S>T!',_SM,0
  DW  _TBUF,_MAKESTR,_RET

COLON 'BLWORD',_BLword,0
  DW _BL,_WORD
COLON '?C@',_?C@,0
  DW _DUP,_C@,_RET
    
; -----------------------
; MEMORY FUNCTIONS
; -----------------------

prim 'MPUSH',_MPUSH,0,@PAR
  POP   CX SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  JMP   _@RETPARZ
  
prim 'MOVTO',_TOADR,0,@PAR
  ;POP   DI  = BX
  POP   CX SI
    REP   MOVSB
  JMP   _@RETPARZ

prim 'S!',_MAKESTR,0,@PAR
  POP   AX SI
  MOV   CL,AL   ; CH = 0
  STOSB
    REP   MOVSB
  MOV   PB [DI],'`'
  JMP   _@RETPARZ

PRIM 'AL>EL',_ALEL,0,@CALL
  ADD  NXT,TOP
  RET

PRIM '1+',_1P,0,@1P

PRIM '2+',_2P,0,@2P

;PRIM '>UNPAK',_UNP,0,@PAR
;  XCHG  AX,Cx
;  POP   CX SI
;  INC   DI
;  SKIPB
;@@UN1:
;  STOSB
;  JCXZ  @@EX10
;  LODSB
;  DEC   CX
;  CMP   AL,'_'
;  JNE   @@UN2
;  MOV   AL,' '
;  JJ    @@UN1
;@@UN2:
;  CMP   AL,'"'
;  JNE   @@UN3
;  JCXZ  @@EX10
;  LODSB
;  DEC   CX
;  JJ    @@UN1
;@@UN3:
;  CMP   AL,'^'
;  JNE   @@UN4
;  JCXZ  @@EX10
;  LODSB
;  DEC   CX
;  AND   AL,31
;  JJ    @@UN1
;@@UN4:
;  CMP   AL,'~'
;  JNE   @@UN1
;  MOV   AL,128
;  XOR   PB [DI-1],AL
;  JJ    @@UN1
;@@EX10:
;  LEA   AX,[DI-1]
;  SUB   AX,BX
;  MOV   [BX],AL
;  JMP   _@RETPARZ

; -----------------------
; Dictionary Search
; -----------------------

prim 'CFND',_CFND,0,@CALL
  MOV   DI,NXT
  INC   PB [DI]
  PUSH  BX DI
  CALL  @FND
  POP   DI AX
  DEC   PB [DI]
  JCXZ  @AFND
  RET

@AFND:
  XCHG  AX,BX
  CALL  @FND
  INC   BX
  INC   BX
  RET
  
prim 'FND',_FND,0,@CALL
@FND:
  CALL  @METHOD
  SCASW
  MOV   SI,AX
  repe  cmpsb
  RET

prim 'WFND',_WFND,0,@CALL
  CALL  @METHOD
  RET


@METHOD:
  POP   AX
  PUSH  DX
  XCHG  AX,DX
  XOR   CX,Cx
  MOV   AX,NXT    ;KAKWO
  MOV   DI,BX     ;KADE
  PUSH  SI
  ;CALL  @REGS
  
@Nfnd:
  add   di,cx
  mov   Bx,di
  mov   cl,[di+4]
    jcxz  xfnd?
  INC   CX
  SCASW
    CALL  DX
  jNZ   @NFnD
  MOV   CL,1
  STC
  ADC   [BX+2],CX
  XCHG  BX,AX
xFND?:
  POP   SI DX
  ;CALL  @REGS
  MOV   NXT,AX 
  MOV   BX,CX 
  RET

; -----------------------
; Colon Definition
; -----------------------

COLON 'COMPILE',_COMPILE,0
  DW _RLDP,_comma,_RET

COLON '(@,',_@COMMA,0
  DW _FETCH,_comma,_RET


COLON ':',_COLON,0  
  DW _HEADER,_COMPILE,DOCOLON  
COLON '>,',_RPAR,0  
  DW TO_+_LOCATE,_DICT,_CFND,_RET
;  _DUP,_IF,@NOTFOUND,_RET
;@NOTFOUND:  
;  DW _DROP,_DICT,_FND,_2P,_RET
  
COLON ';`',_semicolon,0
  DW _COMPILE,_RET
COLON ',<`',_LPAR,0
  DW TO_+_LOCATE
@LOCINI: DW _DICT,_FND,_RET 
  
; -----------------------
; Headers
; -----------------------

;COLON 'HERE',_HERE,0
;  DW _DP,_DPOFFS,_PLUS,_RET

COLON 'HEADER',_HEADER,0
  DW _DP
colon '=:',_ENTRY,0
    dw _0,_SWAP,_Blword,_IF,_@ONERR
    DW _?C@,_1P,_DICT,_MPUSH
    DW _STOREM,_STOREM,TO_+_DICT,_RET

COLON '''',_TICK,0
  DW _Blword,_IF,_@ONERR,_FND,_IF,_@ONERR,_RET

;COLON ';CODE`',_SMCOD,0
;  DW _POP,_DICT,_FETCH,_STORE,_RET
 
 
; -----------------------
; Constants
; -----------------------

;PRIM 'CONST',_constant,0,@DEFS
;  DW doconst,_COMMA
  
; -----------------------
; Outer Interpreter
; -----------------------

COLON 'VIN',_VIN,0
  DW _TIB,_LIT,64,_ACCEPT,_RET
  
prim '(;',_RET,0,doRET

; -----------------------
; PRIMITIVES
; -----------------------

@COMMA:
  SCASW
  SCASW
  PUSH  WA
  MOV   WA,[WA]
  XCHG  AX,TOP
  STOSW
  POP   AX
  XCHG  AX,WA
  STOSW
  jJ DODROP
  
prim 'PERFORM',_PERFORM,0,@JPldPC
  SKIPA
prim 'EXEC',_exec,0,@JPDROP
  XCHG    W,WA
  SKIPA
doDEFER:
  mov     WA,[WA]
  SCASW
  JJ    @INDIR

; -------------------
; Flow Control
; -------------------

primITIVE '(?"',_?STRSKIP,0,@CLRC
  MOV   CL,[DI]   ; DI = BX
  ADD   DI,CX
  CMP   PB [DI],'"'
  JNE   DOSKIP
  jJ next

prim '(BR',_JUMP,0,DOJUMP

primITIVE '(NEXT',_NEXT,0
  POP   W 
  DEC   W 
  PUSH  W 
  INC   W
  JE    DOSKIP
DOJUMP:        
  mov IP,PW [IP]
  jJ next

prim '0;',_0RET,0,@JPDROP
  JE  DORET
  jJ next  

prim '(?BR',_IF,0,@JPDROP
  je DOJUMP
DOSKIP:  
  lodsw
  jJ next

DOFOR:
  MOV   IP,[IP]
DOPUSH:
  PUSH  BX
  jJ DODROP

PRIM 'R!+',_RSTP,0,@JPDROP
  POP   WA
  STOSW
  PUSH  WA
  JJ NEXT
  
PRIMITIVE 'R@+',_RLDP,0,@JPDUP
  POP   WA
  MOV   TOP,[WA]
  SCASW
  PUSH  WA
  JJ NEXT
  
DOSETV:
  SCASW
_@SET:
  MOV [WA],TOP
DODROP:
  MOV   TOP,[DSP]
DONIP:
  INC   DSP
  INC   DSP
  JJ NEXT

doOVER:
  MOV W,[DSP+2]
  jJ @PUSHW

  SCASW
  SCASW
_@DOES:
  POP   W
  PUSH  IP
  MOV   IP,W
  SKIPA
  
  SCASW
  SCASW
DOvar:
  XCHG   W,WA
  jJ @PUSHW

  SCASW
  SCASW
doconst: 
  mov W,[WA]
  jJ @PUSHW
DODUP:
  PUSH  TOP
DOPOP:
  POP   W
  jJ @PUSHW

@CALLDPH:
  MOV   WL,[TOP]
@CALLZPH:
  XOR   WH,WH
@CALLPH:
  CALL  WA
@PUSHW:
  XCHG  W,TOP
  X 
@RPUSHW:
  PUSH  W
@SWAPSTK:  
  X
  
; -------------------
; Inner Interpreter
; -------------------

next:   

;  CALL  @REGS
  MOV    WA,[IP]
  CMPSW
@INDIR:
  CALL  @DBG
  jmp PW [WA-2]

@LARY:
  SHL   TOP,1
@WARY:  
  SHL   TOP,1
@BARY:
  ADD   TOP,WA
  J NEXT

  
DOSETP:
  MOV [WA+2],IP
doRET:
  POP   IP
  J   NEXT
  
PRIMITIVE 'EX',_EX,0
  POP   WA
prim 'NOP',_NOP,0,13CH 
docolon = _NOP
  PUSH  IP
doLbl:  
  MOV   IP,WA
  j   NEXT
  
prim '!+',_STOREP,0,@CLRCX
  POP   [TOP]
;  JJ    @XINC

;prim '@+',_FETCHP,0,@CLRCX
;  PUSH   [TOP]
;@XINC:  
  X
@2P:  
  INC   TOP
@1P:  
  INC   TOP
  J   next  


prim '!-',_STOREM,0,@CLRCX
  POP   [TOP-2]
  X
@2M:  
  DEC   TOP
@1M:  
  DEC   TOP
  J   next  

; -------------------
; Peek and Poke
; -------------------

primitive '@',_fetch,0
  mov bx,PW [bx]
  j next

primitive '!',_store ,0,@CLRCX
  POP   [BX]
  X
  j doDROP

;PRIM '0SWAP',_0SWAP,0,@CLRCX
;  PUSH  CX
;  J @SWAPSTK
  
;prim 'DUPC@',_DUPC@,0,@JPDUP
@C@:  
  mov   bl, PB[bx]
@WtoB:  
  mov   bh,0
  j next

@JPldPC:  ; LOAD DROP CALL
  mov top,[top]
@JPDROP:
  PUSH  WA
@ADROP:
  DPOP  W
  XCHG  W,TOP
  TEST  W,W
  RET
  
@DRCALL:
  CALL  @ADROP
@CALL:
  CALL  DI
    j next

prim 'U<',_ULESS,0,@DRCALL
  SUB BX,AX
  JJ @ZEQ 

prim '0=',_Zeq,0,@CALL
  ;sub bx,1
  NEG BX
  CMC
@Zeq:
  sbb bx,bx
  RET

prim 'COUNT',_count,0,@CALLDPH
  INC   BX
  RET
  
prim 'STR',_STR,0,@CALLPH
  MOV   AX,[BX]
  INC   BX
  INC   BX
  RET
  
; -------------------
; Compilation
; -------------------

@JPDUP:
  PUSH  WA
@DUP:
  Dpush TOP
  RET
  
@PAR:
  PUSH  DX 
@PARIP:  
  PUSH  IP
@CLRCX:
  X
@CLRC:
  PUSH  WA
  MOV   WA,TOP
  XOR   CX,CX
  RET
  
priM 'ACCEPT',_ACCEPT,0,@CALL
  MOV   DI,NXT
  xor  cx,cx
acceptl:
  call acc 
  cmp  Bx,Cx
  jne  acceptl
  RET
 
COLON '(I',_INI,0
  DW _LIT,_VIN,TO_+_TEXT_IN,_LIT
DICTPTR:  
  DW ENDADR,_STR,_DICT,_MPUSH,TO_+_DICT
  DW _LIT,80H,_COUNT,_RET

final:
COLON 'EVAL',_EVAL,0    ; ADR LEN -> INTERPRET
  DW _ALEL,TO_+_LTIB,TO_+_ETIB
@EVAL:        
  DW _BLWORD,_IF,@EXIT1
  DW _LOCATE,_OPER,_PERFORM,_JUMP,@EVAL
  
;freemem = $ - START + 100H    ; ITSY.COM

; 941
; 939 940 942  958 965 954 949 932 938

IF DBG_FLAG
INCLUDE ITSY.IDB
ENDIF

ENDADR = $ - START + 0100H

IF LISTGEN
  ORG DTOP
DTOP = DTOP - DPTR
DPTR = DPTR - 2  
    DOKE DICTPTR,DPTR
    DOKE  DPTR,DTOP
    
Zfreemem = DPTR - ENDADR - 2  
ELSE
DW FREEMEM-ENDADR-2
  ENTRY '=:',_ENTRY 
  ENTRY '',0 
FREEMEM:
ENDIF

    
MyCseg  ends
        end  Start

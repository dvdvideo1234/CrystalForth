
INCLUDE ITSY.IMC

DTOP = 10000  ;-2035H
DPTR = DTOP

LISTGEN = 0

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
ar  = DX  ; DX ARITHMETIC ( ADDRESS ) register 
CNR  = CX  ; CX DATA REGISTER
CNRL = CL  ; CX DATA REGISTER
CNRH = CH  ; CX DATA REGISTER



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

  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
        jmp SHORT @aborT

; -------------------
; Variables &  constantS
; -------------------

        vaLUe 'DICT',_DICT,0,@VOCTOP
        
        vaLUe '>IN',_ETIB,0,0

        vaLUe '#tib',_LTIB,0,0

        POINT 'LOCATE',_LOCATE,0,@LOCINI

        constant 'TBUF',_TBUF,0,@TBUF

; -------------------
; Initialisation
; -------------------

primitive 'ABORT',_aborDOt,0
;  MOV AX,PW [VAL_+_DP]
;  CALL @STROUT
;  MOV AL,'?'
;  CALL @COUT
@ABORT:
  MOV ax,0
_BYE  = $-2
  mov PW [val_+_LTIB],ax
  MOV AX,OFFSET @LOCINI
  mov PW [VAL_+_LOCATE],ax
  
  mov sp,@R_TOP
  mov bp,@S_TOP
  mov si,OFFSET _interpret
  jmp next

        vaLUe 'DP',_dp,0,ENDADR

        vaLUe 'DP+',_dpOFFS,0,0

        constant 'TIB',_tib,0,@TIB

        constant 'FIB',_Fib,0,@Fib

        VECTOR 'TEXT>',_TEXT_IN,0,_INI

        vaLUe 'BASE',_base,0,10

; -------------------
; Stack
; -------------------

;primitive 'ROT',_ROT,0
;  pop  dx ax
;  push dx

;prim 'PUSH',_pUSH,0,@NIPCALL
;@PUSH:
;  XCHG  SP,BP
;  push  Ax
;  XCHG  SP,BP
;  RET
  
prim 'POP',_POP,0,@RPOPW

prim 'SWAP',_swap,0,doSWAP

prim 'PUSH',_PUSH,0,DOPUSH

; -------------------
; Maths / Logic
; -------------------

prim 'XOR',_XOR,0,@DRCALL
  XOR BX,AX
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
; DEBUGER
; -------------------

;PRIM 'TR-',_TRM,0,@CALL
;  MOV PB [NEXT],0B8H
;  RET
;
;PRIM 'TR',_TR,0,@CALL
;  MOV PB [NEXT],0E8H
;  RET
;
;PRIM 'H.',_HDOT,0,@NIPCALL
;@HDOT:
;  CALL  @WORDOUT
;@SPDOT:  
;  MOV   AL,' '
;  JMP   @COUT
;  
;@WORDOUT:
;  CALL  @BYTEOUT
;@BYTEOUT:
;  CALL  @HDOT1
;@HDOT1:
;  ROL   AX,1
;  ROL   AX,1
;  ROL   AX,1
;  ROL   AX,1
;  PUSH  AX
;  CALL  @DIGOUT
;  POP   AX
;  RET
;  
;@DIGOUT:
;  AND   AL,15
;  CMP   AL,10
;  JC    @DIG1
;  ADD   AL,7
;@DIG1:
;  ADD   AL,'0'
;  JMP   @COUT
;
;@STRID:
;  PUSH  CX DX DI
;  MOV   DX,-1
;  MOV   CX,32
;  XCHG  AX,DI
;@@IDLP:  
;  INC   DX
;  DEC   DI
;  MOV   AL,[DI]
;  AND   AL,127
;  CMP   AL,DL
;  JE    @@IDLPX
;  LOOP  @@IDLP
;@@IDLPX:
;  XCHG  AX,DI
;  POP   DI DX CX 
;  RET
;  
;@STROUT:
;  PUSH  CX DI
;  XCHG  AX,DI
;  MOV   AX,[DI]
;  AND   AX,127
;  MOV   CX,AX
;@LPSTR:
;  INC   DI
;  MOV   AL,[DI]
;  CALL  @COUT
;  LOOP  @LPSTR
;  POP   DI CX 
;  JMP   @SPDOT
;  
;@CRDOT:  
;  MOV   AL,13
;  CALL  @COUT
;  MOV   AL,10
;  JMP   @COUT
;  
;@DBG:
;  CALL  @PUSH   ; AX      1
;  CALL  @CRDOT  ; AX .
;  POP   AX
;  CALL  @PUSH   ; RETADR  2
;  ;CALL  @HDOT
;  MOV   AX,SI   ; IP
;  CALL  @HDOT
;  MOV   AX,SP   ; DSP
;  CALL  @HDOT
;  LEA   AX,[BP+4]
;  CALL  @HDOT   ; RSP
;  CALL  @SPDOT
;
;  ;ROT H.
;  POP   AX
;  CALL  @PUSH   ; DSP[2]  3
;  POP   AX
;  PUSH  AX
;  CALL  @HDOT   ; DSP[3] .
;
;  CALL  @POP    ; DSP[2] . 3
;  PUSH  AX
;  CALL  @HDOT
;  MOV   AX,BX   ; DSP[1] .
;  CALL  @HDOT
;  
;  CALL  @POP    ; RETADR BACK  2
;  PUSH  AX
;  MOV   AX,[BP]
;  CALL  @HDOT  
;  MOV   AX,CX
;  CALL  @HDOT
;  MOV   AX,DX
;  CALL  @HDOT
;  CALL  @SPDOT
;  MOV   AX,PW[VAL_+_DP]
;  CALL  @HDOT
;
;  MOV   AX,[SI]
;  CALL  @STRID
;  CALL  @STROUT
;  CALL  @READBIOS
;@POP:
;  XCHG  SP,BP
;  POP   AX
;  XCHG  SP,BP
;  RET
  
; -------------------
; String & ARRAY
; -------------------

PRIM 'OPER',_OPER,0,@WARY
  DW _NUMBER,  _EXEC  ; INTERP
  DW _COMPNUM, _COMMA ; COMPILE
  
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
  DW _?STRSKIP,_NOP,_TONUM,_ZEQ,_IF,_@ONERR
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
  j outchar

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

prim 'WORD',_word,0,@PARS

prim 'BLWORD',_BLword,0,@JPDUP
  MOV   BL,32
@PARS:
  MOV   DI,PW [val_+_ETIB]
  MOV   cx,PW [val_+_LTIB]
  XCHG  AX,BX
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
  MOV   PW [val_+_LTIB],cx
  POP   CX
  SUB   DI,CX
  mov   BX,PW [val_+_TBUF]
  MOV   PB [BX+DI+1],'`'
  XCHG  AX,DI
_@MAKESTRZ:
  MOV   DI,BX
  STOSB
  XCHG  AX,CX  
  XOR   CH,CH
_@TOMOVE:  
  XCHG  SI,AX  ; SAVE IP  ;PUSH  DX      ; START OF THE SOURCE
  REP   MOVSB
  XCHG  SI,AX
  JMP NEXT
  
GETCHAR:
  mov ah,7
  int 021h
  mov ah,0
  RET

_@BIOSK:
  XOR   AX,AX
  INT   16H
  RET
  
; -----------------------
; MEMORY FUNCTIONS
; -----------------------

PRIM '1+',_1P,0,@1P

PRIM '2+',_2P,0,@2P

PRIM '>UNPAK',_UNP,0,@PAR
  XCHG  AX,Cx
  MOV   DI,BX
  POP   CX SI
  INC   DI
  SKIPB
@@UN1:
  STOSB
  JCXZ  @@EX10
  LODSB
  DEC   CX
  CMP   AL,'_'
  JNE   @@UN2
  MOV   AL,' '
  JJ    @@UN1
@@UN2:
  CMP   AL,'"'
  JNE   @@UN3
  JCXZ  @@EX10
  LODSB
  DEC   CX
  JJ    @@UN1
@@UN3:
  CMP   AL,'^'
  JNE   @@UN4
  JCXZ  @@EX10
  LODSB
  DEC   CX
  AND   AL,31
  JJ    @@UN1
@@UN4:
  CMP   AL,'~'
  JNE   @@UN1
  MOV   AL,128
  XOR   PB [DI-1],AL
  JJ    @@UN1
@@EX10:
  LEA   AX,[DI-1]
  SUB   AX,BX
  MOV   [BX],AL
  JMP   _@RETPARZ

; -----------------------
; Dictionary Search
; -----------------------

prim 'CFND',_CFND,0,@CALL
  MOV   DI,NXT
  INC   PB [DI]
  PUSH  DI
  CALL  @FND
  POP   DI
  DEC   PB [DI]
  RET

prim 'FND',_FND,0,@CALL
@FND:
  CALL  @METHOD
  repe  cmpsb
  RET

prim 'WFND',_WFND,0,@CALL
  CALL  @METHOD
  CMP   SI,[DI-4]
  RET


@METHOD:
  POP   AX
  PUSH  DX 
  XCHG  AX,DX
  XOR   CX,Cx
  MOV   AX,NXT    ;KAKWO
  MOV   DI,BX     ;KADE
  PUSH  SI
@Nfnd:
  add   di,cx
  mov   Bx,di
  LEA   di,[DI+4]
  mov   cl,[di]
    jcxz  xfnd?
  INC   CX
  MOV   SI,AX
    CALL  DX
  jNZ   @NFnD
  INC   CX
  STC
  ADC   [BX+2],CX
  XCHG  BX,AX
xFND?:
  POP   SI DX
  MOV   NXT,AX 
  MOV   BX,CX 
  RET

; -----------------------
; Colon Definition
; -----------------------

COLON 'LIT',_LIT,0
  DW _RLDP,_RET

COLON 'COMPILE',_COMPILE,0
  DW _RLDP
COLON ',',_comma,0
  DW _DP,_STOREP,TO_+_DP,_RET


COLON ':',_COLON,0  
  DW _HEADER,_COMPILE,DOCOLON  
COLON '>,',_RPAR,0  
  DW TO_+_LOCATE,_TBUF,_CFND,_DUP,_IF,@NOTFOUND,_RET
@NOTFOUND:  
  DW _DROP,_TBUF,_FND,_2P,_RET
  
COLON ';`',_semicolon,0
  DW _COMPILE,_RET
COLON ',<`',_LPAR,0
  DW TO_+_LOCATE
@LOCINI: DW _TBUF,_FND,_RET 
  
; -----------------------
; Headers
; -----------------------

COLON 'HERE',_HERE,0
  DW _DP,_DPOFFS,_PLUS,_RET

COLON 'HEADER',_HEADER,0
  DW _HERE
colon '=:',_ENTRY,0
    dw _0SWAP,_Blword,_DUPC@,_IF,_@ONERR
    DW _DUPC@,_1P,_DICT,_MPUSH
    DW _STOREM,_STOREM,TO_+_DICT,_RET

COLON '''',_TICK,0
  DW _Blword,_DUPC@,_IF,_@ONERR,_FND,_IF,_@ONERR,_RET

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

_@ONERR   dw _aborDOT

COLON 'VIN',_VIN,0
  DW _TIB,_LIT,64,_ACCEPT,_RET
  
_interpret:
  DW _TEXT_IN,_EVAL,_JUMP,_interpreT  

prim '(;',_RET,0,doRET

; -----------------------
; PRIMITIVES
; -----------------------

prim 'PERFORM',_PERFORM,0,@JPldPC
  SKIPA
prim 'EXEC',_exec,0,@JPDROP
  SKIPA
doDEFER:
  mov WA,[WA]
  SCASW
  jmp PW [WA-2]

; -------------------
; Flow Control
; -------------------

primITIVE '(?"',_?STRSKIP,0
  MOV   DI,255
  AND   DI,BX
  CMP   PB [BX+DI],'"'
  JNE   @SKIP
  jJ next

prim '(?BR',_IF,0,@JPDROP
  je @JUMP
@SKIP:  
  lodsw
  jJ next

primitive '(BR',_JUMP,0
@JUMP:        
  mov IP,PW [IP]
  jJ next

;prim 'S!',_MAKESTR,0,@JP2NIP
;  XCHG   AX,CX
;  CALL  @MAKESTRZ
;  JJ   next  
;
;prim 'MOVTO',_TOADR,0,@JP2NIP
;  MOV   DI,BX
;  CALL  @TOADR
;  JJ   next  

_@DOFOR:
  MOV   IP,[IP]
DOPUSH:
  PUSH  BX
  jJ DODROP

PRIMITIVE 'R!+',_RSTP,0
  POP   WA
  XCHG  W,TOP
  STOSW
  PUSH  WA
  JJ DODROP
  
PRIMITIVE 'R@+',_RLDP,0
  POP   WA
  MOV   W,[WA]
  SCASW
  PUSH  WA
  JJ @PUSHW
  
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
  SKIPR  CNR
  
  SCASW
  SCASW
DOvar:
  XCHG   W,WA
  jJ @PUSHW

  SCASW
  SCASW
doconst: 
  mov W,[WA]
  SKIPB
@RPOPW:
  POP   W
@PUSHW:
  XCHG  W,TOP
  X 
  PUSH  W
@SWAPSTK:  
  X
  
; -------------------
; Inner Interpreter
; -------------------

next:   
  ;CALL  @DBG
  MOV    WA,[IP]
  CMPSW
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
  
doGETP:
  PUSH IP
doGETADR:
  MOV  IP,[WA]
  J NEXT

_@EX:
  POP   WA
prim 'NOP',_NOP,0,13CH 
docolon = _NOP
  PUSH  IP
doLbl:  
  MOV   IP,WA
  j   NEXT
  
doSWAP:
  XCHG TOP,NXT
    j next

prim '!+',_STOREP,0,@CLRCX
  POP   [TOP]
  JJ    @XINC

prim '@+',_FETCHP,0,@CLRCX
  PUSH   [TOP]
@XINC:  
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

PRIM '0SWAP',_0SWAP,0,@CLRCX
  PUSH  CX
  J @SWAPSTK
  
prim 'COUNT',_count,0,@CLRCX
  MOV   CL,[BX]
  INC   BX
  PUSH  BX
  MOV   BX,CX
  J @SWAPSTK

prim 'DUPC@',_DUPC@,0,@JPDUP
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
  TEST  TOP,TOP
  XCHG  W,TOP
  RET
  
@DRCALL:
  CALL  @ADROP
@CALL:
  CALL  DI
    j next

prim 'MPUSH',_MPUSH,0,@PAR
  MOV   DI,TOP
  POP   CX SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  J   _@RETPARZ
  
prim 'U<',_ULESS,0,@DRCALL
  SUB BX,AX
  JJ @ZEQ 

prim '0=',_Zeq,0,@CALL
  sub bx,1
@Zeq:
  sbb bx,bx
  RET

; -------------------
; Compilation
; -------------------

prim 'DROP',_drop,0,doDROP

PRIM 'DUP',_DUP,0,@CALL
  SKIPA
@JP1PDUP:
  INC TOP
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
  XOR   CX,CX
  JMP   WA
  
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
  DW ENDADR,_FETCHP,_SWAP,_DICT,_MPUSH,TO_+_DICT
  DW _LIT,80H,_COUNT,_RET

final:
COLON 'EVAL',_EVAL,0    ; ADR LEN -> INTERPRET
  DW _DUP,TO_+_LTIB,_PLUS,TO_+_ETIB
@EVAL:        
  DW _BLWORD,_DUPC@,_IF,@EXIT1
  DW _LOCATE,_OPER,_PERFORM,_JUMP,@EVAL
  
;freemem = $ - START + 100H    ; ITSY.COM

; 941
; 939 940 942  958 965 954 949 932 938


ENDADR = $ - START + 0100H
  ENTRY '=:',_ENTRY 
  ENTRY '',0 

IF LISTGEN

  ORG DTOP
  
DTOP = DTOP - DPTR
DPTR = DPTR - 2  

    DOKE DICTPTR,DPTR
    DOKE  DPTR,DTOP
Zfreemem = DPTR - ENDADR - 2  
ENDIF

    
MyCseg  ends
        end  Start

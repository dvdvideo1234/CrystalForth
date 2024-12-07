
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

BUF_  @FLS,2        ;   16 B FILE STACK  OF INCLUDE FILES
BUF_  @TIB,64       ;   64 B TEXT INPUT BUFFER
BUF_  @FIB,64       ;   64 B FILE INPUT BUFFER
BUF_  @FOB,64       ;   64 B FILE OUTPUT BUFFER
BUF_  _@BCK,20      ;   22 B BACKWORD STACK FOR BRANCHES
BUF_  _@FWD,20      ;   22 B FOREWORD STACK FOR BRANCHES
BUF_  @TBUF,256     ;  256 B TEXT BUFFER 
BUF_  @R_TOP,6
BUF_  @R_BTM,512    ;  512 B RSTACK
BUF_  @D_TOP,0
BUF_  @D_BTM,512    ;  512 B DSTACK
BUF_  _@MACTOP,0
BUF_ _@MACADR,2560  ; 2560 B = MACROSES
BUF_ _@VOCTOP,4096  ; 4096 B = 4 BUFFERS * 1024 B IO


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
PRIM 'BYE',_BYE,0
  mov PW [val_+_LTIB],ax
  mov sp,@R_TOP
  mov bp,@D_TOP
  CALL  DORET
  DW _LPAR
_interpret:
  DW _TEXT_IN,_EVAL,_JUMP,_interpreT  

prim 'ABORT',_abort,@ABORT

@HERE:
  MOV   W,[WA] 
  ADD   W,PW [VAL_+_DP]
  JMP   @PUSHW

@UNCOMMA:
  SCASW
  SCASW
  CALL  @DUP
;  MOV   WA,[WA]   ; POINTS TO USER DATA STK POINTER
  PUSH  WA
  MOV   AX,[WA+2] ; LOAD LOWER LIMIT
  MOV   WA,[WA]   ; POINTS TO USER DATA STK POINTER
  LEA  BX,[WA-2]  ; NEW VALUE
  CMP   BX,AX    ; EXCEEDED EDGE ?
    JNGE  @floor
  MOV   AX,BX
  MOV   BX,[BX]   ; FETCH BY POINTER
  POP   WA        ; RESTORE POINTER
  STOSW           
@next1:           ; 11A
  JMP   NEXT
  
@floor:
    CALL  @?ERR
    MAKESTR 'floor:'
      
doGETP:   
  PUSH IP
doGETADR:
  MOV  IP,[WA]
  J @next1

; -------------------
; Variables &  constantS
; -------------------

          DW DOVAR-2
        vaLUe 'DICT',_DICT,_@VOCTOP
        
        vaLUe '#tib',_LTIB,0

          DW DOVAR-2
        POINT 'LOCATE',_LOCATE,@LOCINI

        VECTOR 'TEXT>',_TEXT_IN,_INI

          DW DOVAR-2
        VECTOR 'EMIT',_EMIT,_Demit

          DW DOVAR-2
        VECTOR 'KEY',_KEY,_DKEY

        constant '0',_0,0

        vaLUe '>IN',_ETIB,0

        vaLUe '"STAT',_STATE,0

        vaLUe 'BASE',_base,10

        PRIM 'UN,',_UNcomma,@UNCOMMA
        PRIM ',',_comma,@COMMA
        VARIABLE 'DP',_dp,ENDADR
            DW 100H,_@MACTOP

          DW DOVAR-2
          DW DOCONST-1
        PRIM 'HERE',_HERE,@HERE

        constant 'TIB',_tib,@TIB

        constant 'FIB',_Fib,@Fib

        constant 'TBUF',_TBUF,@TBUF

        constant 'BL',_BL,' '

PRIM 'H.',_HDOT,@DRCALL
@HDOT:
  CALL  @WORDOUT
@SPDOT:  
  MOV   AL,' '
  JMP   @COUT
  
PRIM 'SPC',_SPC,@CALL
  MOV AL,' '
  J @SPDOT
    
@WORDOUT:
  CALL  @BYTEOUT
@BYTEOUT:
  CALL  @HDOT1
@HDOT1:
  ROL   AX,1
  ROL   AX,1
  ROL   AX,1
  ROL   AX,1
  PUSH  AX
  CALL  @DIGOUT
  POP   AX
  RET

; -------------------
; Stack & ERRORS
; -------------------
  
@COMMA:
  SCASW           ; WA - POINTS TO USER DATA STK POINTER
  PUSH  WA        ; SAVE POINTER TO USER DATA
  MOV   AX,[WA+4] ; LOAD UPPR LIMIT
  MOV   WA,[WA]   ; POINTS TO USER DATA STK POINTER
  SCASW
  CMP   WA, AX; EXCEEDED EDGE ?
    JNG  @ceiling
  MOV   [DI-2],BX
  POP   AX
  XCHG  AX,WA
  STOSW           ; STORE POINTER
  JMP DODROP
  
@ceiling:
    CALL  @?ERR
    MAKESTR 'ceiling:'
    
PRIM 'TR-',_TRM,@CALL
@TRM:
  MOV AX,0FFA7H
@TRZ:  
  XCHG AX, PW [@INDIR]
  RET

PRIM 'TR',_TR,@CALL
  MOV AX,0B890H
  J @TRZ

 DIVE '(NEST-',@NESTRM
    CALL  @TRM
    PUSH  IP W
    MOV   IP,WA
    CALL  NEXT
  DW _4TH
    POP   W
    CALL  @TRZ
    JMP  DORET
    
 PRIMITIVE '>4TH',_4TH
    JMP IP

@?ERR:
    CALL  @CR
    POP  AX
    CALL  @SHOWSTR
    JJ  @?ERR2
    
PRIM '("+',_STRSKIP,@PAR
  PUSH  TOP IP
  MOV   CL,[IP]
  INC   Cx
  ADD   NXT,CX
  JMP   _@RETPAR
  
COLON '("0A',_0ABRT
    DW _ZEQ
COLON '("A',_ABRT
    DW _STRSKIP,TO_+_STATE,_0RET
@ONERR:
  DW _CR,_STATE,_SDOT,_4TH
@?ERR2:
    MOV  AX,PW [VAL_+_TBUF]
    CALL  @SHOWSTR
    MOV   AL,'?'
    CALL  @COUT
    JMP   @ABORT
      
  PRIM 'CR',_CR,@CALL
@CR:
    CALL  @?STR
    DB  2,13,10

PRIM '".',_SDOT,@DRCALL
    SKIPB
@?STR:
    POP   AX
@SHOWSTR: 
    PUSH  SI
    XCHG  AX,SI
    XOR   AH,AH
    LODSB
    XCHG  AX,Cx
      JCXZ  @CHLPE
@CHLP:
    LODSB
    CALL  @COUT
@CHLP?:
      LOOP @CHLP
@CHLPE:   
    XCHG  AX,SI
    POP   SI
    RET
    
;  mov   bx,1000h     ; only 64k allocate
;  mov   ah,4ah
;  int   21h
;        jmp SHORT @aborT

prim 'DUP',_DUP,DODUP

prim 'POP',_POP,DOPOP

prim 'PUSH',_PUSH,DOPUSH

prim 'DROP',_DROP,DODROP

prim 'NIP',_NIP,DONIP

prim 'OVER',_OVER,DOOVER

prim 'SWAP',_swap,@CALL
  XCHG TOP,NXT
  RET

PRIM 'LIT',_LIT,@CALLPH
  LODSW
  RET

; -------------------
; Maths / Logic
; -------------------

prim 'XOR',_XOR,@DRCALL
  XOR BX,AX
      IF DBG_FLAG EQ 0 
@DBG:  
      ENDIF
  RET
  
prim 'AND',_AND,@DRCALL
  AND BX,AX
  RET
  
prim '-',_MINUS,@DRCALL
  SUB BX,AX
  RET
  
prim '+',_plus,@DRCALL
  ADD BX,AX
  RET
  
  
; -------------------
; String & ARRAY
; -------------------

PRIM 'OPER',_OPER,@WARY
  DW _NUMBER,  _PERFORM  ; INTERP
  DW _COMPNUM, _@COMMA ; COMPILE
  
prim 'C@',_c@,@C@

prim '>NUM',_tonum,@PAR
  PUSH BX
  POP   CX SI DI BX
  XOR   AX,AX
@@numl: 
    jCXZ @@numz
  LODSB
@@nums: 
  cmp al,'9'+1
    jc @@numg
;        cmp al,'a'
;        jc to_nums
;        sub al,32
;  AND aL,0DFH
  cmp al,'A'
    jc @@numh
  sub al,7
@@numg: sub al,48
  cmp   aX,Pw[val_+_base]
    jnc @@numh
  push  Ax
  MOV   AX,BX  
  xchg  ax,DI
  mul   Pw[val_+_base]
  xchg  ax,DI
  mul   Pw[val_+_base]
  POP   BX        ; AH = 0  !!!
  XCHG  AX,BX
  add   Bx,Ax
  adC   DI,dx
  dec   Cx
    JJ   @@numl
@@numh: 
  DEC   SI
@@numz: 
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

;COLON 'NUM',_NUMBER
COLONM 'NUM',_NUMBER
  DW _STRSKIP?,_NOP,_0SWAP,_0SWAP,_COUNT,_TONUM,_ABRT
  MAKESTR 'NUM'
@EXIT2: DW _DROP
@EXIT1: DW _DROP,_RET 
  
  ;_IF,@EXIT2
;_@ONERR   dw _JUMP,@ONERR
;
;COLON '2DROP',_2DROP

COLON '"Z',_STRZ
    DW _COUNT,_OVER,_PLUS,_0SWAP,_STORE,_RET
    
    
COLONM 'NUMC',_COMPNUM
;COLONM 'NUMC',_COMPNUM
  DW _STRSKIP?,_NOP,_NUMBER,_COMPILE,_LIT,_COMMA,_RET
  
; -----------------------
; Terminal Input / Output
; -----------------------

@DIGOUT:
  AND   AL,15
  CMP   AL,10
  JC    @DIG1
  ADD   AL,7
@DIG1:
  ADD   AL,'0'
  JMP   @COUT
  
  PRIM '(DK',_DKEY,@CALLZPH
GETCHAR:
  mov ah,7
  int 021h
  RET

  prim '(DE',_Demit,@DRCALL
  jJ @COUT

  PRIM '(BK',_BKEY,@CALLPH
_@BIOSK:
  XOR   AX,AX
  INT   16H
  RET
  
  prim '(BE',_Bemit,@DRCALL
  jJ @COUT

acc1:	
  ;MOV   AL,7
  ;call @COUT
acc:
  call getchar   
	cmp  al,8
        jne  acc2
        jCXz   acc1
  ;CLC
  dec  Cx
  dec  DI
	push ax
  call @COUT
  mov  al,' '
outc2:
  call @COUT
  pop  ax
@COUT:
  MOV   AH,0EH
  INT   10H
  RET

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
  jmp @COUT

prim '(PARS',_PARSPRIM,@PAR
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
  
COLON 'PARS',_PARS
  DW  _ETIB,_LTIB,_PARSPRIM,TO_+_LTIB,_RET
  
COLON 'WORD',_word
;COLONM 'WORD',_word
  DW  _PARS
COLON 'S>T!',_SM
  DW  _TBUF,_MAKESTR,_RET

;COLON 'TOKEN',_TOKEN
COLONM 'TOKEN',_TOKEN
  DW _BL,_WORD,_?C@,_RET

; -----------------------
; LOOPS
; -----------------------

;: ..TIMES ;DROP : .TIMES ;DROP : TIMES SWAP : >TIMES PUSH
;: LOOPS (FOR MRK> BEGIN J EXECUTE (NEXT <RLS RLS> RDROP ;

COLON ';DROP',_XDROP
  DW _EX,_DROP,_RET

COLON 'EXECUTE',_EXECUTE
  DW _PUSH,_RET

PRIM '(FOR',_FOR,DOFOR

PRIMITIVE 'J',_J
  POP CX AX
  PUSH AX CX 
  JMP @PUSHW
  

COLON '..TIMES',_DDTIMES
  DW _XDROP
COLON '.TIMES',_DTIMES
  DW _XDROP
COLON 'TIMES',_TIMES
  DW _SWAP
COLON '>TIMES',_TOTIMES
  DW _PUSH
COLON 'LOOPS',_LOOPS
  DW _FOR,@@2
@@1:
    DW _J,_EXECUTE
@@2:
  DW _NEXT,@@1,_POP,_DROP,_RET
  
  
   
; -----------------------
; MEMORY FUNCTIONS
; -----------------------

PRIM 'REVERT',_REVERT,@jPNIP
	XCHG	W,WA
		JJ		@@REV
@@REV2:	
	MOV		AL,[TOP]
	MOV		AH,[WA]
	MOV		[top],ah
	STOSB
@@REV:
	DEC		TOP
	CMP		WA,TOP
		JC 		@@REV2
	JMP		DODROP
	

;: REVERT   ;2DROP  BEGIN 1-  2DUP U< 0;
;     PUSH PUSH  J C@  I C@  J C!    POP  C!+ POP  AGAIN ,<

prim 'MPUSH',_MPUSH,@PAR
  POP   CX SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  JMP   _@RETPARZ
  
prim 'MOVTO',_TOADR,@PAR
  ;POP   DI  = BX
  POP   CX SI
    REP   MOVSB
  JMP   _@RETPARZ

prim 'S!',_MAKESTR,@PAR
  POP   AX SI
  MOV   CL,AL   ; CH = 0
  STOSB
    REP   MOVSB
  MOV   PB [DI],'`'
  JMP   _@RETPARZ

PRIM 'AL>EL',_ALEL,@CALL
  ADD  NXT,TOP
  RET

PRIM '1+',_1P,@1P

PRIM '2+',_2P,@2P

PRIM 'PAX!',_PAX,@PAR
  POP   CX SI
  JJ    @@UN4
  
@@UN1:
  LODSB
  AND   AL,31
  SKIPB
@@UN2:
  LODSB
  JCXZ  @@UN6
  DEC   CX
  SKIPA
@@UN3:
  MOV   AL,' '
@@UN4:
  STOSB
@@UN5:  
  JCXZ  @@UN6
  LODSB
  DEC   CX
  CMP   AL,'_'
  JE    @@UN3
  CMP   AL,'"'
  JE    @@UN2
  CMP   AL,'^'
  JE    @@UN1
  CMP   AL,'~'
  JNE   @@UN4
  MOV   AL,128
  XOR   PB [DI-1],AL
  JJ    @@UN5
@@UN6:
  DEC   DI
  SUB   DI,BX
  XCHG  AX,DI
  MOV   [BX],AL
  JMP   _@RETPARZ

; -----------------------
; Dictionary Search
; -----------------------

prim 'CFND',_CFND,@CALL
  MOV   DI,NXT
  INC   PB [DI]
  PUSH  BX DI
  CALL  @FNDC
  POP   DI AX
  DEC   PB [DI]
  JCXZ  @AFND
  RET

@AFND:
  XCHG  AX,BX
  CALL  @FNDC
  INC   BX
  INC   BX
  RET
  
@FNDC:
  MOV   CL,[BX+4]
  LEA   DI,[BX+5]
  JMP  @FND
prim 'FND',_FND,@CALL
  MOV   DI,BX     ;KADE
  XOR   CL,CL
@FND:
  XOR   CH,CH
  PUSH  SI
  MOV   AX,NXT    ;KAKWO
  ;CALL  @REGS
  
@Nfnd:
  add   di,cx
  mov   Bx,di
  LEA   DI,[DI+4]
  mov   cl,[di]
    jcxz  xfnd?
  INC   CX
  MOV   SI,AX
  REP   CMPSB
    jNZ   @NFnD
  INC   CX
  STC
  ADC   [BX+2],CX
  MOV   NXT,BX 
xFND?:
  POP   SI 
  ;CALL  @REGS
  MOV   BX,CX 
  RET

; -----------------------
; Colon Definition
; -----------------------

COLON 'COMPILE',_COMPILE
  DW _RLDP,_comma,_RET

COLON '(@,',_@COMMA
  DW _FETCH,_comma,_RET


COLON ':',_COLON  
  DW _HEADER,_COMPILE,DOCOLON  
COLON '>,',_RPAR  
  DW TO_+_LOCATE,_DICT,_CFND,_RET
;  _DUP,_IF,@NOTFOUND,_RET
;@NOTFOUND:  
;  DW _DROP,_DICT,_FND,_2P,_RET
  
COLON ';`',_semicolon
  DW _COMPILE,_RET
COLON ',<`',_LPAR
  DW TO_+_LOCATE
@LOCINI: DW _DICT,_FND,_RET 
  
; -----------------------
; Headers
; -----------------------

COLON 'TOKEN?',_TOKEN?
  DW _TOKEN,_0ABRT
  MAKESTR 'EMPTY LINE'
  DW _RET
 
COLONM 'HEADER',_HEADER
  DW _HERE
colon '=:',_ENTRY
    dw _TOKEN?,_0SWAP,_?C@,_1P,_DICT,_MPUSH
    DW _STOREM,_STOREM,TO_+_DICT,_RET

COLON '''',_TICK
  DW _TOKEN?,_DICT,_FND,_0ABRT
  MAKESTR 'NFND'
  DW _FETCH,_RET

;COLON ';CODE`',_SMCOD
;  DW _POP,_DICT,_FETCH,_STORE,_RET
 
 
; -----------------------
; Constants
; -----------------------

;PRIM 'CONST',_constant,@DEFS
;  DW doconst,_COMMA
  
; -----------------------
; Outer Interpreter
; -----------------------

COLON 'VIN',_VIN
;COLONM 'VIN',_VIN
  DW _CR,_LIT,']',_EMIT,_TIB,_LIT,64,_ACCEPT,_SPC,_RET
  
prim '(;',_RET,doRET

; -----------------------
; PRIMITIVES
; -----------------------

prim 'PERFORM',_PERFORM,@JPldPC
  SKIPA
prim 'EXEC',_exec,@JPDROP
  XCHG    W,WA
  SKIPA
doDEFER:
  mov     WA,[WA]
  SCASW
  JMP   [WA-2]

; -------------------
; Flow Control
; -------------------

primITIVE '("?',_STRSKIP?,@CLRC
  MOV   CL,[DI]   ; DI = BX
  ADD   DI,CX
  CMP   PB [DI],'"'
  JNE   DOSKIP
  jJ next

prim '(BR',_JUMP,DOJUMP

primITIVE '(NEXT',_NEXT
  POP   W 
  DEC   W 
  PUSH  W 
  INC   W
  JE    DOSKIP
DOJUMP:        
  mov IP,PW [IP]
  jJ next

prim '0;',_0RET,@JPDROP
  JE  DORET
  jJ next  

prim '(?BR',_IF,@JPDROP
  je DOJUMP
DOSKIP:  
  lodsw
  jJ next

DOFOR:
  MOV   IP,[IP]
DOPUSH:
  PUSH  BX
  jJ DODROP

PRIM 'R!+',_RSTP,@JPDROP
  POP   WA
  STOSW
  PUSH  WA
  JJ NEXT
  
PRIMITIVE 'R@+',_RLDP,@JPDUP
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
@INDIR:
  CMPSW
  jmp PW [WA-2]
  ORG $-4
;@NODEBUG:
;  DB 0FFH
  NOP
  DB 0B8H
  ORG $+2
  CALL  @DBG
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
  
PRIMITIVE 'EX',_EX
  POP   WA

;prim 'NOP',_NOP 

DIVE 'NOP',_NOP 
DIVE '(NEST',docolon
  DW 13CH
  PUSH  IP
doLbl:  
  MOV   IP,WA
  j   NEXT
  
prim '!+',_STOREP,@CLRCX
  POP   [TOP]
  JJ    @XINC

prim '@+',_FETCHP,@CLRCX
  PUSH   [TOP]
@XINC:  
  X
@2P:  
  INC   TOP
@1P:  
  INC   TOP
  J   next  


prim '!-',_STOREM,@CLRCX
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

primitive '@',_fetch
  mov bx,PW [bx]
  j next

prim '!',_store ,@CLRCX
  POP   [BX]
  X
  j doDROP

PRIM '0SWAP',_0SWAP,@CLRCX
  PUSH  CX
  J @SWAPSTK
  
prim '?C@',_?C@,@JPDUP
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
  
@JPniP:
  PUSH  WA
@NIP:
  DPOP  W
  RET
@NIPCALL:
  CALL @NIP
  JJ @CALL
@DRCALL:
  CALL  @ADROP
@CALL:
  CALL  DI
    j next

prim 'U<',_ULESS,@DRCALL
  SUB BX,AX
  JJ @ZEQ 

prim '0=',_Zeq,@CALL
  ;sub bx,1
  NEG BX
  CMC
@Zeq:
  sbb bx,bx
  RET

prim 'COUNT',_count,@CALLDPH
  INC   BX
  RET
  
prim 'STR',_STR,@CALLPH
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
  PUSH  DX IP
@CLRCX:
  X
@CLRC:
  PUSH  WA
  MOV   WA,TOP
  XOR   CX,CX
  RET
  
priM 'ACCEPT',_ACCEPT,@CALL
  MOV   DI,NXT
  xor  cx,cx
acceptl:
  call acc 
  cmp  Bx,Cx
  jne  acceptl
  RET

;FF 65
 
COLON '(I',_INI
  DW _LIT,_VIN,TO_+_TEXT_IN,_LIT
DICTPTR:  
  DW ENDADR,_STR,_LIT,_@VOCTOP,_MPUSH,TO_+_DICT
  DW _LIT,80H,_COUNT
;  DW _TR  ;GHXFGH
  DW  _RET

final:
COLON 'EVAL',_EVAL    ; ADR LEN -> INTERPRET
  DW _ALEL,TO_+_LTIB,TO_+_ETIB
@EVAL:        
  DW _TOKEN,_IF,@EXIT1
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
ELSE
DW 0    ; FILLER
DPTR = $
DW FREEMEM-ENDADR-2
  ENTRY '=:',_ENTRY 
  ENTRY '',0 
DTOP = $
ENDIF

DTOP = DTOP - DPTR
    DOKE _DICT+VAL_,DPTR
DPTR = DPTR - 2  
    DOKE DICTPTR,DPTR
    DOKE  DPTR,DTOP
    
Zfreemem = DPTR - ENDADR - 2  

IF Zfreemem LT 0
  MEMORY_ERROR
ENDIF

    
MyCseg  ends
        end  Start

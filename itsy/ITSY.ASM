
locals  @@
VAL_ = 2
TO_  = -2
AT_  = -4

fl_name = 0

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

SKIPA   MACRO
  DB    03DH
ENDM

SKIPB   MACRO
  DB    03CH
ENDM

SKIPR   MACRO reg
MADR = $
  mov   reg,0
  IF $-MADR-2
  org   $-1
  ENDIF
  org   $-1
ENDM

X MACRO 
  XCHG DSP,RSP      
ENDM

JMPS MACRO LBL
  JMP   SHORT LBL
ENDM

DPOP    MACRO REG
  X
  POP REG
  X
ENDM

DPUSH   MACRO REG
  X
  PUSH REG
  X
ENDM

RPOP    MACRO REG
  POP REG
ENDM

RPUSH   MACRO REG
  PUSH REG
ENDM


nam_    macro   msg,FLAG
  local endstr
  db    endstr-$-1+FLAG
  db    msg
endstr  label   byte
        endm

HEAD MACRO  NAM,LBL,FLAG
  if fl_name EQ 1
TEMP = $
  DW LINK
LINK = TEMP
  NAM_ NAM,FLAG
  endif
LBL:
ENDM  

primitive MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,FLAG
  DW $+2
  ENDM

prim MACRO NAM,LBL,FLAG,ADR
  HEAD NAM,LBL,FLAG
  DW ADR
  ENDM

colon MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,FLAG
  DW docolon
  ENDM

constant MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW doconst,FLAG
  ENDM

variable MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW dovar,FLAG
  ENDM

DEFER MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW doDEFER,FLAG
  ENDM

VALUE MACRO NAM,LBL,FLAG
  DW DOSETV
  HEAD NAM,LBL,0
  DW doconst,FLAG
  ENDM

VECTOR MACRO NAM,LBL,FLAG
  DW DOSETV
  HEAD NAM,LBL,0
  DW doDEFER,FLAG
  ENDM

POINT MACRO NAM,LBL,FLAG
  DW DOSETP
  HEAD NAM,LBL,0
  DW doGETP,FLAG
  ENDM

BUF_ MACRO ADR,LEN
  MADR = MADR - (LEN)
  ADR  = MADR
ENDM
 
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
DR  = CX  ; CX DATA REGISTER
DRL = CL  ; CX DATA REGISTER
DRH = CH  ; CX DATA REGISTER



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

        jmp SHORT @aborT

_BYE  DW 0
  
; -------------------
; Variables
; -------------------

        POINT 'LOCATE',_LOCATE,@LOCINI

        vaLUe '>IN',_ETIB,0

        vaLUe '#tib',_LTIB,0

        vaLUe 'DP',_dp,freemem

        VECTOR 'TEXT>',_TEXT_IN,_INI

        vaLUe 'BASE',_base,10

        vaLUe 'DICT',_DICT,@VOCTOP
        
        constant 'TIB',_tib,@TIB

        constant 'TBUF',_TBUF,@TBUF

        constant 'FIB',_Fib,@Fib

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
  mov PW [val_+_LTIB],ax
  MOV AX,OFFSET @LOCINI
  mov PW [VAL_+_LOCATE],ax
  
  mov sp,@S_TOP
  mov bp,@R_TOP
  mov si,OFFSET _interpret
  jmp next

; -----------------------
; PRIMITIVES
; -----------------------
  
prim 'EXEC',_exec,0,@EXEC
@PERFORM:
  MOV TOP,[TOP]
@EXEC:
  LEA di,[TOP+2]
  Dpop TOP
  jmp PW [di-2]

prim 'PERFORM',_PERFORM,0,@PERFORM

prim '(;',_RET,0,doRET

;@DDRET:  POP BX
;@DRET:  POP BX
;@RET:   mov si,PW [bp]
;@RDROP: inc bp
;        inc bp
;        jmp next

;prim '(..;',_DDRET,0,@DDRET

DOSETV:
  MOV [WA+2],TOP
DODROP:
  DPOP  TOP
  JMP NEXT

doDEFER:
  mov WA,[WA]
  SCASW
  jmp PW [WA-2]

DOSETP:
  MOV [WA+2],IP
doRET:
  POP   IP
  JMP   NEXT
  
doGETP:
  PUSH IP
  MOV  IP,[WA]
  JMP NEXT

  SCASW
  SCASW
doconst: 
  mov WA,[WA]
  jmp DOvar

doOVER:
  MOV W,[DSP+2]
  SKIPB
doLIT:
  LODSW
@PUSHW:
  DPUSH TOP
  XCHG  W,TOP
  JMP   NEXT

  SCASW
  SCASW
doDOES:
  POP   W
  PUSH  IP
  MOV   IP,AX
  SKIPR  CX
  
  SCASW
  SCASW
DOvar:
  DPUSH TOP
  MOV   TOP,WA
  JMP   NEXT
  
prim 'NOP',_NOP,0,13CH 
docolon = _NOP
  PUSH  IP
  MOV   IP,di
  jmp   NEXT
  
PRIM 'NIP',_NIP,0,@CALL
@NIP:
  DPOP   AX
  RET
  
@NIPCALL:
  CALL @NIP
@CALL:
  CALL  DI
    jmp next

doDUP:
  Dpush bx
  jmp next

doSWAP:
  XCHG TOP,NXT
    jmp next

; -------------------
; Compilation
; -------------------

prim ',',_comma,0,@NIPCALL
  XCHG  W,TOP
  mov WA,PW [VAL_+_dp]
  stosw
  mov PW [VAL_+_dp],WA
  RET

prim 'LIT',_lit,0,doLIT

; -------------------
; Stack
; -------------------

;primitive 'ROT',_ROT,0
;  pop  dx ax
;  push dx

prim 'DROP',_drop,0,doDROP

primitive 'DUP',_dup,0,doDUP

;prim 'PUSH',_pUSH,0,@NIPCALL
;@PUSH:
;  XCHG  SP,BP
;  push  Ax
;  XCHG  SP,BP
;  RET
  
;primitive 'POP',_POP,0
;  push  BX
;  XCHG  SP,BP
;  POP   bx
;  XCHG  SP,BP
;  jmp next

prim 'SWAP',_swap,0,doSWAP

; -------------------
; Maths / Logic
; -------------------

prim 'XOR',_XOR,0,@NIPCALL
  XOR BX,AX
  RET
  
prim 'AND',_AND,0,@NIPCALL
  AND BX,AX
  RET
  
prim '-',_MINUS,0,@NIPCALL
  XCHG  AX,BX
  SUB BX,AX
  RET
  
prim '+',_plus,0,@NIPCALL
  ADD BX,AX
  RET
  

primitive '0=',_Zeq,0
@ZEQ:        
  sub bx,1
  sbb bx,bx
  jmp next

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
; Peek and Poke
; -------------------

primitive '@',_fetch,0
  mov bx,PW [bx]
  jmp next

primitive '!',_store ,0
  CALL @NIP
  MOV [TOP],W
  jmp doDROP

; -------------------
; Inner Interpreter
; -------------------

@DOES2:
  SCASW
@DOES1:
  SCASW
@DOES:
  POP   AX
  PUSH  BX
  MOV   BX,DI
@PUSHIP:  
  XCHG  AX,SI
@RPUSH:
  XCHG  SP,BP
  push  Ax
  XCHG  SP,BP
  
next:   
        ;CALL  @DBG
        MOV    DI,[SI]
        CMPSW
        jmp PW [di-2]

; -------------------
; Flow Control
; -------------------

primitive '(?BR',_IF,0
  test bx,bx
  pop bx
  je @JUMP
  lodsw
  jmp next

primitive '(BR',_JUMP,0
@JUMP:        
  mov si,PW [si]
  jmp next

; -------------------
; String & ARRAY
; -------------------

@LARY:
  SHL   BX,1
@WARY:  
  SHL   BX,1
@BARY:
  ADD   BX,DI
  JMP   NEXT

PRIM 'OPER',_OPER,0,@WARY
  DW _NUMBER,  _EXEC  ; INTERP
  DW _COMPNUM, _COMMA ; COMPILE
  
@0SWAP:
  XOR   AX,AX
  X
  PUSH  AX
  X
  JMP NEXT
  
@COUNT:  
  inc   bx
  Dpush  bx
  DEC   BX
@C@:  
  mov   bl, PB[bx]
  mov   bh,0
  jmp next

prim '0SWAP',_0SWAP,0,@0SWAP

prim 'COUNT',_count,0,@COUNT

prim 'C@',_c@,0,@C@

  primITIVE '>NUM',_tonum,0
  X
  pop di
  pop cx
  pop ax
@@numl: 
  test bx,bx
    je @@numz
  push ax
  mov al,Pb[di]
@@nums: 
  cmp al,'9'+1
    jc @@numg
  AND al,0DFH
  cmp al,'A'
    jc @@numh
  sub al,7
@@numg: sub al,48
  mov   ah,0
  cmp   al,Pb[val_+_base]
    jnc @@numh
  xchg  ax,dx
  pop   ax
  push  dx
  xchg  ax,cx
  mul   Pw[val_+_base]
  xchg  ax,cx
  mul   Pw[val_+_base]
  add   cx,dx
  pop   dx
  add   ax,dx
  dec   bx
  inc   di
    jmp   @@numl
@@numz: 
  push  ax
@@numh: 
  push  cx
  push  di
  X
    jmp next

COLON 'NUM',_NUMBER,0
  DW _0SWAP,_0SWAP,_COUNT,_TONUM,_ZEQ,_IF,@ONERR
@NUMOK: DW _DROP,_DROP,_RET 
  
COLON 'NUM',_COMPNUM,0
  DW _NUMBER,_LITC,_RET
  
; -----------------------
; Terminal Input / Output
; -----------------------

priM 'ACCEPT',_ACCEPT,0,@CALL
  MOV   DI,NXT
  xor  cx,cx
acceptl:
  call acc 
  cmp  Bx,Cx
  jne  acceptl
  jmp next
 
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

@READBIOS:
  XOR   AX,AX
  INT   16H
  RET
  

@BLPARS:
  MOV   BL,32
@PARS:
  PUSH  DI
  MOV   DI,PW [val_+_ETIB]
  MOV   cx,PW [val_+_LTIB]
  XCHG  AX,BX

  ;POP   CX DI AX
  SUB   DI,CX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   DI
  INC   CX
@@SKIPX:
  MOV   DX,DI    ;  START OF THE SOURCE
  JCXZ  @@WEX
  REPNE SCASB
  JNE   @@WEX
  DEC   DI      ; END OF THE SOURCE
@@WEX:          ; CX REST LEN OF BUF
  XCHG  AX,DI
  SUB   AX,DX
  MOV   PW [val_+_LTIB],cx
  mov   BX,PW [val_+_TBUF]
@MAKESTRZ:
  XCHG  SI,DX  ; SAVE IP  ;PUSH  DX      ; START OF THE SOURCE
  MOV   CX,AX
  MOV   DI,BX
  STOSB
  XOR   CH,CH
  REP   MOVSB
  XCHG  SI,DX
  MOV   CL,[BX]
  MOV   PB [DI],'`'
  RET
  
prim 'WORD',_word,0,@PARS
  jmp next

prim 'BLWORD',_BLword,0,@BLPARS
  JCXZ  @@?DUP
  DPUSH  BX
@@?DUP:
  MOV   BX,CX
  jmp next

  prim 'EMIT',_emit,0,@NIPCALL
  XCHG  AX,BX
  jmp outchar

getchar:
  mov ah,7
  int 021h
  mov ah,0
  RET

primITIVE 'S!',_MAKESTR,0
  POP   AX DX
  CALL  @MAKESTRZ
  JMP   next  

; -----------------------
; MEMORY FUNCTIONS
; -----------------------

COLON 'STR',_STR,0
  DW _FETCHP,_SWAP,_RET
  
primITIVE '@+',_FETCHP,0
  X
  PUSH   [BX]
  X
@2P:  
  INC   BX
@1P:  
  INC   BX
  JMP   next  

PRIM '1+',_1P,0,@1P

PRIM '2+',_2P,0,@2P


prim '!-',_STOREM,0,@NIP
  MOV   [BX-2],AX
@2M:  
  DEC   BX
@1M:  
  DEC   BX
  JMP   next  

primITIVE 'MPUSH',_MPUSH,0
  MOV   DI,TOP
  X
  POP   CX AX
  X
  XCHG  AX,SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  XCHG  AX,SI
  JMP   next  
  
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
  POP   DX 
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
  XCHG  BX,AX
xFND?:
  POP   SI
  MOV   NXT,AX 
  MOV   BX,CX 
  RET

; -----------------------
; Colon Definition
; -----------------------

@COMPS:
  CALL  doDOES
@COMPS2  DW _STR,_COMMA,_PERFORM
@EXIT1: 
  DW _RET
    
@DEFS:
  CALL  doDOES
  DW _HEADER,_JUMP,@COMPS2
  
PRIM ':',_COLON,0,@DEFS  
  DW DOCOLON,_RPAR
  
PRIM ';`',_semicolon,0,@COMPS  
  DW _RET,_RPAR
  
PRIM 'LIT`',_LITC,0,@COMPS  
  DW _LIT,_COMMA
  
; -----------------------
; Headers
; -----------------------

COLON 'HEADER',_HEADER,0
  DW _DP

colon '=:',_ENTRY,0
    dw _LIT,0,_DUP,_Blword,_IF,@ONERR
    DW _DUP,_C@,_1P,_DICT,_MPUSH
    DW _STOREM,_STOREM,TO_+_DICT,_RET

PRIM 'CREATE',_create,0,@DEFS
  DW DOVAR,_NOP

;COLON '''',_TICK,0
;  DW _Blword,_IF,@ONERR,_FIND,_IF,@ONERR,_RET
  
;  primitive '(;CODE)',_do_semi_code,0
;  mov di,PW [val_+_last]
;  mov al,PB [di+2]
;  and ax,31
;  add di,ax
;  mov PW [di+3],si
;  jmp @RET

; -----------------------
; Constants
; -----------------------

PRIM 'CONST',_constant,0,@DEFS
  DW doconst,_COMMA
  
; -----------------------
; Outer Interpreter
; -----------------------

COLON '>,',_RPAR,0  
  DW TO_+_LOCATE,_TBUF,_CFND,_DUP,_IF,@NOTFOUND,_RET
@NOTFOUND:  
  DW _DROP,_FND,_2P,_RET
  
COLON ',<',_LPAR,0
  DW TO_+_LOCATE
@LOCINI: DW _TBUF,_FND,_RET 
  
@ONERR   dw _aborDOT

COLON 'VIN',_VIN,0
  DW _TIB,_LIT,64,_ACCEPT,_RET
  
COLON '(I',_INI,0
  DW _LIT,_VIN,TO_+_TEXT_IN,_LIT,80H,_COUNT,_RET

_interpret:
  DW _TEXT_IN,_EVAL,_JUMP,_interpreT  

final:
COLON 'EVAL',_EVAL,0    ; ADR LEN -> INTERPRET
  DW _DUP,TO_+_LTIB,_PLUS,TO_+_ETIB
@EVAL:        
  DW _DUP,_BLWORD,_IF,@EXIT1
  DW _LOCATE,_OPER,_PERFORM,_JUMP,@EVAL

freemem:

MyCseg  ends
        end  Start

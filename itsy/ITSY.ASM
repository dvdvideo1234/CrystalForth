 link =  0
 TEMP = 0
immediate  = 080h
locals  @@
VAL_ = 2

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr


nam_    macro   msg,FLAG
  local endstr
  db    endstr-$-1+FLAG
  db    msg
endstr  label   byte
        endm

HEAD MACRO  NAM,LBL,FLAG
TEMP = $
  DW LINK
LINK = TEMP
  NAM_ NAM,FLAG
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

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 0100h

Start   Label byte

        jmp @aborT

; -------------------
; Variables
; -------------------

        variable 'STATE',_state,0

        variable '>IN',_ETIB,0

        variable '#tib',_LTIB,0

        variable 'DP',_dp,freemem

        variable 'ACCEPT',_accept,_INI

@P2:
  INC   BX
  INC   BX
  JMP   NEXT
        
        variable 'BASE',_base,10

        variable 'LAST',_last,final
        
        constant '0',_0,0

        constant 'BL',_BL,32

        constant 'TIB',_tib,128

; -------------------
; Initialisation
; -------------------

primitive 'ABORT',_aborDOt,0
  MOV AX,PW [VAL_+_DP]
  CALL @STROUT
  MOV AL,'?'
  CALL @COUT
@ABORT:
  xor bp,bp
  mov PW [VAL_+_state],bp
  mov PW [val_+_LTIB],BP
  mov sp,-256
  mov si,OFFSET _interpret
  jmp next

; -------------------
; Compilation
; -------------------

@DRCALL:
  POP   AX
  XCHG  AX,BX
@CALL:
  CALL  DI
    jmp next

prim ',',_comma,0,@DRCALL
@COMMA:
  mov di,PW [VAL_+_dp]
  stosw
  mov PW [VAL_+_dp],di
  RET

primitive 'LIT',_lit,0
  lodsw
  jmp @PUSHW

; -------------------
; Stack
; -------------------

primitive 'ROT',_ROT,0
  pop  dx ax
  push dx
@PUSHW:
  push bx
  xchg ax,bx
  jmp next

primitive 'DROP',_drop,0
@DROPW:        
  pop bx
  jmp next

primitive 'DUP',_dup,0
  push bx
  jmp next

prim 'PUSH',_pUSH,0,@DRCALL
@PUSH:
  XCHG  SP,BP
  push  Ax
  XCHG  SP,BP
  RET
  
primitive 'POP',_POP,0
  push  BX
  XCHG  SP,BP
  POP   bx
  XCHG  SP,BP
  jmp next

primitive 'SWAP',_swap,0
  pop ax
  jmp @PUSHW

; -------------------
; Maths / Logic
; -------------------

@XOR:
  pop ax
  XOR bx,ax
  JMP DI

primitive '-',_MINUS,0
  NEG BX
@plus:        
  pop ax
  add bx,ax
  jmp next

prim '+',_plus,0,@plus

primitive '0=',_Zeq,0
@ZEQ:        
  sub bx,1
  sbb bx,bx
  jmp next

PRIM '=',_equals,0,@XOR
  JMP SHORT @ZEQ

; -------------------
; DEBUGER
; -------------------

PRIM 'TR-',_TRM,0,@CALL
  MOV PB [NEXT],0B8H
  RET

PRIM 'TR',_TR,0,@CALL
  MOV PB [NEXT],0E8H
  RET

PRIM 'H.',_HDOT,0,@DRCALL
@HDOT:
  CALL  @WORDOUT
@SPDOT:  
  MOV   AL,' '
  JMP   @COUT
  
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
  
@DIGOUT:
  AND   AL,15
  CMP   AL,10
  JC    @DIG1
  ADD   AL,7
@DIG1:
  ADD   AL,'0'
  JMP   @COUT

@STRID:
  PUSH  CX DX DI
  MOV   DX,-1
  MOV   CX,32
  XCHG  AX,DI
@@IDLP:  
  INC   DX
  DEC   DI
  MOV   AL,[DI]
  AND   AL,127
  CMP   AL,DL
  JE    @@IDLPX
  LOOP  @@IDLP
@@IDLPX:
  XCHG  AX,DI
  POP   DI DX CX 
  RET
  
@STROUT:
  PUSH  CX DI
  XCHG  AX,DI
  MOV   AX,[DI]
  AND   AX,127
  MOV   CX,AX
@LPSTR:
  INC   DI
  MOV   AL,[DI]
  CALL  @COUT
  LOOP  @LPSTR
  POP   DI CX 
  JMP   @SPDOT
  
@CRDOT:  
  MOV   AL,13
  CALL  @COUT
  MOV   AL,10
  JMP   @COUT
  
@DBG:
  CALL  @PUSH   ; AX      1
  CALL  @CRDOT  ; AX .
  POP   AX
  CALL  @PUSH   ; RETADR  2
  ;CALL  @HDOT
  MOV   AX,SI   ; IP
  CALL  @HDOT
  MOV   AX,SP   ; DSP
  CALL  @HDOT
  LEA   AX,[BP+4]
  CALL  @HDOT   ; RSP
  CALL  @SPDOT

  ;ROT H.
  POP   AX
  CALL  @PUSH   ; DSP[2]  3
  POP   AX
  PUSH  AX
  CALL  @HDOT   ; DSP[3] .

  CALL  @POP    ; DSP[2] . 3
  PUSH  AX
  CALL  @HDOT
  MOV   AX,BX   ; DSP[1] .
  CALL  @HDOT
  
  CALL  @POP    ; RETADR BACK  2
  PUSH  AX
  MOV   AX,[BP]
  CALL  @HDOT  
  MOV   AX,CX
  CALL  @HDOT
  MOV   AX,DX
  CALL  @HDOT
  CALL  @SPDOT
  MOV   AX,PW[VAL_+_DP]
  CALL  @HDOT

  MOV   AX,[SI]
  CALL  @STRID
  CALL  @STROUT
  CALL  @READBIOS
@POP:
  XCHG  SP,BP
  POP   AX
  XCHG  SP,BP
  RET
  
; -------------------
; Peek and Poke
; -------------------

primitive '@',_fetch,0
  mov bx,PW [bx]
  jmp next

primitive '!',_store ,0
  pop PW [bx]
  jmp @DROPW

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
        CALL  @DBG
        MOV    DI,[SI]
        CMPSW
        jmp PW [di-2]

; -------------------
; Flow Control
; -------------------

PRIM 'BYE',_BYE,0,0

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

prim 'EXEC',_exec,0,@EXEC
@PERFORM:
  MOV BX,[BX]
@EXEC:
  LEA di,[bx+2]
  pop bx
  jmp PW [di-2]

prim 'PERFORM',_PERFORM,0,@PERFORM

prim '(;',_RET,0,@RET
@DDRET:  POP BX
@DRET:  POP BX
@RET:   mov si,PW [bp]
@RDROP: inc bp
        inc bp
        jmp next

prim '(..;',_DDRET,0,@DDRET

; -------------------
; String & ARRAY
; -------------------

@OPER:
  INC   BX
  MOV   CX,PW _STATE+VAL_
  JCXZ  @WARY
  ADD   BX,3
@WARY:  
  SHL   BX,1
@BARY:
  ADD   BX,DI
  JMP   NEXT

PRIM 'OPER',_OPER,0,@OPER
  ; IMMEDIATE  NFND NOIMMED
  DW _EXEC, _NUMBER,  _EXEC  ; INTERP
  DW _EXEC, _COMPNUM, _COMMA ; COMPILE
  
@TONUM:
  XOR   AX,AX
  PUSH  AX AX
@COUNT:  
  inc   bx
  push  bx
  DEC   BX
  mov   bl, PB[bx]
  mov   bh,0
    JMP DI

prim 'COUNT',_count,0,@COUNT
    jmp next

  prim '>NUM',_tonum,0,@TONUM
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
    jmp next

COLON 'NUM',_NUMBER,0
  DW _TONUM,_ZEQ,_IF,@ONERR
@NUMOK: DW _DDRET 
  
COLON 'NUM',_COMPNUM,0
  DW _NUMBER,_LITC,_RET
  
; -----------------------
; Terminal Input / Output
; -----------------------
prim '>AXP',_aXP,0,@ACCEP

priMITIVE 'ACPT',_ACPT,0
;  DW _tib,_lit,50,_aXP,_RET
  PUSH  BX
  MOV   BX,PW [_TIB+VAL_]
  PUSH  BX
  DEC   BX
  ;CALL @DBG
@ACCEP:  
  CALL @CRDOT
  MOV   AL,'>'
  CALL @COUT
  
  POP   DI
  PUSH  DI
  xor  cx,cx
acceptl:
  call acc 
  jnC  acceptl
  jmp next
 
acc1:	
  MOV   AL,7
  call outchar
acc:
  call getchar   
	cmp  al,8
        jne  acc2
        jCXz   acc1
  CLC
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
  STC
  JMP @SPDOT

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
  PUSH  BX
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
  RET
  
@MAKESTRZ:
  mov   BX,PW [val_+_dp]
  XCHG  SI,DX  ; SAVE IP  ;PUSH  DX      ; START OF THE SOURCE
  MOV   DI,BX
  MOV   CX,AX
  STOSB
  XOR   CH,CH
  REP   MOVSB
  XCHG  SI,DX
  MOV   CL,[BX]
  RET
  
prim 'WORD',_word,0,@PARS
  CALL  @MAKESTRZ
  jmp next

prim 'BLWORD',_BLword,0,@BLPARS
  CALL  @MAKESTRZ
  JCXZ  @@?DUP
  PUSH  BX
@@?DUP:
  MOV   BX,CX
  jmp next

  prim 'EMIT',_emit,0,@DRCALL
  jmp outchar

getchar:
  mov ah,7
  int 021h
  mov ah,0
  RET

; -----------------------
; Dictionary Search
; -----------------------

prim '(FND',_find,0,@FND
@FND:
  PUSH SI
  PUSH   PW  _last+VAL_
findL:
  POP   SI
  MOV   DX,SI
  MOV   CX,DX
    jCXz  findnf
  LODSW
  PUSH  AX    ; LINK TO NEXT
  
  MOV   DI,BX
  LODSB
	AND  AX,31
  SCASB       ; LENGTH = ?
    JNE   findL
  
  XCHG  CX,AX
  rep  cmpsb
    jNe   findL
  
  POP   AX      ; DISCARD LINK
  INC   CX      ; FLAG FOUND
  mov   BX,si
  MOV   SI,DX
  TEST  PB [SI+2],080H  ; IMMEDIATE ?
    JZ    FINDNF
  NEG   CX
  
findnf:
  POP  sI
	push bx
	mov  Bx,cx
    jmp next

; -----------------------
; Colon Definition
; -----------------------

PRIMITIVE 'STR',_STR,0
  XCHG BX,SI
  LODSW
  PUSH  SI
  XCHG BX,SI
  XCHG AX,BX
  JMP NEXT
  
@STATES:
  CALL  @DOES
  DW _FETCH,_STATE,_STORE
@EXIT1: 
  DW _RET
  
@COMPS:
  CALL  @DOES
@STAT:  DW _STR,_COMMA,_PERFORM,_RET
  
@DEFS:
  CALL  @DOES
  DW _HEADER,_JUMP,@STAT
  
PRIM ']',_RPAR,0,@STATES  
  DW -1
  
PRIM '[',_LPAR,IMMEDIATE,@STATES  
  DW 0
  
PRIM ':',_COLON,0,@DEFS  
  DW DOCOLON,_RPAR
  
PRIM ';',_semicolon,IMMEDIATE,@COMPS  
  DW _RET,_RPAR
  
PRIM '[LIT]',_LITC,IMMEDIATE,@COMPS  
  DW _LIT,_COMMA
  
  
PRIM 'NOP',_NOP,0,13CH

docolon = _NOP
  XCHG AX,di
  jmp @PUSHIP
  
;colon ';',_semicolon,immediate
;  dw _lit,_RET,_comma,_0,_state
;  dw _store
;@EXIT1:  
;  DW _RET

; -----------------------
; Headers
; -----------------------

colon 'HEADER',_HEADER,0
    dw _dp,_fetch,_last,_fetch,_comma
    dw _last,_store,_Blword,_IF,@ONERR,_count   ;IF EMPTY
    dw _plus,_dp,_store,_RET

PRIM 'CREATE',_create,0,@DEFS
  DW DOVAR,_NOP

dovar:
  XCHG  AX,DI
  jmp @PUSHW

COLON '''',_TICK,0
  DW _Blword,_IF,@ONERR,_FIND,_IF,@ONERR,_RET
  
  primitive '(;CODE)',_do_semi_code,0
  mov di,PW [val_+_last]
  mov al,PB [di+2]
  and ax,31
  add di,ax
  mov PW [di+3],si
  jmp @RET

; -----------------------
; Constants
; -----------------------

PRIM 'CONST',_constant,0,@DEFS
  DW doconst,_COMMA
  
doconst: 
  mov Ax,PW [di]
  jmp @PUSHW

; -----------------------
; Outer Interpreter
; -----------------------

@ONERR: DW _dp,_FETCH,_STATE,_FETCH,_IF,@intnc
  DW _last,_fetch,_dup,_fetch,_last,_store,_dp,_store ; CLEAR GARBIGE WORD
@intnc   dw _aborDOT

COLON '(I',_INI,0
  DW _LIT,_ACPT,_ACCEPT,_STORE,_TIB,_COUNT,_RET

_interpret:
  DW _ACCEPT,_PERFORM,_EVAL,_JUMP,_interpreT  

PRIMITIVE '>EVAL',_TOEVAL,0    ; ADR LEN -> INTERPRET
  ;DW _DUP,_LTIB,_store,_PLUS,_ETIB,_store
  POP   AX
  MOV   PW[_LTIB+VAL_],BX
  ADD   AX,BX
  MOV   PW[_ETIB+VAL_],AX
  POP   BX
  JMP   NEXT

final:
COLON 'EVAL',_EVAL,0    ; ADR LEN -> INTERPRET
  DW _TOEVAL  ;_DUP,_LTIB,_store,_PLUS,_ETIB,_store
@EVAL:        
  DW _BLWORD,_IF,@EXIT1
  DW _FIND,_OPER,_PERFORM,_JUMP,@EVAL

freemem:

MyCseg  ends
        end  Start

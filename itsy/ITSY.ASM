
INCLUDE ITSY.IMC

DIVE EQU DUCK

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

        constant 'TIB',_tib,0,@TIB

        constant 'FIB',_Fib,0,@Fib

        VECTOR 'TEXT>',_TEXT_IN,0,_INI

        vaLUe 'BASE',_base,0,10

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
  
prim '0SWAP',_0SWAP,0,@0SWAP

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
  DW _0SWAP,_0SWAP,_COUNT,_TONUM,_ZEQ,_IF,_@ONERR
@NUMOK: DW _DROP,_DROP,_RET 
  
COLON 'NUM',_COMPNUM,0
  DW _NUMBER,_LITC,_RET
  
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

@BLPARS:
  CALL  @DUP
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
  MOV   CX,DX
@MAKESTRZ:
  MOV   DI,BX
  STOSB
  XCHG  AX,CX  
  XOR   CH,CH
@TOADR:  
  XCHG  SI,AX  ; SAVE IP  ;PUSH  DX      ; START OF THE SOURCE
  REP   MOVSB
  XCHG  SI,AX
  MOV   CL,[BX]
  RET
  
  prim 'EMIT',_emit,0,@NIPCALL
  XCHG  W,TOP
  j outchar

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

COLON 'STR',_STR,0
  DW _FETCHP,_SWAP,_RET
  
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
  STC
  ADC   [BX+2],CX
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
  CALL  _@DOES
@COMPS2  DW _STR,_COMMA,_PERFORM
@EXIT1: 
  DW _RET
    
@DEFS:
  CALL  _@DOES
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
    dw _LIT,0,_Blword,_IF,_@ONERR
    DW _DUP,_C@,_1P,_DICT,_MPUSH
    DW _STOREM,_STOREM,TO_+_DICT,_RET

PRIM 'CREATE',_create,0,@DEFS
  DW DOVAR,_NOP

COLON '''',_TICK,0
  DW _Blword,_IF,_@ONERR,_FND,_IF,_@ONERR,_RET
  
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
  DW _DROP,_TBUF,_FND,_2P,_RET
  
COLON ',<',_LPAR,0
  DW TO_+_LOCATE
@LOCINI: DW _TBUF,_FND,_RET 
  
_@ONERR   dw _aborDOT

COLON 'VIN',_VIN,0
  DW _TIB,_LIT,64,_ACCEPT,_RET
  
_interpret:
  DW _TEXT_IN,_EVAL,_JUMP,_interpreT  

prim '(;',_RET,0,doRET

; -----------------------
; PRIMITIVES
; -----------------------

prim 'PERFORM',_PERFORM,0,@ldNIPC
  SKIPA
prim 'EXEC',_exec,0,@NIPCALL
  XCHG  W,TOP
  XCHG  W,WA
  SKIPA
doDEFER:
  mov WA,[WA]
  SCASW
  jmp PW [WA-2]

; -------------------
; Flow Control
; -------------------

prim '(?BR',_IF,0,@JPNIP
  XCHG TOP,W
  je @JUMP
@SKIP:  
  lodsw
  jJ next

primitive '(BR',_JUMP,0
@JUMP:        
  mov IP,PW [IP]
  jJ next

priM 'ACCEPT',_ACCEPT,0,@CALL
  MOV   DI,NXT
  xor  cx,cx
acceptl:
  call acc 
  cmp  Bx,Cx
  jne  acceptl
  jJ next
 
prim 'S!',_MAKESTR,0,@JP2NIP
  XCHG   AX,CX
  CALL  @MAKESTRZ
  JJ   next  

prim 'MOVTO',_TOADR,0,@JP2NIP
  MOV   DI,BX
  CALL  @TOADR
  JJ   next  

prim 'WORD',_word,0,@PARS
  MOV   PB [DI],'`'
  jJ next

prim 'BLWORD',_BLword,0,@BLPARS
  MOV   PB [DI],'`'
  JCXZ  @@?DUP
  DPUSH  BX
@@?DUP:
  MOV   BX,CX
  jJ next

DOSETV:
  MOV [WA+2],TOP
  SKIPB
@RDROP:
  POP   IP
DODROP:
  DPOP  TOP
  JJ NEXT

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
  DPUSH TOP
  MOV   TOP,WA

; -------------------
; Inner Interpreter
; -------------------

next:   
  ;CALL  @DBG
  MOV    WA,[IP]
  CMPSW
  jmp PW [WA-2]

  SCASW
  SCASW
doconst: 
  mov WA,[WA]
  j DOvar

doOVER:
  MOV W,[DSP+2]
  SKIPB
doLIT:
  LODSW
@PUSHW:
  XCHG  W,WA
  J   DOvar

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
  MOV  IP,[WA]
  J NEXT

prim 'NOP',_NOP,0,13CH 
docolon = _NOP
  PUSH  IP
doLbl:  
  MOV   IP,WA
  j   NEXT
  
doSWAP:
  XCHG TOP,NXT
    j next

primITIVE '@+',_FETCHP,0
  X
  PUSH   [TOP]
  X
@2P:  
  INC   TOP
@1P:  
  INC   TOP
  J   next  


prim 'U<',_ULESS,0,@NIPCALL
  SUB BX,AX
  JJ @ZEQ
 

primitive '0=',_Zeq,0
  sub bx,1
@Zeq:
  sbb bx,bx
  j next

prim '!-',_STOREM,0,@JPNIP
  MOV   [TOP-2],AX
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

primitive '!',_store ,0
  CALL @NIP
  MOV [TOP],W
  j doDROP

@0SWAP:
  XOR   AX,AX
  X
  PUSH  AX
  X
  J NEXT
  
prim 'COUNT',_count,0,@JP1PDUP
  DEC   BX
@C@:  
  mov   bl, PB[bx]
  mov   bh,0
  j next

@ldNIPC:
  mov top,[top]
@NIPCALL:
  CALL @NIP
@CALL:
  CALL  DI
    j next

prim 'MPUSH',_MPUSH,0,@JP2NIP
  MOV   DI,TOP
  XCHG  AX,SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  XCHG  AX,SI
  J   next  
  
PRIM '2NIP',_2NIP,0,@CALL
  SKIPB
@JP2NIP:
  PUSH  WA
@2NIP:
  X
  POP   W CNR
  X
  RET
  
PRIM 'NIP',_NIP,0,@CALL
  SKIPB
@JPNIP:
  PUSH  WA
@NIP:
  DPOP   W
  test TOP,TOP
  RET
  
PRIM 'DUP',_DUP,0,@CALL
  SKIPA
@JP1PDUP:
  INC TOP
@JPDUP:
  PUSH  WA
@DUP:
  Dpush TOP
  RET

COLON '(I',_INI,0
  DW _LIT,_VIN,TO_+_TEXT_IN,_DP,_STR,_DICT,_MPUSH,TO_+_DICT
  DW _LIT,80H,_COUNT,_RET

final:
COLON 'EVAL',_EVAL,0    ; ADR LEN -> INTERPRET
  DW _DUP,TO_+_LTIB,_PLUS,TO_+_ETIB
@EVAL:        
  DW _DUP,_BLWORD,_IF,@EXIT1
  DW _LOCATE,_OPER,_PERFORM,_JUMP,@EVAL
  
ENDADR:  
  DW  FREEMEM-ENDADR
  ENTRY '=:',_ENTRY 

freemem:    ; ITSY.COM 958 965 954 949 932 938

MyCseg  ends
        end  Start

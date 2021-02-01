DBG   = 1
NAMES = 1
INCLUDE NF7.INC

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@TBUF   = -256          ; 256
@TIB    = @TBUF * 2     ; 256
@R_TOP  = @TIB * 2      ; 512  RSTACK
@S_TOP  = @R_TOP * 2    ; 1024 DSTACK
@VOCTOP = @S_TOP * 2    ; 2048 = 4 BUFFERS * 512

Start   Label byte
  mov   bx,1000h          ; only 64k allocate
  mov   ah,4ah
  int   21h
@ABORT:
  MOV   DSP,@S_TOP
__QUIT:  
  MOV   RSP,@R_TOP
  CALL  __TOF
  DW    @INIT
@MAINLP:                  ; TEXT INTERPRETTER
  DW _TIB,_TBL
__@ACCEPT:
  DW _ACCZ,_EVAL
__@OK:
  FIX_ _OK
  DW _JUMP,@MAINLP

POINT_  @INIT,__@INI

;---------------------------------------------------
; TRANSFER      COMMANDS  STR @ !+  C!+  XA XR  1+ 2+ 

@STR:
  LEA   T,[TOP+2]
  PUSH  T
@LD:
  MOV   TOP,[TOP]
  JMPS  @MAIN

@STP:
  POP   [TOP]
__2P:
  INC   TOP
@1P:  
  INC   TOP
  JMPS @MAIN

__XA:
  XCHG  AR,[RSP]
  JMPS  @MAIN

__XR:
  XCHG  TOP,[RSP]
  JMPS  @MAIN

;--------------------------------------------------------
; TRANSFER      C!+   1- 2-  !-  (BARY (WARY (LARY (SETV

@_DARY:
  SHL   TOP,1
@_LARY:
  SHL   TOP,1
@_WARY:
  SHL   TOP,1
@_BARY:
  ADD   TOP,W
  JMPS  @MAIN

@STM:
  POP   [TOP-2]
__2M:
  DEC   TOP
__1M:  
  DEC   TOP
  JMPS @MAIN

__@setvar:
  MOV   [W+2],TOP
  JMPS  @DROP  
  
;---------------------------------------------
; LOGICAL      COMMANDS  XOR NAND NOT 0= U<

_XOR DW @_NIP
  XOR   TOP,T
  JMPS  @MAIN

_NAND DW @_NIP
  AND   TOP,T
;  SKIPB
;__NEG:
;  DEC   TOP
__NOT:  
  NOT   TOP
  JMPS  @MAIN

;_EQ DW @_NIP
;  SUB   TOP,T
@ZEQ:
  SUB   TOP,1
  JMPS  @ULES
_ULES DW @_NIP
  SUB   T,TOP
@ULES:
  SBB   TOP,TOP
  JMPS   @MAIN
__STOD:
  PUSH  TOP
__ZLESS:
  SHL   TOP,1
  JMPS  @ULES

__TOF:    
IF DBG
  CALL  @DEBUGOFF
  ;CALL  @DEBUGON
ELSE 
  CALL  @NODEBUG
ENDIF  
@TOF:
  POP   IP
  SKIPA
__RDROP:
  INC   RSP
  INC   RSP
  SKIPB
@DUP: 
  PUSH   TOP
  JMPS   @MAIN

@INC:
  INC   PW [TOP]
  JMPS  @DROP  

@DEC:
  DEC   PW [TOP]
  JMPS  @DROP  

@EMIT: ; dos function number EMIT
  XCHG  TOP,T
  MOV   AH,0EH
  INT   010H
@DROP:
  DPOP  TOP
  JMPS   @MAIN

@_POINT:
  MOV   W,[W]
  JMPS  @NESTW

; MAIN  LOOP
@DOES3:
  SCASW
@DOES2:
  SCASW
__@does:
  POP   T
  XCHG  T,W
  PUSH  TOP
  XCHG  T,TOP
@NEST:
_NOP:  SKIPB		; 13CH = NOP
  DB	1
@NESTW:  
  XCHG  W,IP
@RPUSHW:  
  X
  PUSH  W
@XMAIN:  
  X
@MAIN:
  MOV   W,[IP]
  CMPSW
  JMP   [W-2]
  
IF DBG
@TODEBUG:
  JMP  @DEBUGER
ELSE 
  JMP  @NODEBUG
ENDIF  

@_CONS3:
  SCASW
@_CONS2:
  SCASW
__@CONS:
  MOV   T,[W]
@DPUSH:
  DPUSH TOP
  XCHG  TOP,T
  JMPS   @MAIN
  
;------------------------------------------------
; RETURN STACK COMMANDS  POP PUSH XCHG EX @_STR
__POP: 
  PUSH  TOP
  X
  POP   TOP
  JMPS  @XMAIN

__J:
  MOV   T,[RSP+2]
  JMPS   @DPUSH

;_NIP: DW @_NIP      ; SWAP
;  SKIPA
__OVER:       ; OVER
  POP    T
  PUSH   T
  SKIPB
@LIT:
  LODSW
  JMPS   @DPUSH

_SWAP: DW @_NIP      ; SWAP
  SKIPA
@_VAR2:
  SCASW
__@VAR:
  XCHG   T,W
  JMPS   @DPUSH

P_ _BK
  CLR   T
  INT   16H
  ?Z    TL
  JE    @BK
  CLR   TH
@BK:
  JMPS  @DPUSH
  
;-------------------------------------
; CONTROL  (IF (IF- (-IF (NEXT (JUMP (FOR PUSH (DOES (DEFR

__RDROPX:
  INC   RSP
  INC   RSP
  JMPS  @RETURN
@_SETPNT:
  MOV   [W+2],IP
  SKIPB
@DROPX:  
  POP   TOP
@RETURN:
  X
@RETN:  
  POP   IP
  JMPS  @XMAIN

__MIF:
  INC  TOP
@IFM:
  DEC  TOP
  JMPS @NEXT0
  
__NEXT:    ; (NEXT
  DEC   PW [RSP]
@NEXT0:  
  JS    __SKIP

@JUMP:    ; (JUMP
  MOV   IP,[IP]
  JMPS  @MAIN

@IF:  
  ?Z    TOP
  POP   TOP
  JE    @JUMP
__SKIP:
  LODSW
  JMPS  @MAIN

; CONTROL      COMMANDS

@PERFORM: 
  POP   W
  XCHG  W,TOP
__@defer:
  MOV   W,[W]
  OR    W,W
  JZ    @MAIN
  SCASW
  JMP   [W-2] 

__FOR:
  MOV   IP,[IP]
__PUSH:
  XCHG  W,TOP
  POP   TOP
  JMPS  @RPUSHW
  
_P2DIV:	DW @_NIP
  ADD   TOP,T
  PUSH  TOP
  RCR   TOP,1  
  JMPS  @MAIN  
  
;  CHAR etib ltib  /  START LEN ltib
_PARS  DW @PUSHIPD
  POP   CX W T
  SUB   W,CX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   W
  INC   CX
@@SKIPX:
  MOV   BX,W    ;  START OF THE SOURCE
  JCXZ  @@WEX
  REPNE SCASB
  JNE   @@WEX
  DEC   W      ; END OF THE SOURCE
@@WEX:          ; CX REST LEN OF BUF
  PUSH  BX      ; START OF THE SOURCE
  SUB   W,BX
  PUSH  W
  JMPS  @FND?

_num DW @PUSHIPD     ;= (>#       ; (NUM
  POP   CX SI
  MOV   T,10  ; base := 10
  CALL  @NUM@
@NUM2:  
  PUSH  BX
@FND?:
  PUSH  CX
@RET2DR:
  POP   TOP
@RET2:
  X
  POP   AR
  JMPS  @RETN

_INT DW @PUSHIPD
  POP   T
  MOV   PB @AINT,TL
  POP   AX BX CX DX 
  PUSH  RSP DS ES 
  INT   21H
@AINT = $-1
  POP   ES DS RSP
  PUSH  DX CX BX AX
  PUSHF  
  JMPS  @RET2DR

;  MOV   DI,bX   ; TOP OF DICTIONARY

_FND  DW @PUSHIP
  JMPS  @CHK?
  
_MFND  DW @PUSHIPD
  MOV   CL,4
  ADD   CL,[BX+3]
  POP   W
NEXTfnd:
  ADD   W,CX
  MOV   BX,W
@CHK?:  
  POP   SI
  PUSH  SI
  LEA   W,[BX+3]
  mov   cl,[W]
  Jcxz  @FND?
  INC   CX
  repe  cmpsb
  jNZ   NEXTfnd
  POP   SI
  PUSH  BX
  inc   cx        ; fnd_ok
  JMPS  @FND?

_MAKESTR DW @PUSHIPD
  POP   DI AX SI
  STOSB
  MOV   cL,AL
  REP   MOVSB   ; NAME  MOVE
  MOV   PB [W],'`'
  JMPS  @RET2

_MPUSH DW @PUSHIPD
  POP   DI CX SI
@MPUSH:  
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  JMPS  @RET2
  
_STRPUSH DW  @PUSHIPD
  POP   DI SI
  MOV   CL,[SI]
  INC   CX
  JMPS  @MPUSH
  
@NUM@:
  CALL  @@numini
  CALL  @@SGN
@@NUMZ:
  CALL  @@N1
  JMPS  @@NUMZ

@@n1:
  cmp   al,'$'     ; BASE := 16
  JNE   @@N2
  MOV   al,16
  jmp   SHORT @@setbas

@@N2:   cmp  al,'#'     ; BASE := CX
  JNE   @@N3
  mov   al,Bl
@@numini:
  Xor   Bx,Bx      ; ACCUMULATOR
@@setbas:
  mov   W,T
@@END?:
  JCXZ  @@ERNUM
@@GETC:
  deC   CX
  LODSB
  RET

@@N3:
  cmp   al,'9'+1
  jc    @@ton2
  AND   AL,0DFH
  cmp   al,'A'      ; no case sensivity
  jc    @@ERNUM
  sub   al,7
@@ton2:
  sub   al,'0'
  cmp   T,W
  jnc   @@ERNUM
  xchg  T,Bx
  mul   W
  xchg  T,Bx
  add   Bx,T
  JCXZ  @@EXNUM
  JMP   @@GETC
@@ERNUM:
  INC   CX
@@EXNUM:
  pop   AR    ; rdrop
@@noEXn:
  RET

@@SGN:
  CMP   AL,'-'     ; SGN
  JNE   @@N1
  POP   AR
  CALL  @@END?
  CALL  AR
  NEG   bX
  RET

_SDIV		DW @_NIP		; -/,
  SHL	  T,1
  RCL   TOP,1
  CMP   TOP,AR
  JB	  @MDIV
  SUB   TOP,AR
@INCT:  
  INC	  T
@MDIV: 
  PUSH  T
  JMPS 	@MAIN1

@RXCDZ:
  CLR   TH
@RXCD:
  PUSH  TOP
  SKIPA
@RXC:
  POP   T
  XCHG  TOP,T
  XCHG  IP,[RSP]
  CALL  W
@EX:
  XCHG  IP,[RSP]
@MAIN1:
  JMP   @MAIN

_RLDP DW @RXCD
  LODSW
  XCHG  TOP,T
  RET 
  
_RSTP DW @RXC
  MOV   [IP],T
  LODSW
  RET
  
_RSTPB DW @RXC
  MOV   [IP],TL
  LODSB
  RET
  
_@_STR DW @RXCDZ
  MOV   TOP,IP
  LODSB
  ADD   IP,T
  RET
  
_PMUL	DW @_NIP			; +*,
  TEST	TL,1
  JE    @PMUL2
  ADD   TOP,AR
@PMUL2:
  RCR   TOP,1
  RCR   T,1
  JMPS	@MDIV
  
_ACCZ: DW @_NIPDX
  XCHG TOP,T
  MOV   PB [TOP],TL
  MOV   T,0A00H
  INT   21H
  POP   AR
  INC   TOP
@COUNT:  
  INC   TOP
  PUSH  TOP
  DEC   TOP
@LDB:  
  MOV   TOPH,[TOP]
__HWTOB:
  MOV   TOPL,TOPH
__WTOB:
  CLR   TOPH
  JMPS  @MAIN1  

@_NIPDX:
  POP   T
  PUSH  AR
  MOV   AR,T
  SKIPB
@_NIP:
  POP   T
  JMP   W
  
@PUSHIPD:
  PUSH  TOP 
@PUSHIP:
  CLR   CH
  PUSH  DI
@IPAR:
  X
  PUSH IP AR
  X
@NODEBUG:  
  RET

  
  
; DATA STACK   COMMANDS  DUP DROP


XT_ _JUMP,@JUMP       ; ^
XT_ _RET,@RETURN      ; ^
XT_ _IFM,@IFM         ; ^
XT_ _IF,@IF           ; ^
XT_ _EX,@EX
XT_ _1P,@1P
XT_ _DEC,@DEC
XT_ _INC,@INC
XT_ _BE,@EMIT
XT_ _STP,@STP
XT_ _LD,@LD           ; @
XT_ _PERFORM,@PERFORM
XT_ _STM,@STM
XT_ _STR,@STR        ; STR
XT_ _ZEQ,@ZEQ
XT_ _C@,@LDB
XT_ _ABORT,@ABORT
XT_ _DROPX,@DROPX
XT_ _DROP,@DROP
XT_ _LIT,@LIT
XT_ _DUP,@DUP
XT_ _CSTR,@COUNT


L_ _ADD
  DW _P2DIV
@ABORTX  DW _DROPX
  
CONST_  _TBL,80H
CONST_  _TIB,-512
CONST_  _TBUF,-256
CONST_  _0,0
        _BYE  = $-2
CONST_  _BL,32
     
VALUE_  _H,FREEMEM
VALUE_  _ETIB,0
VALUE_  _LTIB,0
VALUE_  _DICT,@VOCTOP
POINT_  _FIND,__@DICTPTR

_OPERAT DW @_WARY,_NUMBER,_PERFORM,_COMP_NUM,_@COMMA

  DW @_CONS3,__@setvar
L_ _EMIT
  DW _BE,_CNTC,_INC,_RET
VAR_    _CNTC,0
  
  DW @_CONS3
VECTOR_ _KEY,_BK

@_commaer:
  call __@does
@commaer:
  dw _STR,_comma,_perfORM,_RET

@_MAKER:
  call __@does
__@HERE:  ; _HERE !!!
  dw _H,_ENTRY,_JUMP,@commaER      ; _HERE !!!

_COLON  DW @_MAKER,@NEST,_RPAR          ; :
_SEMICO DW @_COMMAER,_RET,_LPAR         ; ;
_clit   dw __@COMMA,_lit                ; (#,

L_ _NUMBER
  DW _CSTR,_NUM
L_ _??
  DW _ABORT?
  NAM_  "?"
  DW _RET

L_ _COMP_NUM
  DW _NUMBER,_cLIT,_comma,_RET
L_ _TOKEN
  DW _BL,_PARSE,_TBUF,_MAKESTR,_DUP,_C@,_RET

L_ _PARSE
__@SOURCE:
  DW _NOP,_ETIB,_LTIB,_PARS,TO_+_LTIB,_RET
  
L_ _ENTRY
  DW _0,_TOKEN?,_DICT,_STRPUSH,_STM,_1P,_STM,TO_+_DICT,_RET

L_    _TOKEN?
  DW _TOKEN,_ZEQ,_??,_RET

__@COMMA:
  CALL  __@does
L_ _@COMMA
      DW _LD
L_ _COMMA
      DW _H,_STP,TO_+_H,_RET

L_ _ABORT?
          DW _@_STR,_SWAP,_IF,@ABORTX   ; IF NO ERROR JUST EXIT
__@ERROR:  ; SHOW ERROR  VECTOR
  FIX_ _ON_ERROR
__@AFTER:  ; INIT AFTER ERROR AND BEFORE ABORT VECTOR
  FIX_ _BREAK
    DW _ABORT

__@INI    DW _NOP      ; INIT VECTOR
    DW  _H,_STR,_DICT,_MPUSH, TO_+_DICT,_LIT,EndMem,_LIT,8000H,_XEVAL
    
    DW  TO_+@INIT
L_ _LPAR                    ; INTERPRETTER
      DW TO_+_FIND    ; EXECUTE OR TRY FOR NUMBER
__@DICTPTR   DW _DICT ; DICTPTR - POINTS DICTIONARY IN WHITCH TO SEARCH 
      DW _FND,_RET       

L_ _RPAR                    ; COMPILER
  DW TO_+_FIND,_DUP,_INC,_DICT,_MFND,_IFM,@RPAR   ; EXECUTE COMPILING WORD
  DW _DROP,_DUP,_DEC,_DICT,_MFND,_1P         ; COMPILE WORD OR  LITERAL
@RPAR DW _1P,_RET

L_ _XEVAL
  DW _EX
L_ _EVAL
      DW _DUP,TO_+_LTIB,_ADD,TO_+_ETIB
@EVAL DW _TOKEN,_IF,@ABORTX,_FIND
  BP_
      DW _OPERAT,_PERFORM
      DW _JUMP,@EVAL
        
;-----------------------------------------------

INCLUDE NF7.ITX ; TEXT
  
freemem:
  DW ENDMEM-FREEMEM-2
  INCLUDE NF7.IGN
  DW 0,0
EndMem:

INCLUDE NF7.ITS   ; TEST

lastw = ppppp

MyCseg  ends
        end  Start

;_STPB DW @_NIP
;  MOV   [TOP],TL
;  JMPS  @1P  
;  
;__ST:
;  POP   [TOP]
;  JMPS  @DROP  
;

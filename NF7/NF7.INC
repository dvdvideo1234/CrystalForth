BP_ MACRO
  IF DBG 
    DW _BREAK
  ENDIF
ENDM

locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_    =  -2
AT_    =  -4
VAL_   =  2

JMPS    MACRO LBL
  jmp  SHORT LBL
ENDM

SKIPA   MACRO
  DB    03DH
ENDM

SKIPB   MACRO
  DB    03CH
ENDM

SKIPR   MACRO reg
  mov   reg,0
  org   $-2
ENDM

SKIPC   MACRO reg
  mov   reg,0
  org   $-1
ENDM

CLR     MACRO  REG
  XOR    REG,REG
ENDM

?Z      MACRO REG
  OR    REG,REG
ENDM
  
X       MACRO
  xchg Rsp,DSP
ENDM

RPUSH   MACRO REG
  X
  PUSH  REG
  X
ENDM

RPOP    MACRO REG
  X
  POP   REG
  X
ENDM

DPUSH   MACRO REG
  PUSH  REG
ENDM

DPOP    MACRO REG
  POP   REG
ENDM

PP = 0
QQ = 0

CMPGEN_   MACRO NUM
  QQ = PP / NUM
  DB QQ+'0'
  PP = PP - (QQ * NUM)
ENDM

TOSTR   MACRO NUM
  PP = NUM-Start+100h
  CMPGEN_ 10000
  CMPGEN_ 1000
  CMPGEN_ 100
  CMPGEN_ 10
  DB PP+'0'
ENDM


qqqqq = 0
ppppp = qqqqq

nam_    macro   msg
  local endstr
  db    endstr-$-1
  db    msg
endstr  label   byte
endm

ln_     macro   token
ppppp = $
  nam_  token
  dw    qqqqq
qqqqq = ppppp
endm

NOPS = 0;

ALIGN1_  MACRO 
  IF ($-@START+1) AND 1
    NOP
    NOPS = NOPS + 1
  ENDIF
ENDM

ALIGN_  MACRO  FLAG
  IF ($-START+FLAG) AND 1
    NOP
    NOPS = NOPS + 1
  ENDIF
ENDM

XALIGN_ MACRO  HLBL
HLBL    =      $
ENDM

  ;__XALIGN LBL
col_    macro  lbl
LBL  DW  @NEST
endm

  ;__XALIGN LBL
VAR_    macro   LBL,DAT
LBL  DW __@VAR,DAT
ENDM

P_     macro   LBL
LBL  DW $+2
ENDM

  ;__XALIGN LBL
XT_     macro   LBL,ADR
LBL  DW ADR
ENDM

  ;__XALIGN LBL
const_  macro   lbl,dat
LBL  DW __@CONS,DAT
endm

  ;__XALIGN LBL
value_  macro   lbl,dat
  DW __@setvar
  const_ LBL,dat
endm

  ;__XALIGN LBL
DEFER_  macro   lbl,dat
LBL  DW     __@defer,dat
endm

  ;__XALIGN LBL
vector_ macro   lbl,dat
  DW __@setvar
  DEFER_ LBL,dat
endm

  ;__XALIGN LBL
point_  macro   lbl,dat
  DW @_setpnt
  XALIGN_ LBL
  DW @_point,dat
endm

entry_  macro ADR,nam
  DW ADR
  DB 0
  nam_ nam
endm

; MINIMAL SET INTERPRETTER COMMANDS
; METHOD       COMMANDS  (DOES (VAR (CONST (CONST2 (DEFER (DEFER2
;                        (SETVAR (SETVAR2 (CONST3 (SETPOINT (POINT
;                        (BARY (WARY (RW_BLK
; CONTROL      COMMANDS  (IF (JUMP (CALL (NEXT (FOR (NEST (EXEC (PERF
;                        (GOTO (RETURN (EX (XNEST (IFZ (IFM
; RETURN STACK COMMANDS  POP PUSH RDROP I J
; DATA STACK   COMMANDS  DUP DROP XCHG
; MATH         COMMANDS  +2/ LIT  ABS NEG NOT _ 1- 2- 1+ 2+
; LOGICAL      COMMANDS  XOR AND
; DATA TRANSF  COMMANDS  @R+ !R+ C!R+
; IO           COMMANDS  (IO

; REGISTERS
IP  = SI  ; INSTRUCTION POINTER
RSP = BP  ; RETURN STACK POINTER
DSP = SP  ; DATA STACK POINTER
TOP = BX  ; DATA STACK TOP REGISTER
TOPL= BL  ; DATA STACK TOP REGISTER
TOPH= BH  ; DATA STACK TOP REGISTER
W   = DI  ; WORK REGISTER
AR  = DX  ; ARITHMETIC / ADRESS REGISTER  ?
T   = AX 
TL  = AL
TH  = AH

; AX, CX, DI  SCRATCH


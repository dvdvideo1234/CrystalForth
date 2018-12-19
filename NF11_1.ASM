locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_     =  -2
AT_     =  -4
VL_     =  2

JMPS    MACRO LBL
          jmp  SHORT LBL
        ENDM

SKIPA   MACRO
        DB    03DH
        ENDM

SKIPB   MACRO
        DB    03CH
        ENDM

SKIPr   MACRO reg
        mov   reg,0
        org   $-2
        ENDM


X       MACRO
  xchg Rsp,DSP
        ENDM

TO_R    MACRO  REG
  PUSH   REG
        ENDM
		

R_TO    MACRO  REG
  POP    REG
        ENDM

TO_D    MACRO  REG
  X
  PUSH   REG
  X
        ENDM

_DUP_	MACRO  
  TO_D	TOP      
		ENDM

D_TO    MACRO  REG
  X
  POP    REG
  X
        ENDM

_DROP_	MACRO  
  D_TO	TOP      
		ENDM

rchg    macro   reg
  xchg  ax,reg
        endm

DUP2    MACRO   R1,R2
  X
  PUSH  R1
  PUSH  R2
  X
        ENDM

DROP2   MACRO   R1,R2
  X
  POP   R1
  POP   R2
  X
        ENDM

qqqqq = 0
ppppp = qqqqq

__nam    macro   msg
  local endstr
  db    endstr-$-1
  db    msg
endstr  label   byte
        endm

__ln     macro   token
ppppp = $
  __nam  token
  dw    qqqqq
qqqqq = ppppp
        endm

__ALIGN  MACRO  FLAG
        IF ($-@_START+FLAG) AND 1
        NOP
        ENDIF
        ENDM

_ALIGN  MACRO
        __ALIGN 0
        ENDM

__entry  macro nam,ADR
        __nam  nam
        DW    ADR,0
        endm


;  ASSIGNMENT OF THE REGISTERS

ip  = BX        ; ip INSTRUCTION POINTER for THE interpretter
dsp = AX		; dsp DATA STACK POINTER
rsp = SP		; rsp RETURN STACK POINTER
ar  = DX        ; address  register
top = BP		; DATA STACK TOP REGISTER
DST = DI		; DESTINATION POINTER
SRC = SI		; SOURCE POINTER
W   = CX		; WORK REGISTER
WL	= CL		; LOWER HALF OF THE WORK REGISTER

;
; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
; RETURN STACK COMMANDS  POP PUSH 
; DATA STACK   COMMANDS  DUP J
; DATA TRANSF  COMMANDS  @R+ !R+ XCHG XR 
; MATH         COMMANDS  +2/ +* -/ NAND
; EXTENSION    COMMANDS  (IO C!R+ C@R+  MEM-

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@TBUF  = -256      		; -256    TBUF = 256   
@TIB   = @TBUF * 2    	; -512    TIB  = 256  + 
@RTOP  = @TIB         	; -512  RSTACK = 768  +
@STOP  = @TBUF+@TIB*2	; -1280 DSTACK = 768  += TOTAL = 2048
@VOCTOP= @TIB * 12    	; -6144 = 4 BUFFERS * 1024 + TOTAL

@_Start   Label byte
  jmpS   _start
;--------------------------------------------------------
; VARIABLES
;--------------------------------------------------------
@_OPER:
  DW	0,0,0,0,0
  
@_AX:    
  DW	0
_AX DW 0
@_BX:    
  DW	0
_BX DW 0
@_CX:    
  DW	0
_CX DW 0
@_DX:    
  DW	0
_DX DW 0
@_FL:    
  DW	0
_FL DW 0

_start:  
  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  _ALIGN
@_ABORT:
  CLD
  MOV   RSP,@RTOP
  MOV   DSP,@STOP
  __ALIGN 1
  CALL  @_RET
@_INIT:    
  DW	0  

  
@INIREG:
  POP	SRC
  X
  POP	DST BX CX DX
  X
  RCHG	DST
  PUSH  DST DS ES
  CALL	SRC
  POP	ES DS DST
  RCHG	DST
  PUSHF
  POP	_FL
  MOV	_DX,DX
  MOV	_CX,CX
  MOV	_BX,BX
  MOV	_AX,DST
  RET
 
; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA C!R+ C@R+,
 _ALIGN
@_MEMCMP:			; MEM-,
; DW	@_COPER
  XOR	W,W
  XCHG	TOP,W
  DROP2	DST,SRC
  REP 	CMPSB
  JE	_CMP
  MOV	W,TOP
  MOV	WL,[SRC-1]
  MOV	TOP,W
  MOV	WL,[DST-1]
  SUB	TOP,W
_CMP:
  JMP	_MAIN  
   
 _ALIGN
@_CRTO:				; C!R+,
;  DW	@_COPER
  RCHG	TOP
  POP	DST
  STOSB
  JMPS	_RTO

 _ALIGN
@_RTO:				; !R+,
;  DW	@_COPER
;@RTO:				
  RCHG	TOP
  POP	DST
  STOSW
_RTO:  
  PUSH  DST
  RCHG	TOP
  JMPS	_DROP

 _ALIGN
@_RAT:				; @R+,
;  DW	@_COPER
;@RAT:				
  _DUP_
  RCHG	TOP
  POP	SRC
  LODSW
  JMPS	_RAT
    
 _ALIGN
@_CRAT:				; C@R+,
;  DW	@_COPER
  _DUP_
  RCHG	TOP
  POP	SRC
  LODSB
  XOR	AH,AH
_RAT:  
  PUSH  SRC
  RCHG	TOP
  JMPS	_MAIN
    
 _ALIGN
@_XCHG:				; XCHG,
;  DW	@_COPER
;@XCHG:				
  R_TO	W
  XCHG	TOP,W
  TO_R	W
  JMPS	_MAIN  
  
 _ALIGN
@_XA:				; XA,
;  DW	@_COPER
;@XA:				
  R_TO	W
  XCHG	AR,W
  TO_R	W
  JMPS	_MAIN  

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
 _ALIGN
@_JUMP:    			; (JUMP,
;  DW	@_COPER
@JUMP:    			
  MOV   IP,[IP]
  JMPS	_MAIN

 _ALIGN
@_IF:				; (IF,
;  DW	@_COPER
;@IF:	 			
  MOV	w,[IP]
  LEA	IP,[IP+2]
  TEST	WL,1
  JNE   _IO 
  OR	TOP,TOP
  JNZ	_DROP    ; TOP = 0
  MOV	IP,W
_DROP:  
  _DROP_
  JMPS	_MAIN
  
 _ALIGN
@_IFM:    			; (IF-.
;  DW	@_COPER
;@IFM:    			
  DEC   TOP
  JNS   @JUMP
  INC	IP
  INC	IP
  JMPS	_MAIN
  
; IO           COMMANDS  (IO  vvvvvvvvvv
 _ALIGN
@_DOS:				; (DOS,
;  DW	@_IOCOPER
;@DOSZ:
  CALL	@INIREG
  INT   21H
  RET
  
 _ALIGN
@_VID:				; (VID,
;  DW	@_IOCOPER
;@VIDZ:
  CALL	@INIREG
  INT	10H  
  RET  
  
 _ALIGN
@_KBD:				; (KBD,
;  DW	@_IOCOPER
;@KBDZ:
  CALL	@INIREG
  INT	16H  
  RET  
  
_IO:  
  DEC   W
  TO_D  TOP
  PUSH  IP src AR 
  CALL  W
  D_TO	TOP 
  CLD
  POP  	AR src
 _ALIGN
;@_RET:				; (RET,
;  DW	@_COPER
@_RET:				
  POP	IP
  jmps  _main  
; IO           COMMANDS  (IO  ^^^^^^^

; MAIN  LOOP
;  SKIPr	W			; !!!
  
@NEST:				; (NEST
  PUSH	ip
  mov	IP,W
  
_MAIN:
  MOV	w,[IP]
  LEA	IP,[IP+2]
  TEST	WL,1
  jE	@nest
  DEC	W
  JMP   W

;  STACK COMMANDS   PUSH DUP J POP
 _ALIGN
@_PUSH:				; PUSH,
;  DW	@_COPER
;@PUSH:
  TO_R	TOP
  JMPS   _DROP  

 _ALIGN
@_DUP:				; DUP,
;  DW	@_COPER
;@DUP:
  to_r	top
 _ALIGN
@_POP:				; POP,
;  DW	@_COPER
;@POP:				
  _DUP_
  R_TO	TOP
  JMP	_MAIN
   
;  _DUP_
;  JMPS	_MAIN 
  
;  STACK   COMMANDS   
 _ALIGN
@_J:				; J,
;  DW	@_COPER
;@J:
  _DUP_
  R_TO	W
  R_TO	TOP
  TO_R	TOP
  TO_R	W
  JMP	_MAIN 
  
; MATH         COMMANDS  +2/ +* -/ NAND
 _ALIGN
@_DIVMOD:			; -/,
;  DW	@_COPER
;@MDIV:
  X
  POP	W
  SHL	W,1
  RCL   TOP,1
  CMP   TOP,AR
  JB	_MDIV
  SUB   TOP,AR
  INC	W
_MDIV: 
  PUSH	W
_MDIV2: 
  X
  JMP	_MAIN
   
 _ALIGN
@_P2DIV:			; +2/,
;  DW	@_COPER
;@P2DIV:
  X
  POP	W
  ADD   W,TOP
  MOV	TOP,W
  RCR   TOP,1
  JMPS	_MDIV
   
 _ALIGN
@_PMUL:				; +*,
;  DW	@_COPER
;@PMUL:
  X
  POP	W
  TEST	WL,1
  JE    _PMUL2
  ADD   TOP,AR
_PMUL2:
  RCR   TOP,1
  RCR   W,1
  JMPS	_MDIV
   
 _ALIGN
@_NAND:				; NAND,
;  DW	@_COPER
;@NAND:
  X
  POP	W
  AND   TOP,W
  NOT	TOP
  JMPS	_MDIV2

@_end:

lastw = ppppp

MyCseg  ends
        end  @_Start



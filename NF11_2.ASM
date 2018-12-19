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

DROP	 MACRO REG
		  LODSW
        ENDM
		
DROPREG MACRO REG
		  DROP
          RCHG REG
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

TO_R    MACRO  REG
  PUSH   REG
        ENDM
		
R_TO    MACRO  REG
  POP    REG
        ENDM

rchg    macro   reg
  xchg  ax,reg
        endm

__ALIGN  MACRO  FLAG
        IF ($-@_START+FLAG) AND 1
        NOP
        ENDIF
        ENDM

_ALIGN  MACRO
        __ALIGN 0
        ENDM

;  ASSIGNMENT OF THE REGISTERS

ip  = DI        ; ip INSTRUCTION POINTER for THE interpretter
top = AX		; DATA STACK TOP  REGISTER
NXT = [SI] ; DATA STACK NEXT REGISTER
dsp = SI		; dsp DATA STACK POINTER
rsp = SP		; rsp RETURN STACK POINTER
ar  = DX        ; address  register
W   = BX		; WORK REGISTER
WL	= BL		; LOWER HALF OF THE WORK REGISTER
TMP = CX
TL  = CL

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
  POP	DI
  PUSH  DS ES TOP
  DROPREG BX
  DROPREG CX
  DROPREG DX
  POP	TOP
  CALL	DI
  POP	ES DS 
  MOV	_DX,DX
  MOV	_CX,CX
  MOV	_BX,BX
  MOV	_AX,AX
  PUSHF
  POP	_FL
  RET
 
; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA C!R+ C@R+,
 _ALIGN
@_MEMCMP:			; MEM-,
  PUSH  IP
  RCHG	CX
  DROPREG DI
  DROP
  PUSH  DSP
  RCHG	SI
  XOR   TOP,TOP
  REP 	CMPSB
  JE	_CMP
  MOV   CH,0
  DEC	SI
  LODSB
  MOV   CL,[DI-1]
  SUB   AX,CX
;  JE	_CMP
;  XOR   W,W
;  MOV	WL,[SI-1]
;  MOV	TOP,W
;  MOV	WL,[DI-1]
;  SUB	TOP,W
_CMP:
  POP   DSP
  
  __ALIGN 0
@_RET:
  POP   IP
  JMP	_MAIN  
   
; IO           COMMANDS  (IO  vvvvvvvvvv
;  _ALIGN
; @_DE:				; (DOS_EMIT
;   PUSH  DX
;   RCHG  DX
;   MOV   AX,0200H
;   INT   21H
;   POP	DX
;   DROP
;   JMP	_MAIN  

 _ALIGN
@_DOS:				; (DOS,
  CALL	@INIREG
  INT   21H
  RET
  
 _ALIGN
@_VID:				; (VID,
  CALL	@INIREG
  INT	10H  
  RET  
  
 _ALIGN
@_KBD:				; (KBD,
  CALL	@INIREG
  INT	16H  
  RET  
  
_IO:  
  DEC   W
  PUSH  IP AR 
  CALL  W
  CLD
  DROP
  POP  	AR 
  jmps  @_RET  
; IO           COMMANDS  (IO  ^^^^^^^

 _ALIGN
@_CRTO:				; C!R+,
  MOV	W,DI
  POP	DI
  STOSB
  JMPS	_RTO

 _ALIGN
@_RTO:				; !R+,
  MOV	W,DI
  POP	DI
  STOSW
_RTO:  
  PUSH  DI
  MOV   DI,W
  JMPS	_DROP

 _ALIGN
@_RAT:				; @R+,
  POP	W
  MOV	TMP,[W]
  INC	W
  JMPS	_RAT
    
 _ALIGN
@_CRAT:				; C@R+,
  POP	W
  XOR	TMP,TMP
  MOV	TL,[W]
_RAT:  
  INC	W
  PUSH  W
_PUSH:
  LEA	DSP,[DSP-2]
  MOV   [DSP],TOP
  MOV   TOP,TMP  
  JMPS	_MAIN
    
 _ALIGN
@_XCHG:				; XCHG,
  R_TO	W
  TO_R	TOP
  MOV	TOP,W
  JMPS	_MAIN  
  
 _ALIGN
@_XA:				; XA,
  R_TO	W
  TO_R	AR
  MOV	AR,W
  JMPS	_MAIN  

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
 _ALIGN
@_JUMP:    			; (JUMP,
@JUMP:    			
  MOV   IP,[IP]
  JMPS	_MAIN

 _ALIGN
@_IF:				; (IF,
  MOV	w,[IP]
  LEA	IP,[IP+2]
  TEST	WL,1
  JNE   _IO 
  OR	TOP,TOP
  JNZ	_DROP    ; TOP = 0
  MOV	IP,W
_DROP:  
  DROP
  JMPS	_MAIN
  
 _ALIGN
@_IFM:    			; (IF-.
  DEC   TOP
  JNS   @JUMP
  INC	IP
  INC	IP
  JMPS	_MAIN
  
; MAIN  LOOP
@NEST:				; (NEST
  PUSH	ip
  mov	IP,W
_MAIN:
  MOV	w,[IP]
  SCASW ; LEA	IP,[IP+2]
  TEST	WL,1
  jE	@NEST
  DEC	W
  JMP   W

;  STACK COMMANDS   PUSH DUP J POP
 _ALIGN
@_PUSH:				; PUSH,
  TO_R	TOP
  JMPS   _DROP  

 _ALIGN
@_DUP:				; DUP,
  MOV	TMP,top
  JMPS	_PUSH
  
 _ALIGN
@_POP:				; POP,
  R_TO	TMP
  JMP	_PUSH
   
;  STACK   COMMANDS   
 _ALIGN
@_J:				; J,
  R_TO	W
  R_TO	TMP
  TO_R	TMP
  TO_R	W
  JMP	_PUSH 
  
; MATH         COMMANDS  +2/ +* -/ NAND
 _ALIGN
@_DIVMOD:			; -/,
  SHL	PW NXT,1
  RCL   TOP,1
  CMP   TOP,AR
  JB	_MDIV
  SUB   TOP,AR
  INC	PW NXT
_MDIV: 
  JMP	_MAIN
   
 _ALIGN
@_P2DIV:			; +2/,
  ADD   TOP,NXT
  MOV	NXT,TOP
  RCR   TOP,1
  JMP	_MAIN
   
 _ALIGN
@_PMUL:				; +*,
  TEST	PB NXT,1
  JE    _PMUL2
  ADD   TOP,AR
_PMUL2:
  RCR   TOP,1
  RCR   PW NXT,1
  JMP	_MAIN
   
 _ALIGN
@_NAND:				; NAND,
  AND   NXT,TOP
  DROP
  NOT	TOP
  JMP	_MAIN

@_end:

MyCseg  ends
        end  @_Start

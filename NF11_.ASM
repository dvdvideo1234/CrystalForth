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

D_TO    MACRO  REG
  X
  POP    REG
  X
        ENDM

w2      macro
  scasw
        endm

cf_to   macro  reg
  sbb   reg,reg
        endm

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
        IF ($-START+FLAG) AND 1
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

; REGISTERS
; SI INSTRUCTION POINTER
; AX DATA STACK POINTER
; SP RETURN STACK POINTER
; CX DATA STACK TOP REGISTER
; DI WORK REGISTER

ip  = si        ; for interpretter
W   = di
dsp = ax
rsp = sp
top = cx
NXT = DX
ar  = bP        ; address  register
RT	= BX		; RETURN TOP

;
; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
; RETURN STACK COMMANDS  POP PUSH 
; DATA STACK   COMMANDS  DUP J
; DATA TRANSF  COMMANDS  @R+ !R+ XCHG XR
; MATH         COMMANDS  +2/ +* -/ NAND
; IO           COMMANDS  (IO

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@_TBUF  = -256      	; -256    TBUF = 256   
@_TIB   = @_TBUF * 2    ; -512    TIB  = 256  + 
@_RTOP  = @_TIB         ; -512  RSTACK = 768  +
@_STOP  = @_TBUF+@_TIB*2; -1280 DSTACK = 768  += TOTAL = 2048
@_VOCTOP= @_TIB * 12    ; -6144 = 4 BUFFERS * 1024 + TOTAL

Start   Label byte
@ABORT:
  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  MOV   RSP,@_RTOP
  MOV   DSP,@_STOP
  __ALIGN 1
  CALL  _RETURN
;--------------------------------------------------------
; CONTROL OPERATIONS
;--------------------------------------------------------
@_vINIT:
  DW	0  
  
@_RESTART:
  DW	@_IF+1,@ABORT+1
@_BYE:  
  DW	@_IF+1,1

;--------------------------------------------------------
; MATH & LOGIC OPERATIONS
;--------------------------------------------------------
@_@AND:
  DW	@_RAT+1
@_AND:
  DW	@_@NAND+1
@_NOT:
  DW	@_DUP+1
@_NAND:
  DW	@_@NAND+1,@_RET+1	
@_R@AND:
  DW	@_RAT+1,@_AND,@_JUMP+1,@_EXIT
@_PLUS:
  DW	@_P2DIV+1,  
;--------------------------------------------------------
; MEMORY OPERATIONS
;--------------------------------------------------------
@_TO_2P:
  DW	@_PUSH+1,@_RTO+1,@_POP+1,@_RET+1
@_@_2P:
  DW	@_PUSH+1,@_RAT+1,@_POP+1,@_RET+1
@_2LIT:
  DW	@_RAT+1
@_LIT:
  DW	@_RAT+1,@_RET+1
@_2M@:
  DW	@_2MDXEP
@_@:				; @
  DW	@_PUSH+1
@_CON:
  DW	@_RAT+1
@_EXIT:
  DW	@_POP+1
@_DROP:
  DW	@_IF+1,@_NOP
@_NOP:
  DW	@_RET+1 
@_2MTO:
  DW	@_2MDXEP
@_TO:				; !
  DW	@_PUSH+1
@_TOV:
  DW	@_RTO+1,@_JUMP+1,@_EXIT
@_SET:
  DW	@_RAT+1,@_IF+1,_SET
_SET DW @_RTO+1,@_EXIT 

;--------------------------------------------------------
; STACK OPERATIONS
;--------------------------------------------------------
@_DRDR:
  DW	@_DROP
@_RDROP:
  DW	@_POP+1,@_XCHG+1,@_JUMP+1,@_DROP
@_2SWAP:
  DW	@_ROT,@_XEP  
@_ROT:
  DW	@_USWAP,@_JUMP+1,@_SWAP 
@_MROT:
  DW	@_SWAP  
@_USWAP:
  DW	@_XEP  
@_SWAP:
  DW	@_PUSH+1
@_XPOP:  
  DW	@_XCHG+1,@_POP+1,@_RET+1  
@_2DUP:  
  DW	@_OVER
@_OVER:
  DW	@_PUSH+1,@_DUP+1,@_JUMP+1,@_XPOP
@_2PICK:
  DW	@_PUSH+1,@_OVER,@_JUMP+1,@_XPOP
  
  DW	@_RAT+1
  DW 	@_SET
@_AX:    
  DW	@_CON
_AX DW 0
  DW	@_RAT+1
  DW 	@_SET
@_BX:    
  DW	@_CON
_BX DW 0
  DW	@_RAT+1
  DW 	@_SET
@_CX:    
  DW	@_CON
_CX DW 0
  DW	@_RAT+1
  DW 	@_SET
@_DX:    
  DW	@_CON
_DX DW 0
  DW	@_RAT+1
  DW 	@_SET
@_FL:    
  DW	@_CON
_FL DW 0

@_EX:
  DW	@_POP+1
@_XPUSH:
  DW	@_XCHG+1  
@_EXECUTE:
  DW	@_PUSH+1,@_RET+1
@_2MDXEP:  
  DW    @_IFM+1,@_1MDXEP
@_1MDXEP:  
  DW    @_IFM+1,@_DXEP
@_DXEP:  
  DW	@_DUP+1
@_XEP:  
  DW	@_XCHG+1,@_EXECUTE,@_POP+1,@_RET+1
  
@_SEMIT:
  DW	@_T
  DW	@_EX
  DW 	@_SET
@_T:    
  DW	@_CON
  DW	0

@_SEMIH:
  DW	@_H
  DW	@_EX
  DW 	@_SET
@_H:    
  DW	@_CON
  DW	@_START

@_SEMI_EMIT:
  DW	@_RAT+1,@_EMIT-2,@_XCHG+1,@_PUSH+1,@_EMIT-4,_EX  
  DW 	@_POP+1,@_SET,@_CON
@_EMIT:
  DW	@_DROP,@_RET+1
@_DEMIT:
  DW	@_DUP+1,@_DUP+1,@_DUP+1,@_LIT,200H
@_DOS:  
  DW    @_IF+1,@_DOSZ+1,@_RET+1  
@_VID:  
  DW    @_IF+1,@_VIDZ+1,@_RET+1  
@_KBD:  
  DW    @_IF+1,@_KBDZ+1,@_RET+1  
  
@INIREG:
  POP	IP
  X
  POP	W BX CX DX
  X
  RCHG	W
  PUSH  W DS ES
  CALL	IP
  POP	ES DS W
  RCHG	W
  PUSHF
  POP	_FL
  MOV	_DX,DX
  MOV	_CX,CX
  MOV	_BX,BX
  MOV	_AX,DI
  RET
 
 _ALIGN
@_DOSZ:
  CALL	@INIREG
  INT   21H
  RET
  
 _ALIGN
@_VIDZ:
  CALL	@INIREG
  INT	10H  
  RET  
  
 _ALIGN
@_KBDZ:
  CALL	@INIREG
  INT	16H  
  RET  
  
; IO           COMMANDS  (IO  vvvvvvvvvv
_IO:  
  DEC   W
  X
  PUSH   NXT TOP
  X
  PUSH  IP RT AR 
  CALL  W
  X
  POP	TOP NXT
  X
  CLD
  POP  	AR RT IP
  RET 
; IO           COMMANDS  (IO  ^^^^^^^

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
 _ALIGN
@_IF:	 			; (IF
  CALL	_LIT
  JNE   _IO 
  OR	TOP,TOP
  CALL	_DROP
  JNZ	_IF    ; TOP = 0
  MOV	IP,W
_IF:
  RET
  
_LIT:
  MOV	w,[IP]
_SKIP:
  LEA	IP,[IP+2]
  TEST	W,1
  RET

 _ALIGN
@_IFM:    			; (IF-
  DEC   TOP
  JS    _SKIP

 _ALIGN
@_JUMP:    			; (JUMP
  MOV   IP,[IP]
  RET

 _ALIGN
@_RET:				; (RET
  POP	W
  MOV	IP,RT
  POP	RT
  JMPS  _MAIN

; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA
 _ALIGN
@_RAT:				; @R+
  CALL  @_DUP
  MOV   TOP,[RT]
  LEA	RT,[RT+2]
  RET
    
 _ALIGN
@_RTO:				; !R+
  MOV   [RT],TOP
  LEA	RT,[RT+2]
_DROP:
  MOV	TOP,NXT
_NIP:  
  D_TO  NXT
  RET
  

 _ALIGN
@_XCHG:				; XCHG
  XCHG	TOP,RT
  RET  
  
 _ALIGN
@_XA:				; XA
  XCHG	AR,RT
  RET  

; MAIN  LOOP
@NEST:				; (NEST
  PUSH	RT
  MOV	RT,IP
  MOV	IP,W
  
_MAIN:
  CALL	_LIT
  jE	@nest
  DEC	W
  CALL  W
  JMP   _MAIN

;  STACK COMMANDS   PUSH DUP
 _ALIGN
@_DUP:
  X
  PUSH	NXT
  X
  MOV	NXT,TOP
  RET
_RETURN:  
  POP	IP
  JMP   _MAIN
  
;  STACK   COMMANDS   J POP
 _ALIGN
@_J:
  CALL  @_DUP
  POP	W
  POP	TOP
  PUSH	TOP
  JMP	W
  
 _ALIGN
@_PUSH:
  POP	W
  PUSH	RT
  PUSH  W
  MOV	RT,TOP
  JMP   _DROP  

 _ALIGN
@_POP:				; POP
  CALL  @_DUP
  POP	W
  MOV	TOP,RT
  POP	RT
  JMP	W
   
; MATH         COMMANDS  +2/ +* -/ NAND
 _ALIGN
@_MDIV:
  SHL	NXT,1
  RCL   TOP,1
  CMP   TOP,AR
  JB	_MDIV
  SUB   TOP,AR
  INC	NXT
_MDIV: 
  RET 
   
 _ALIGN
@_P2DIV:
  ADD   NXT,TOP
  MOV	TOP,NXT
  RCR   TOP,1
  RET
   
 _ALIGN
@_PMUL:
  TEST	NXT,1
  JE    _PMUL2
  ADD   TOP,AR
_PMUL2:
  RCR   TOP,1
  RCR   NXT,1
  RET
   
 _ALIGN
@_NAND:
  AND   TOP,NXT
  NOT	TOP
  JMPS  _NIP
   
@_START:

lastw = ppppp

MyCseg  ends
        end  Start



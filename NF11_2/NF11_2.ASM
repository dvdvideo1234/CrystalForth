locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_     =  -2
AT_     =  -4
VL_     =  2

JMPS   MACRO LBL
  jmp SHORT LBL
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

CLR   MACRO reg
  XOR   reg,REG
ENDM

X MACRO
  XCHG RSP,DSP
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

_ALIGN1  MACRO 
  IF ($-@_START+1) AND 1
  NOP
  ENDIF
ENDM

_ALIGN  MACRO
  IF ($-@_START) AND 1
  NOP
  ENDIF
ENDM

;LBL = ($-@_START+0100H) / 2
P_ MACRO LBL
  _ALIGN 
  NOP
LBL:
  ORG $-1
  ENDM
        
;LBL = (($-@_START+0100H) / 2) + 08000H
L_  MACRO LBL
  _ALIGN 
LBL:
  ENDM

;  ASSIGNMENT OF THE REGISTERS

ip  = SI    ; ip INSTRUCTION POINTER for THE interpretter
top = BX		; DATA STACK TOP  REGISTER
TOPL= BL		; DATA STACK TOP  REGISTER
NXT = DX		; DATA STACK NXT  REGISTER
NXTL= DL		; DATA STACK NXT  REGISTER
dsp = AX		; dsp DATA STACK POINTER
rsp = SP		; rsp RETURN STACK POINTER
ar  = BP    ; ARITHMETIC  register
W   = DI		; WORK REGISTER
TMP = CX
TMPL= CL

; CX DI SCRATCH

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
  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  MOV   AX,3
  INT   010H

P_ _ABORT
  MOV   RSP,@RTOP
  MOV   DSP,@STOP
  CLD
  CALL  @RET
_@INIT:    
  DW	0  

;--------------------------------------------------------
; VARIABLES
;--------------------------------------------------------
@_OPER:
  DW	0,0,0,0,0
  
L_ _AX    
  DW	_CONST
@AX DW 0
L_ _BX    
  DW	_CONST
@BX DW 0
L_ _CX    
  DW	_CONST
@CX DW 0
L_ _DX
  DW	_CONST
@DX DW 0
L_ _FL
  DW	_CONST
@FL DW 0
  
L_ _DOS				; (DOS,
  DW    _IO
  MOV   NXTL,21H
@INIREG:
  MOV   PB @INTA,NXTL
  PUSH  DS ES 
  X
  POP   AR BX CX DX
  X
  XCHG  AR,AX
  PUSH  AR
  INT 	21H
@INTA = $-1  
  POP	  AR ES DS 
  MOV	  @DX,DX
  MOV	  @CX,CX
  MOV	  @BX,BX
  MOV	  @AX,AX
  PUSHF 
  POP	  @FL
  XCHG  AR,AX
  RET
   
L_ _VID				; (VID,
  DW    _IO
  MOV   NXTL,10H
  JMPS	@INIREG
  
L_ _KBD				; (KBD,
  DW    _IO
  MOV   NXTL,16H
  JMPS	@INIREG
  
P_ _IO
  X
  PUSH  DX BX
  X
  PUSH AR
  CALL IP
  POP AR

P_ _2DROPX
  X
  POP  BX DX
  X
  
P_ _RET  
@RET:
  POP   IP
  JMP 	@MAIN

P_ _CONST
  MOV   TMP,[IP]  
  POP   IP
  JMP   @DPUSH
  
P_ _VAR
  MOV   TMP,IP  
  POP   IP
  JMP   @DPUSH
  
P_ _DEFER
  PUSH  [IP]  
  JMP   @RET
  
P_ _SETVAR
  MOV   [IP+2],TOP
  POP   IP
  JMP   @DROP
  
P_ _ADDI
  ADD   TOP,[IP]
  JMP   @RET
  
P_ _ANDI
  AND   TOP,[IP]
  JMP   @RET
  
; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA C!R+ C@R+,

L_ _MEMCMP			; MEM-,
  DW    _IO
  X
  POP   CX DI SI
  CLR   TOP
  JCXZ  @CMP
  REP 	CMPSB
  JE	  @CMP
  CLR   CH
  MOV   TOPL,[SI-1]
  MOV   CL,[DI-1]
  SUB   TOP,CX
@CMP:
  PUSH  TOP
  X
  RET  
   
; IO           COMMANDS  (IO  vvvvvvvvvv
L_ _DE				; (DOS_EMIT
  DW  _IO
  X
   POP	 DX
   MOV   BX,0200H
   XCHG  BX,AX
   INT   21H
   XCHG  BX,AX
  X
  RET

; IO           COMMANDS  (IO  ^^^^^^^

P_ _NAND				; NAND,
  AND   NXT,TOP
  NOT	  TOP
  JMPS	@NIP

P_ _CRSTP				; C!R+,
  POP	  W
  MOV	  [W],TOPL
  JMPS	@RTO

P_ _RSTP				; !R+,
  POP	  W
  MOV	  [W],TOP
  INC   W
@RTO:  
  INC   W
  PUSH  DI
P_ _DROP
@DROP:
  MOV  TOP,NXT
P_ _NIP				
@NIP:
  D_TO  NXT
  JMPS	@MAIN

P_ _RLDP				; @R+,
  ;TO_D  TOP
  POP	  W
  MOV	  TMP,[W]
  INC	  W
@RAT:  
  INC	W
  PUSH  W
  JMPS	@DPUSH
    
P_ _CRLDP			; C@R+,
  ;TO_D  TOP
  POP	  W
  CLR	  TMP
  MOV	  TMPL,[W]
  JMPS	@RAT

P_ _PUSH
  PUSH  TOP
  JMPS	@DROP
    
P_ _XCHG				; XCHG,
  POP   W
  PUSH	AR
  MOV	  TOP,W
  JMPS	@MAIN
  
P_ _XA				; XA,
  POP   W
  PUSH	AR
  MOV	  AR,W
  JMPS	@MAIN

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-
P_ _JUMP    			; (JUMP,
@JUMP:    			
  MOV   IP,[IP]
  JMPS	@MAIN

P_ _IF				; (IF,
  OR    TOP,TOP
  MOV  TOP,NXT
  D_TO  NXT
  JZ	  @JUMP    ; TOP = 0
P_ _SKIP
@SKIP:
  CMPSW
  JMPS	@MAIN
  
P_ _IFM    			; (IF-.
  DEC   TOP
  JNS   @JUMP
  JMPS	@SKIP
  
; MAIN  LOOP

P_ _EX
  POP   W
@NEST:				; (NEST
  PUSH  IP
  MOV   IP,W
@MAIN:
  MOV   W,[IP]
  ADD   IP,2
  .386
  BTR	W,1
  .186
  jC	  @NEST
  JMP   W

;  STACK COMMANDS   PUSH DUP J POP

P_ _DUP				; DUP,
  PUSH	TOP
  
P_ _POP				; POP,
  POP	  TMP
@DPUSH:
  TO_D	NXT
  MOV   NXT,TOP
  MOV   TOP,TMP
  JMPS	@MAIN
   
;  STACK   COMMANDS   

P_ _J				; J,
  ;TO_D	TOP
  POP   W
  POP	  TMP
  PUSH	TMP
  PUSH	W
  JMPS	@DPUSH
  
; MATH         COMMANDS  +2/ +* -/ NAND

P_ _DIVMOD			; -/,
  SHL	  NXT,1
  RCL   TOP,1
  CMP   TOP,AR
  JB	  @MDIV
  SUB   TOP,AR
  INC	  NXT
@MDIV: 
  JMPS	@MAIN
   
P_ _P2DIV			; +2/,
  ADD   TOP,NXT
  MOV	  NXT,TOP
  RCR   TOP,1
  JMPS	@MAIN
   
P_ _PMUL				; +*,
  TEST	NXTL,1
  JE    @PMUL2
  ADD   TOP,AR
@PMUL2:
  RCR   TOP,1
  RCR   NXT,1
  JMPS	@MAIN
   
@_end:

MyCseg  ends
        end  @_Start

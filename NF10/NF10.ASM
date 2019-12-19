; shrinkED CODE ADDRESS INTERPRETTER

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

rchg    macro   reg
  xchg  ax,reg
        endm

CLR    macro   reg
  XOR  reg,reg
        endm

ALIGN_  MACRO
        IF ($-START) AND 1
        NOP
        ENDIF
        ENDM

P_  MACRO NAM
  ALIGN_
  NOP
NAM:
  ORG $-1
  ENDM

L_  MACRO NAM
  ALIGN_
NAM:
  ENDM

; REGISTER usage
ip  = si  ; SI INSTRUCTION POINTER
dsp = ax  ; AX DATA STACK POINTER
rsp = sp  ; SP RETURN STACK POINTER
top = cx  ; CX DATA STACK TOP REGISTER
topL= cL  ; CX DATA STACK TOP REGISTER
w   = di  ; DI WORK REGISTER

ar  = Dx  ; DX ARITHMETIC ( ADDRESS ) register 
		 ; BP  BX  - NOT USED

; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (; (IF- 
  ;(IO (-IF (NEXT 0; ?SKIP ?EXEC PUSH;
; RETURN STACK COMMANDS  POP PUSH 				; RDROP
; DATA STACK   COMMANDS  DUP J					; A! A@ DROP DROP;
; DATA TRANSF  COMMANDS  @R+ !R+ XA XR			; C@R+ C!R+ 
; MATH         COMMANDS  +2/ +* -/ NAND

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@TBUF   = -258          ; -256    TBUF = 256   
@TIB    = @TBUF -256    ; -512    TIB  = 256  + 
@R_TOP  = @TIB-64       ; -512  RSTACK = 768  +
@S_TOP  = @TBUF+@TIB*2  ; -1280 DSTACK = 768  += TOTAL = 2048
@VOCTOP = @TIB * 12     ; -6144 = 4 BUFFERS * 1024 + TOTAL

Start   Label byte

P_ _ABORT
  MOV   RSP,@R_TOP
  MOV   DSP,@S_TOP
  CALL  @DEBUG
  CALL  @RETURN
  
L_ _INITA
    DW 7 DUP(0)
	
L_ _TASKPTR
  DW  0,0,0
      
; IO           COMMANDS  (IO  vvvvvvvvvv

P_ _IO				; NOT IF => IO OPERATION
  PUSH  AR BX BP DS ; PRESERVE REGISTERS
  MOV   BP,SP		; MAKE FRAME (PRESERVE SP)
  X					; SWITCH TO DATA STACK
  RCHG  TOP			; LOAD AX
  POP   BX CX DX	; LOAD REGISTERS
  CALL  IP   		; CALL ADDRESS IN W 
  PUSH  ds es BP DI SI CX BX CS
  POP	ES
  PUSHF				; FETCH FLAGS
  PUSH	DX AX
  CLD				; CLEAR DIRECTION FOR EVERYTHING CASE
  MOV   DI,WORD PTR CS:_TASKPTR[4]
  MOV   CX,10
@@1: POP	AX
  STOSW	
  LOOP  @@1
  X	  ; SWITCH TO RETURN STACK
  MOV	SP,BP
  POP  	DS BP BX AR	; RESTORE REGISTERS
  
L_ _DOS
  DW _IO
  INT 21H
  RET  
  
L_ _VID
  DW _IO
  INT 10H
  RET  
  
L_ _KBD
  DW _IO
  INT 16H
  RET    
  
; IO           COMMANDS  (IO  ^^^^^^^

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-

@DROPX:  
  D_TO	TOP
P_ _RET
@RETURN:
  r_to  IP			; POP IP FROM RETURN TOP ELEMENT
  JMP   @MAIN		; LOAD IP FROM RETURN STACK
P_ _DROPX
  JMPS @DROPX 
  
 P_ _TARY	    
        SHL     TOP,1
 P_ _5ARY	     
        ADD     IP,TOP
 P_ _LARY	     
        SHL     TOP,1
 P_ _WARY	     
        SHL     TOP,1
 P_ _BARY	 
        ADD     TOP,IP
        JMPS    @RETURN
 
 P_ _4PX	
        INC     TOP
        INC     TOP
 P_ _2PX
@2PX:
        INC     TOP
        INC     TOP
        JMPS    @RETURN
		
 P_ _1PX	
        JMPS    @2PX+1
		
 P_ _PUSHX
		PUSH	TOP
		JMPS 	@DROPX 		

P_ _AST	
    MOV AR,TOP	
    JMPS  @DROP	
	
P_ _?EXIT			; (0;) EXEC NEXT WORD ON 0= ELSE SKIP
  JCXZ  @DROPX
  JMPS  @DROP
  
P_ _EXEC
	MOV		W,TOP
	D_TO	TOP
    JMP @MAIN3  
    
P_ _?EXEC			; EXEC NEXT WORD ON 0= ELSE SKIP
  JCXZ  @DROP
  JMPS  @SKIP
  
P_ _?SKIP			; EXEC NEXT WORD ON 0<> ELSE .SKIP
  JCXZ  @SKIPDR
  JMPS  @MAIN

P_ _PUSH			; PUSH
  TO_R	TOP
@DROP:
  D_TO 	TOP
  JMPS  @MAIN
  
P_ _DROP
 JMPS @DROP				; DUPLICATE TOP

P_ _IF	   ; (IF
  JCXZ  @JUMPDR
@SKIPDR:
  INC	IP
  INC	IP
  JMPS  @DROP
  
P_ _FOR	 
  PUSH	TOP
@JUMPDR:  
  MOV   IP,[IP]		; JUST BRANCH
  JMPS  @DROP
  
P_ _NEXT	
  POP	W
  DEC	W
  PUSH	W
  SKIPR W
  
P_ _MIF	  			; (-IF
@MIF:  
  INC   TOP			; INCREMENT TOP 
@IFM:
  DEC   TOP			; DECREMENT TOP 
  JS    @SKIP		; ON NEGATIVE - SKIP BRANCH
  
P_ _JUMP	   			; (JUMP
@JUMP:
  MOV   IP,[IP]		; JUST BRANCH
  JMPS  @MAIN
  
P_ _SKIP	
@SKIP:
  INC   ip
  INC   ip
  JMPS  @MAIN

P_ _IFM
 JMPS @IFM  			; (IF-

; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA

@GETLEN:
		TO_D	TOP
        CLR     TOP
        MOV     TOPL,[W]
@DEBUG:  
		RET

 P_ _SLSKIP		            ; ("SKIP
        POP     W
		CALL	@GETLEN
        OR      TOPL,1        ; MAKE CNT ODD
        ADD     TOP,W
        XCHG    TOP,W
        JMPS    @RINC1

P_ _RSTBP			; C!R+
  POP 	W   		; USE RETURN TOP AS DATA ADDRESS
  MOV   [W],TOPL		; STORE DATA TOP
  JMPS  @WINCW			; FETCH NEXT DATA TO TOP

P_ _RSTP			; !R+
  R_TO 	W			; USE RETURN TOP AS DATA ADDRESS
  MOV   [W],TOP		; STORE DATA TOP
  inc   W			; INCREMENT ADDRESS
@WINCW:  
  inc   W			; INCREMENT ADDRESS
  PUSH	W
  JMPS  @DROP		; FETCH NEXT DATA TO TOP

P_ _RLDBP			; C@R+
  R_TO 	W			; USE RETURN TOP AS DATA ADDRESS
	CALL	@GETLEN
  JMPS  @RINC1

P_ _RLDP			; @R+
  R_TO 	W			; USE RETURN TOP AS DATA ADDRESS
  TO_D	TOP
  MOV   TOP,[W]		; USE RETURN TOP AS DATA ADDRESS
@RINC2:  
  inc   W			; INCREMENT ADDRESS
@RINC1:  
  inc   W			; INCREMENT ADDRESS
  JMPS  @RPUSH			; INCREMENT ADDRESS

P_ _J				; J - DATA FROM SECOND ELEMENT OF RETURN STACK
  TO_D	TOP
  R_TO  W			; POP W FROM RETURN
  R_TO	TOP
  TO_R	TOP
  JMPS  @RPUSH			; INCREMENT ADDRESS
  
P_ _XR				; XCHG
@XCHG:
  R_TO	W			; EXCHANGE TOP ELEMENTS
  XCHG  TOP,W		; => DATA STACK AND RETURN STACK
  JMPS  @RPUSH 
  
P_ _XA				; XA
  R_TO	W			; EXCHANGE RETURN TOP ELEMENT
  XCHG	ar,W		; WITH ADDED REGISTER
  JMPS  @RPUSH 
  

; MAIN  LOOP -----------------------------

P_ _EX	
  R_TO  W
@NEST: 
  XCHG  IP,W		; PUSH NEW IP
@RPUSH:  
  to_r  W			; PUSH W 
  
P_ _NOP  
@MAIN:
  MOV   w,[IP]	
@MAIN2:  
  LEA 	IP,[IP+2]
@MAIN3:  
  TEST	W,1
  JZ	@NEST
  DEC 	W
  JMP   W		; BRANCH TO PRIMITIVE

;  STACK COMMANDS   PUSH DUP  ----------------------------

P_ _POP
 JMPS @POP		; POP 
  
P_ _OVER
	X
	R_TO	W
	TO_R	W
	X
	TO_R	W
	SKIPB
	
P_ _RSPLD
	TO_R	RSP
	SKIPB
	
P_ _DSPLD
	TO_R	DSP
	SKIPB
	
P_ _ALD
	TO_R	AR
	SKIPB
	
P_ _DUP					; DUPLICATE TOP
	TO_R	TOP
@POP:
	TO_D	TOP
	R_TO	TOP
    JMPS  @MAIN
   
P_ _RDROP
	POP		W
    JMPS  @MAIN	
@NOT_CTO:	
	CMC
@C_TO_R:	
    SBB     TOP,TOP
    JMPS	@MAIN	
	
P_ _ZEQ		  	    ;  - LOGICAL INVERT
	NEG   	TOP
    JMPS	@NOT_CTO	
	
 P_ _0LESS
    SHL		TOP,1
    JMPS	@C_TO_R	

P_ _DIG_C	
	RCHG	TOP
	CMP	  AL,10
	JB	  @@2
	ADD   AL,7
@@2:ADD   AL,'0'	
	RCHG	TOP
    JMPS  @MAIN	
	
; MATH, LOGIC AND SHIFT COMMANDS   +2/ +* -/ NAND

P_ _NAND		; NAND - LOGICAL PRIMITIVE
	D_TO W
	AND   TOP,W	; AND 
@NOT:
	INC	TOP			  ; NOT  2  1 & 2 => NAND
P_ _NEG,@NEG  
@NEG:  
	NEG	TOP			  ; NOT  2  1 & 2 => NAND
	JMPS  @MAIN
P_ _NOT
 JMPS @NOT  	
 
P_ _MDIV			; -/ DIVIDE PRIMITIVE
  X					; SWITCH DSP WITH RSP
  R_TO 	W			; BELOW TOP REGISTER OF DATA STACK
  SHL	W,1			; SHIFT LEFT NEXT TO CARRY
  RCL   TOP,1		; ROTATE LEFT WITH CARRY
  CMP   TOP,ar		; COMPARE TOP WITH AR
  JB	  @MDIV		; IF NOT BELOW THEN SUBTRACT 
  SUB   TOP,ar		; SUBTRACT SAR FROM TOP
  INC	W			; SUCSESSFULL SUBTRACT
@MDIV:  
  TO_R	W			; NEXT BACK TO DATA STACK
@MDIV2:  
  X					; SWITCH DSP WITH RSP
  JMPS  @MAIN
   
P_ _PMUL					; +* MULTIPLY PRIMITIVE
  X
  R_TO 	W			  ; FETCH SECOND DATA ELEMENT - NEXT
  TEST	W,1			; TEST LEAST SIGNIFICANT BIT
  JE    @2MUL		; IF CLEAR - NOT ADD
  ADD   TOP,ar		; ADDING SAR TO TOP
@2MUL:
  RCR   TOP,1		; JUST SHIFT RIGHT TOP WITH CARRY
  RCR   W,1			; SHIFT RIGHT NEXT WITH CARRY
  JMPS  @MDIV
   
P_ _P2DIV			; +2/ SUM AND SHIFT PRIMITIVE
  X					; SWITCH DSP WITH RSP
  R_TO 	W			; BELOW TOP REGISTER OF DATA STACK
  ADD   W,TOP		; NEXT := NEXT + TOP;
  MOV	  TOP,W		; PREPARE FOR SHIFT
  RCR   TOP,1		; SHIFT RIGHT TOP WITH CARRY
  JMPS  @MDIV
       
P_ _XOR			  	; XOR - LOGICAL PRIMITIVE
	X				; SWITCH DSP WITH RSP
	R_TO 	W		; BELOW TOP REGISTER OF DATA STACK
	XOR   	TOP,W		
	JMPS  	@MDIV2
  
P_ _SUB			  	; SUB - ARITH PRIMITIVE
	NEG		TOP
P_ _ADD			  	; ADD - ARITH PRIMITIVE
	X				; SWITCH DSP WITH RSP
	R_TO 	W		; BELOW TOP REGISTER OF DATA STACK
	XOR   	TOP,W		
	JMPS  	@MDIV2
  
L_ EndMem

MyCseg  ends
        end  Start

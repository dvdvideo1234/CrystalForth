
A386 = 0

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

Zero?_  MACRO   REG
  OR    REG,REG
ENDM

JMPS    MACRO LBL
  jmp   SHORT LBL
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

X       MACRO
  xchg  Rsp,DSP
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

DROP_   macro   
  LODSW
endm

SWAP_   macro   
  XCHG  TOP,NXT
endm

PUSHR_  MACRO REG
  DEC   DSP
  DEC   DSP
  MOV   NXT,REG
ENDM  

POPR_   macro   reg
  xchg  ax,reg
  DROP_
endm

CLR     macro   reg
  XOR   reg,reg
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
  org   $-1
ENDM

L_      MACRO NAM
  ALIGN_  0
NAM:
ENDM

; REGISTER usage
ip  = BX  ; BX INSTRUCTION POINTER
dsp = SI  ; SI DATA STACK POINTER
rsp = sp  ; SP RETURN STACK POINTER
top = Ax  ; AX DATA STACK TOP REGISTER
NXT   EQU PW [DSP]
topL= AL  ; AX DATA STACK TOP REGISTER
topH= AH  ; AX DATA STACK TOP REGISTER
w   = di  ; DI WORK REGISTER
ar  = Dx  ; BX ARITHMETIC ( ADDRESS ) register 
DR  = CX  ; DX DATA REGISTER
DRL = CL  ; DX DATA REGISTER
DRH = CH  ; DX DATA REGISTER


nacc  = DI
nbase = BP

; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-  ;(IO
; RETURN STACK COMMANDS  POP PUSH 
; DATA STACK   COMMANDS  DUP J
; DATA TRANSF  COMMANDS  @R+ !R+ XCHG XR
; MATH         COMMANDS  +2/ +* -/ NAND

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@TBUF   = -256          ; -256    TBUF = 256
@TIB    = @TBUF * 2     ; -512    TIB  = 256  +
@R_TOP  = @TIB          ; -512  RSTACK = 768  +
@S_TOP  = @TBUF+@TIB*2  ; -1280 DSTACK = 768  += TOTAL = 2048
@VOCTOP = @TIB * 12     ; -6144 = 4 BUFFERS * 1024 + TOTAL

Start  Label byte   
L_ _STARTMEM
  mov   ah,4ah     
  mov   bx,1000h        ; only 64k allocate
  int   21h
P_ _ABORT
  CLD
  MOV   RSP,@R_TOP
  MOV   DSP,@S_TOP
  CALL  @RETURN
  
_INIT   DW 0,0,0

; IO           COMMANDS  (IO  vvvvvvvvvv

;L_ _W_B
;  DW _IO
;  JMPS  @W_B

L_ _BK
  DW _DUP,_IO
  CLR   AX
  INT   16H
  ZERO?_ TOPL
  JE  @@1
@W_B:  
  CLR   TOPH
@@1: RET

P_ _IO  				  ; IF INPUT PARAMS = OUTPUT PARAMS 
  PUSH  AR  ; PRESERVE REGISTERS
  MOV   W,IP
  MOV   BX,[DSP]
  MOV   CX,[DSP+2]
  MOV   DX,[DSP+4]
  ;push  es ds 
  CALL  W	 ; ,"^\~|~?~^V^A+~^R~+~X+~^S~+~^Q~+~C~"
  ;pop   ds es
  POP  	AR	; RESTORE REGISTERS
P_ _RET			; (RET
  JMPS  @RETURN

L_ _BE
  DW _IO
  MOV     AH,0EH
  INT     10H
  DROP_
  RET
        
  ; PUSHF			; FETCH FLAGS
  ; CLD				; CLEAR DIRECTION FOR EVERYTHING CASE
  ; MOV   DI,OFFSET @AX
  ; STOSW
  ; RCHG  DX
  ; STOSW
  ; POP   AX		; STORE FLAGS TO _F
  ; STOSW
  ; RCHG  BX		; STORE BX TO _B
  ; STOSW
  ; RCHG  CX		; STORE CX TO _C
  ; STOSW
  ; RET
  
; IO           COMMANDS  (IO  ^^^^^^^

; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-


P_ _?SKIP			; ?SKIP
  Zero?_    TOP  
  JNZ   @MAIN
P_ _IFM1  
  JMPS  @IFM1

P_ _IF	 			; (IF
  DEC   TOP
@IFM1:  
  INC   TOP
  DROP_
  JE    @JUMP 
  
P_ _SKIP
@SKIP:
  INC   ip
  INC   ip
  JMPS  @MAIN

P_ _IFM    			; (IF-
  JMPS  @IFM
  
P_ _MIF    			; (-IF
  INC   TOP
@IFM:
  DEC   TOP			; DECREMENT TOP AND BRANCH ON POSITIVE
  JS    @SKIP		; ON NEGATIVE - SKIP BRANCH
  JMPS  @JUMP 
  
P_ _NEXT
  R_TO  DR
  INC   DR
  JZ    @SKIP
  TO_R  DR

P_ _JUMP    			; (JUMP
@JUMP:
  MOV   IP,[IP]		; JUST BRANCH
  JMPS  @MAIN


; DATA TRANSFER  COMMANDS  @R+ !R+ XCHG XA

P_ _RSTM			; !R-
  R_TO 	W			; TAKE TOP OF THE RETURN STACK
  DEc   W			; DECREMENT ADDRESS
  DEc   W			; DECREMENT ADDRESS
  SKIPB
  
P_ _RST			  ; !R
  R_TO 	W			; TAKE TOP OF THE RETURN STACK
  MOV   [W],TOP		; USE RETURN TOP AS DATA ADDRESS
  JMPS  @WSAVE		; FETCH NEXT DATA TO TOP

P_ _RLDM			; @R-
  R_TO 	W			; TAKE TOP OF THE RETURN STACK
  DEc   W			; DECREMENT ADDRESS
  DEc   W			; DECREMENT ADDRESS
  SKIPB
  
P_ _RLD			  ; @R
  R_TO 	W			; TAKE TOP OF THE RETURN STACK
  MOV   DR,[W]		; USE RETURN TOP AS DATA ADDRESS
  JMPS  @DUPW ; 

P_ _RLDP			; @R+
  R_TO 	W			; TAKE TOP OF THE RETURN STACK
  MOV   DR,[W]		; USE RETURN TOP AS DATA ADDRESS
  inc   W			; INCREMENT ADDRESS
  JMPS  @RINCW			; INCREMENT ADDRESS

P_ _RSTBP			; C!R+
  R_TO 	W			; USE RETURN TOP AS DATA ADDRESS
  STOSB
  JMPS  @WSAVE			; FETCH NEXT DATA TO TOP

P_ _RSTP			; !R+
  R_TO 	W			; USE RETURN TOP AS DATA ADDRESS
  STOSW
@WSAVE:
  TO_R  W
  DROP_
  JMPS  @MAIN			; FETCH NEXT DATA TO TOP

P_ _RLDBP			  ; C@R+
  R_TO 	W			  ; TAKE TOP OF THE RETURN STACK
  MOV   DRL,[W]	; USE RETURN TOP AS DATA ADDRESS
  CLR   DRH
@RINCW:  
  inc   W			  ; INCREMENT ADDRESS
@DUPW:  
  TO_R  W			  ; STORE ADDRESS BACK TO RETURN STACK
@DUP:  
  PUSHR_	TOP	    ; DUPLICATE DATA TOP REGISTER
@XCHG:  
  XCHG  TOP,DR
  JMPS  @MAIN

P_ _XCHG				; XCHG
  R_TO	DR			; EXCHANGE TOP ELEMENTS
  TO_R  TOP			; OF TWO STACKS
  JMPS  @XCHG 
  
P_ _XA				  ; XA
  R_TO	W			  ; EXCHANGE RETURN TOP ELEMENT
  TO_R 	ar			; 
  MOV	ar,W		  ; WITH ADDED REGISTER
  JMPS  @MAIN 
  
; MAIN  LOOP  ---------------------------------------

P_ _EX
  R_TO  DR
@NEST:				  ; (NEST
  to_r  IP			; PUSH OLD IP
  to_r  DR		; PUSH NEW IP
@RETURN:
  r_to  IP			; POP IP FROM RETURN TOP ELEMENT
  
P_ _NOP  
@MAIN:
  MOV   DR,[IP]	
  INC   IP
  INC   IP
  test 	DRL,1		; ADDRESS ODD ?
  je    @nest		; NOT ODD ADDRESS - NEST THEN
  dec   DR			; MAKE ODD ADDRESS EVEN
  JMP   DR			; BRANCH TO PRIMITIVE

;  STACK COMMANDS   PUSH DUP

P_ _NIP
  SWAP_
P_ _DROP				; DUPLICATE TOP
  JMPS  @DROP

P_ _NFOR
  NOT   TOP
P_ _FOR
  MOV   IP,[IP]		; JUST BRANCH
P_ _PUSH				; PUSH
  TO_R	TOP
@DROP:
  DROP_
  JMPS  @MAIN

P_ _J				  ; J - DATA FROM SECOND ELEMENT OF RETURN STACK
  R_TO  W			; POP W FROM RETURN
  R_TO  DR		; POP TOP FROM RETURN  - SECOND ELEMENT
  TO_R  DR		; PUSH TOP
  TO_R  W			; PUSH W - STATE OF RETURN STACK IS 
  JMPS  @DUP	;          LIKE BEFORE OPERATION
  
P_ _DUP				; DUPLICATE TOP
  TO_R	TOP		; PUSH TOP TO RETURN STACK
@POP:  
  R_TO  DR		; - THIS WAY WE ACHIVE DUPLICATE OF TOP
  JMPS  @DUP		
  
P_ _STKP			; STACK PTR
  TO_R  DSP
  SKIPA
P_ _OVER			; DUPLICATE NEXT
  TO_R  NXT
P_ _POP				; POP 
  JMPS  @POP
  
  
P_ _RDROP
  R_TO  DR
  SKIPA
P_ _SWAP
  SWAP_
  JMPS  @MAIN
   
; MATH, LOGIC AND SHIFT COMMANDS   +2/ +* -/ NAND

P_ _XOR				  ; XOR - LOGICAL PRIMITIVE
  XOR     NXT,TOP	  ; XOR TO SECOND DATA ELEMENT - NEXT
  JMPS    @DROP
  
P_ _MDIV				  ; -/ DIVIDE PRIMITIVE
  SHL	  NXT,1     ; SHIFT LEFT NEXT TO CARRY
  RCL   TOP,1		  ; ROTATE LEFT WITH CARRY
  CMP   TOP,ar		; COMPARE TOP WITH AR
  JB	  @MDIV		  ; IF BELOW SUBTRACT IS NOT POSSIBLE
  SUB   TOP,ar		; SUBTRACT SAR FROM TOP
P_ U1P  
  INC	  NXT	      ; SUCSESSFULL SUBTRACT
@MDIV:  
  JMPS  @MAIN
   
P_ _P2DIV			    ; +2/ SUM AND SHIFT PRIMITIVE
  ADD   NXT,TOP		; NEXT := NEXT + TOP;
  MOV	  TOP,NXT		; PREPARE FOR SHIFT
P_ _2DIV  
  RCR   TOP,1		  ; SHIFT RIGHT TOP WITH CARRY
  JMPS  @MAIN
   
P_ _PMUL				  ; +* MULTIPLY PRIMITIVE
  TEST	NXT,1     ; TEST LEAST SIGNIFICANT BIT
  JE    @PMUL2		; IF CLEAR - NOT ADD
  ADD   TOP,ar		; ADDING SAR TO TOP
P_ _D2DIV  
@PMUL2:
  RCR   TOP,1		  ; JUST SHIFT RIGHT TOP WITH CARRY
  RCR   NXT,1     ; SHIFT RIGHT NEXT WITH CARRY
  JMPS  @MAIN
   
P_ _NAND				  ; NAND - LOGICAL PRIMITIVE
  AND   NXT,TOP	  ; AND TO SECOND DATA ELEMENT - NEXT
  DROP_
@NOT:
  INC   TOP
P_ _NEG  
  NEG	TOP			    ; NOT  2  1 & 2 => NAND
  JMPS  @MAIN
P_ _NOT
  JMPS  @NOT
  
; L_ _CTX;,@CTX      ; ( c -- ) \ Send character c to output device.
;  DW  _IO      ; char in DL
;  CMP   AL,0FFH ; 0FFH is interpreted as input
;  XCHG  AX,DX
;  JNZ   @TX1    ; do NOT allow input
;  MOV   DL,32   ; change to blank
;@TX1:
;  MOV   AH,6    ; MS - DOS Direct Console I/O
;  INT   021H    ; display character
;  RET
;  
; L_ _?CRX;,@?CRX      ; (  -- c T | F )  
;  DW _IOD
;  X
;  MOV   DX,0FFFFH ; input command & setup for TRUE flag
;  CALL  @TX1      ; MS - DOS Direct Console I/O
;  JNZ   QRX0    ; ?key ready
;  INC   DX      
;  JMPS  QRX3
;QRX0:  
;  OR    AL,AL   ; AL=0 if extended char
;  JNZ   QRX1    ; ?extended character code
;  INT   021H    ;
;  STC
;QRX1:
;  MOV   AH,0
;  JNC   QRX2
;  XCHG  AH,AL   ; extended code in msb
;QRX2:
;  PUSH  AX
;QRX3:
;  PUSH  DX
;  X
;  RET


 L_ _PARS
  DW  _IO
  XCHG    CX,AX
  MOV     DI,[DSP]    
  MOV     AX,[DSP+2]
	JCXZ 	  @@SKIPX
	SUB  	  DI,CX	   
	CMP  	  AL,' '
	JNE  	  @@SKIPX
	REPE 	  SCASB
	JE   	  @@SKIPX
	DEC  	  DI
	INC  	  CX
@@SKIPX:
  MOV     [DSP+2],DI    ;  START OF THE SOURCE
	JCXZ  	@@WEX
	REPNE 	SCASB
	JNE   	@@WEX
	DEC   	DI
@@WEX:                ; END OF THE SOURCE  IN DI
	SUB     DI,[DSP+2]    ; LENGTH OF THE WORD
	MOV     [DSP],DI      ; LENGTH OF THE WORD
  XCHG    CX,AX         ; IN CX REMAINS LENGTH OF THE BUFFER
  RET
	
; -----------------------
; searching
; -----------------------

 L_ _CFIND
  DW  _IO
  INC     PB [BX]
  CALL    @FIND  
  DEC     PB [BX]
  RET
  
 L_ _FIND
  DW  _IO
@FIND:  
  CLR     CX 
  MOV     DX,BX
  XCHG    TOP,DI
@FND?:  
  ADD     DI,CX
  LEA 	  DI,[DI+4]
  mov 	  cl,byte[Di]
  jcxz	  @DCX ;not_fnd
  inc 	  cx
  PUSH    DSP
  MOV     SI,DX
  repe	  cmpsb
  POP     DSP
  jNZ 	  @FND?
	MOV		  CL,2
	ADD		  [DI+2],CX
  MOV     [DSP],DI
@DCX: 
  XCHG    TOP,CX
  RET

;----------------   NUMBERS	 ---------------------

@ATOI:
	CALL  	@@numini
	CALL  	@@SGN
@@GETC:	
  JCXZ    @@EXNUM2
	LODSB	
	deC   	CX
	CALL  	DX
	JMPS	  @@GETC
  
COMOPT  DW @@B16,@@B8,@@B2,@@KOLI,@@ACCUM,@@DIEZ
OPTAB   DB "$&%'^#"

@@SGN:	
	JCXZ  	@@ERNUM
  CALL    @@STATE
	CMP   	AL,'-'     ; SGN
	JNE   	@@N16
	POP   	BX
	CALL  	BX         ; return to caller
	NEG   	nacc
@@EXNUM2: 
  RET

@@DIEZ:	
	XCHG  	nacc,AX
  
@@numini:	
	CLR    	nacc      ; ZEROING ACCUMULATOR
  SKIPA
  
@@B2:
	MOV		  AL,2        ; BIN
  SKIPA 
    
@@B8: 
	MOV		  AL,8        ; OCT
  SKIPA 
    
@@B16:                ; HEX
	MOV		  AL,16
  
@@setbas:	
	DEC   	AX
	DEC   	AX
	xor   	ah,ah
	mov   	nbase,ax
	INC   	nbase
	INC   	nbase
@@NORMAL?:
  CALL    @@STATE
  
@@N16:	
  PUSH    BX
	MOV		  BX,6-1
@@SCANB1:	
	CMP		  AL,OPTAB[BX]
	JE		  @@SCANB2	
	DEC		  BX
	JNS		  @@SCANB1	
@@SCANB2:	
	SHL		  BX,1
	MOV		  DX,COMOPT[BX]
  POP     BX
  JS      @@N5
	JCXZ    @@ERNUM
  RET
  
@@ERNUM:	
	MOV   	CX,SI
@@STATE:	
	pop   	Dx    ; rdrop
	RET
  
@@N5:	
	cmp   	al,'9'+1
	jc    	@@ton2
	cmp   	al,'A'      ; no case sensivity
	jc    	@@ERNUM
	sub   	al,7
@@ton2:	
	sub   	al,'0'
	cmp   	ax,nbase
	jnc   	@@ERNUM
@@ACCUM:	
	Xchg  	nacc,AX
	mul   	nbase
	Xchg  	nacc,AX
	add   	nacc,ax
	JMPS    @@NORMAL?
  
@@KOLI:	
	AND	  	AL,31
	JMPS  	@@ACCUM
  
 L_ _ATOI
  DW  _IO
  PUSH    NBASE DSP
  XCHG    AX,CX
  MOV     SI,[DSP]
	MOV     AL,10   	; BASE 10 INITIALLY
	CALL	  @ATOI
  POP     DSP NBASE
  MOV     [DSP],nacc
  XCHG    AX,CX
	RET

 L_ _MPUSH ; TOP OF DICTIONARY   IN DI
  DW _IO
	POPR_   DI
	POPR_	  CX
  CALL    @MAKESTR
  INC     AX
  RET

 L_ _MAKESTR         ; ("!
  DW _IO
	POPR_   DI
	POPR_	  CX
  MOV     CH,0
  ADD     DI,CX
  INC     DI          ; SPACE FOR LENGTH
  MOV     PB [DI],'`' ; IMMEDIATE SIGN
@MAKESTR:  
  XCHG    AX,SI
  to_r    CX
  ADD     SI,CX       ; AFTER NAME ADDRESS
  STD                 ; BACKWARDS
  CMPSB               ; PREPARE FOR DIRECTION
  REP     MOVSB       ; NAME (MEMORY) MOVE
  CLD
  r_to    cx
  MOV     [DI],CL     ; LENGTH OF THE STRING
  XCHG    AX,SI
  XCHG    AX,DI
  RET

    
L_ _EndMem

;lastw = ppppp

MyCseg  ends
        end  Start

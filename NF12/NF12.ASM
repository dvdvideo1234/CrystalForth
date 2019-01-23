; :TODO
; 1 DEBUGGER
; 2 UNIT TESTS FOR EVERY PRIMITIVE
; 3 DESA ASEMBLER DESASEMBLER
; 4 MODULED TARGET COMPILATION

A386  = 0   ; 0 - NO DEBUGER

TO_   = -2
AT_   = -4
VAL_  = 2

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

TWICE_  MACRO
  DW $+2
ENDM

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

nam_    macro   msg
  local endstr
  db    endstr-$-1
  db    msg
endstr  label   byte
        endm

IF A386

TRACE_OFF MACRO
  CALL  @NO_TRACE
ENDM

TRACE_ON MACRO
  CALL  @DO_TRACE
ENDM


ELSE

TRACE_OFF MACRO
  CALL  @RET
ENDM

ENDIF



DEFER_ MACRO NAM,VAL
L_ NAM  
  DW _JUMP,VAL
ENDM


VECTOR_ MACRO NAM,VAL
  ALIGN_ 0
  DW _SET2
  DEFER_ NAM,VAL
ENDM

DOER_ MACRO NAM2,VAL
  ALIGN_ 0
  DW _pntSET
  DEFER_ NAM2,VAL
ENDM

CONST_ MACRO NAM,VAL
L_ NAM  
  DW _CON,VAL
ENDM


VALUE_ MACRO NAM,VAL
  ALIGN_ 0
  DW _SET2
  CONST_ NAM,VAL
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
ar  = BP  ; BP ARITHMETIC ( ADDRESS ) register 
DR  = CX  ; CX DATA REGISTER
DRL = CL  ; CX DATA REGISTER
DRH = CH  ; CX DATA REGISTER


; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-  ;(IO
; RETURN STACK COMMANDS  POP PUSH 
; DATA STACK   COMMANDS  DUP J
; DATA TRANSF  COMMANDS  @R+ !R+ XCHG XR
; MATH         COMMANDS  +2/ +* -/ NAND

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

STKSZ   = 512+128
@R_TOP  = -64            
@S_TOP  = @R_TOP-STKSZ   
@TIB    = @S_TOP-STKSZ-256-@R_TOP   
@SBUF   = @TIB-256         
@TBUF   = @SBUF-256         
@VOCTOP = @TBUF-16

Start  Label byte   
L_ _START
  mov   ah,4ah     
  mov   bx,1000h        ; only 64k allocate
  int   21h
P_ _ABORT
  MOV   RSP,@R_TOP
  MOV   DSP,@S_TOP
  CALL  @RET            ; TRACE_OFF HOLE FOR STOPPING DEBUGGER
  CALL  _@4TH
_@INI:  
  DW 0  ; STARTUP ADDRESS  
          
; IO COMMANDS vvvvvvvvvv  ---------------------------

L_ _@BKEY
  DW 0    ;_VAR
L_ _BKEY
  DW _DUP,_IO
  CLR   AX
  INT   16H
  ZERO?_ TOPL
  JE  @RET
@W_TO_B:  
  CLR   TOPH
@RET: RET

P_ _OSTR          ; (?S
  R_TO 	W			    ; TAKE TOP OF THE RETURN STACK
  MOV   DRL,[W]	  ; USE RETURN TOP AS DATA ADDRESS
  CLR   DRH
  ADD   DR,W
  INC   DR
  INC   DR
  AND   DRL,0FEH
  XCHG  DR,W
  JMPS  @DUPW ; 

    
P_ _IO  				  ; IF INPUT PARAMS = OUTPUT PARAMS 
  MOV   DX,[DSP+4]
  MOV   CX,[DSP+2]
P_ _IO2  				  ; IF INPUT PARAMS = OUTPUT PARAMS 
  MOV   W,[DSP]   ; IP = BX
P_ _IO1  				  ; IF INPUT PARAMS = OUTPUT PARAMS 
  XCHG  W,IP
  INT   3
  CALL  W	 
P_ _RET  
  JMPS  _@4TH

; IO           COMMANDS  (IO  ^^^^^^^

; CONTROL      COMMANDS  ----------------------------

P_ _IF	 			; (IF
  Zero?_    TOP  
  drop_
  JE    @JUMP 
P_ _SKIP
@SKIP:
  INC   ip
  INC   ip
  JMPS  @MAIN

P_ _2MX
  DEC   TOP
  POP   IP
P_ _1M
  DEC   TOP
  SKIPB

P_  _BRK
  INT   3
  JMPS  @MAIN

@dbg:  
  jmp   debugerr
    
P_ _NEXT
  POP   W
  DEC   W
  PUSH  W
  SKIPC DRL
  
P_ _IFM    			; (IF-
  DEC   TOP			; DECREMENT TOP AND BRANCH ON POSITIVE 
  JS    @SKIP		; ON NEGATIVE - SKIP BRANCH
P_ _JUMP    		; (JUMP
@JUMP:
  MOV   IP,[IP]	; JUST BRANCH
  JMPS  @MAIN

; DATA TRANSFER  COMMANDS -----------------------------------

L_ _@BEMIT
  DW 0    ;_VAR
P_ _BEMIT
  MOV     AH,0EH
  INT     10H
  JMPS    @DROP
        
P_ _RSTP			  ; !R+
  R_TO 	W			  ; USE RETURN TOP AS DATA ADDRESS
  STOSW
@WSAVE:
  TO_R  W
  DROP_
  JMPS  @MAIN		; FETCH NEXT DATA TO TOP

P_ _RLDP			  ; @R+
  R_TO 	W			  ; TAKE TOP OF THE RETURN STACK
  MOV   DR,[W]	; USE RETURN TOP AS DATA ADDRESS
  SCASW			    ; INCREMENT ADDRESS
@DUPW:  
  TO_R  W			  ; STORE ADDRESS BACK TO RETURN STACK
@DUP:  
  PUSHR_	TOP	  ; DUPLICATE DATA TOP REGISTER
@XCHG:  
  XCHG  TOP,DR
  JMPS  @MAIN

P_ _XR				  ; XCHG
  R_TO	DR			; EXCHANGE TOP ELEMENTS
  TO_R  TOP			; OF TWO STACKS
  JMPS  @XCHG 
  
P_ _XA				  ; XA
  R_TO	W			  ; EXCHANGE RETURN TOP ELEMENT
  TO_R 	ar			; 
  MOV	ar,W		  ; WITH ADDED REGISTER
  JMPS  @MAIN 
  
; MAIN  LOOP  ---------------------------------------

P_ _2px
  INC   TOP
  R_TO	ip			 
P_ _1P
  INC   TOP
  SKIPA
P_ _RDRPX
  R_TO  DR
_@4TH:
  r_to  IP			; POP IP FROM RETURN TOP ELEMENT  
P_ _NOP
@MAIN:
  MOV   DR,[IP]
  ;JMPS  _@dbg
@MAIN2:  
  INC   IP
  INC   IP
@MAIN3:  
  test 	DRL,1		; ADDRESS ODD ?
  je    @nest		; NOT ODD ADDRESS - NEST THEN
  dec   DR			; MAKE ODD ADDRESS EVEN
  JMP   DR			; BRANCH TO PRIMITIVE
  
P_ _EXEC
	POPR_	DR
  JMPS  @MAIN3
  
P_ _EX
_@JSR4TH:
  R_TO  DR
@NEST:				  ; (NEST
  to_r  IP			; PUSH OLD IP
  MOV   IP,DR		; PUSH NEW IP
  JMPS  @MAIN   

;  STACK COMMANDS   --------------------------------

P_ _DROPX
  R_TO  IP
  SKIPa
P_ _NIP
  SWAP_
P_ _DROP				; DUPLICATE TOP
  JMPS  @DROP

  
P_ _NFOR
  NOT   TOP
P_ _FOR
  mov   ip,[ip]
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
  
P_ _POPX			; POP 
  R_TO  DR
  R_TO  IP
  JMPS  @DUP
  
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
P_ _U1P  
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
P_ _ZEQ
  NEG   TOP
  SBB   TOP,TOP
;P_ _NOT
  JMPS  @NOT
   
P_ _ULESS
  SUB   NXT,TOP
  DROP_
  SKIPR  CX
  
P_ _ODD
  SHR   TOP,1
@ODD:  
  SBB   TOP,TOP
  JMPS  @MAIN
  
P_ _0LESS
  SHL   TOP,1
  JMPS  @ODD
 
  
 L_ _MKSTR         ; S>"!
  DW _IO
	POPR_   DI
	POPR_	  CX
  MOV     CH,0
  ADD     DI,CX
  INC     DI          ; SPACE FOR LENGTH
  MOV     PB [DI],'`' ; IMMEDIATE SIGN
_@MAKESTR:  
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

  
L_ _MPUSH ; TOP OF DICTIONARY   IN DI
  DW _IO
	POPR_   DI
	POPR_	  CX
_@MPUSH1:
  CALL    _@MAKESTR
_@MPUSH2:
  INC     AX
  RET

 L_ _PARS
  DW  _IO 
  XCHG    CX,AX
  MOV     DI,BX    
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
@@WEX:                  ; END OF THE SOURCE  IN DI
	SUB     DI,[DSP+2]    ; LENGTH OF THE WORD
  MOV     NXT,DI
  XCHG    TOP,CX
  RET
	
; -----------------------
; searching
; -----------------------

 L_ _CFIND
  DW  _IO      
  INC     PB [BX]
  CALL    _@FIND  
  DEC     PB [BX]
  RET
  
L_ _TFIND?
  DW _NOP
L_ _FIND
  DW  _IO
_@FIND:  
  CLR     CX 
@FND?:  
  ADD     AX,CX
  MOV     DI,AX
  LEA 	  DI,[DI+4]
  mov 	  cl,PB [Di]
  jcxz	  @DCX ;not_fnd
  inc 	  cx
  PUSH    SI
  MOV     SI,BX
  repe	  cmpsb
  POP     SI
  XCHG    AX,DI
  jNZ 	  @FND?
	MOV		  CL,2
	ADD		  [DI+2],CX
  MOV     NXT,DI
@DCX: 
  XCHG    TOP,CX
  RET

;----------------   NUMBERS	 ---------------------

@@ADR   = BX
@@ACC   = DI
@@IND   = SI
@@BASE  = CX
@@OPADR = DX  ; OPTION ADDRESS
  
COMOPT  DW @@KOLI,@@TICK,@@DIEZ,@@HEX,@@OCT,@@BIN
;OPTAB   DB "^'#$&%"
OPTAB   DB "%&$#'^"

@@SGN:
  INC     @@IND                 ; ZERO LEN
	JZ     	@@ERNUM
  CMP     pb [@@ADR+@@IND],'-'  ; SGN?
  jne     @@EXSGN
  INC     @@IND                 ; SKIP '-'
	JZ     	@@ERNUM               ; LAST CHAR ?
	POP   	@@OPADR
	CALL  	@@OPADR         ; return to caller
@@DNEG:  
	;NEG   	@@acc
	not   	@@acc
	not   	AR
	inc   	@@acc
  jne     @@EXSGN
	inc   	AR
@@EXSGN: 
  RET

@@ERNUM:	
	DEC   	@@IND
@@STATE:	
	pop   	@@OPADR    ; rdrop
	RET
  
@@DIEZ:	
	XCHG  	@@acc,AX
  
@@numini:	
	CLR   	@@acc      ; ZEROING ACCUMULATOR
  CLR     AR        ; HI PART ACCUMULATOR
  SKIPA
@@HEX:
  MOV     AL,16
  SKIPA
@@OCT:
  MOV     AL,8
  SKIPA
@@BIN:
  MOV     AL,2
@@setbasE:	
	DEC   	AX
	DEC   	AX
	xor   	ah,ah
	mov   	@@base,ax
	INC   	@@base
	INC   	@@base
@@NORMAL?:
  CALL    @@STATE
  
@@N16:	
  PUSH    DI
  MOV     DI, OFFSET OPTAB
  PUSH    CX
  MOV     CX,6
  REPNE   SCASB
  MOV     DI,CX
  POP     CX
  JNE     @@N5	
  SHL     DI,1
	MOV		  @@OPADR,COMOPT[DI]
  POP     DI
  INC     @@IND
	JZ      @@ERNUM
  DEC     @@IND
  JMP     @@OPADR
  
@@N5:	
  POP     DI 
	cmp   	al,'9'+1
	jc    	@@ton2
	cmp   	al,'A'      ; no case sensivity
	jc    	@@ERNUM
	sub   	al,7
@@ton2:	
	sub   	al,'0'
	jc    	@@ERNUM
	cmp   	ax,@@base
	jnc   	@@ERNUM
@@ACCUM:	
	Xchg  	AR,AX
	mul   	@@base
	Xchg  	AR,AX
	Xchg  	@@acc,AX
	mul   	@@base
	Xchg  	@@acc,AX
	add   	@@acc,ax
  ADC     AR,DX
	JMPS    @@NORMAL?
  
@@TICK:  
  CALL    @@STATE
	JMPS  	@@ACCUM
@@KOLI:	
  CALL    @@STATE
	AND	  	AL,31
	JMPS  	@@ACCUM
  
@@ATOI:
	MOV     AL,10   	; BASE 10 INITIALLY
	CALL  	@@SGN
	CALL  	@@numini
@@GETC:	
  MOV     AL,[@@ADR+@@IND]
	CALL  	@@OPADR
  INC     @@IND
  JNZ     @@GETC
  RET

L_ _ATOI
  DW  _IO
  PUSH    DSP
  XCHG    TOP,@@IND
  LEA     @@ADR,[@@ADR+@@IND]
  NOT     @@IND
	CALL	  @@ATOI
  XCHG    TOP,@@IND
  POP     DSP
  MOV     NXT,@@ACC
  RET

L_ debugerr

  IF A386
  
  ;DW 0,0
  TRACE_OFF
  call  _@JSR4TH
  DW @EMIT,TO_+@SV_EMIT
  DW _@BEMIT,TO_+@EMIT
L_ _@DBGW     ; show stacks / address, code, nextcode & name  
  DW    0,0   
  DW @SV_EMIT,TO_+@EMIT
  dw   _BKEY,_FROMF
  TRACE_ON
  and   al,0dfh
  cmp   al,'S'
  DROP_
  jne   @@2
  TRACE_OFF
@@2:    
  POP   iP
  MOV   DR,[IP]	
  jmp   @MAIN2

L_ _TROFF
  DW    _JSR
@NO_TRACE:
  SKIPR DR
  MOV   DR,[IP]
  
@X_TRACE:
  XCHG  DR,PW @MAIN
  RET
  
L_ _TRON
  DW _JSR
@DO_TRACE:
  SKIPR DR
  DB 0EBH,@dbg-@MAIN2
  JMPS  @X_TRACE
  
 VALUE_ @SV_EMIT,0
 
P_ _FROMF
  JMP     IP
  
  ENDIF

    
L_ _EndMem

MyCseg  ends
        end  Start

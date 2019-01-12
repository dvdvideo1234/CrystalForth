
A386  = 0
TO_   = -2
AT_   = -4

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
  CALL  @RET            ; HOLE FOR STOPPING DEBUGGER 
  CALL  @RETURN
  
_@INIT  DW 0  ; STARTUP ADDRESS  

; VARIABLES ---------------------------------
;
; 0 VALUE; H
_HX     DW _H,_EX,_SET2
_H      DW _CON,_EndMem

; $F800 VALUE; T
        DW _SET2
_TX     DW _T,_EX,_SET2
_T      DW _CON,@VOCTOP
 
; 0 VALUE; LTIB
; 18 4 - 1K     U*  VAL' LTIB  T!
_LTIBX  DW _LTIB,_EX,_SET2
_LTIB   DW _CON,(18-5)*1024

; $100 18 1K U* + VALUE ETIB
        DW _SET2
_ETIB   DW _CON,18*1024+100H
        DW _SET2
_MSG    DW _CON,0 ; MESSAGE

_vNUMC  DW _JUMP,_TONUMC ; 0 DEFER 
_vTARG  DW _JUMP,_T      ; 0 DEFER 
 
; 0 CONST 0     \ >,
_0      DW _CON,0
   
; $20 CONST BL
_BL     DW _CON,20H 
 
; $80 CONST TBL
_TBL    DW _CON,80H 
  
; $FF00 CONST TBUF
_TBUF   DW _CON,@TBUF   
_SBUF   DW _CON,@SBUF   
_TIB    DW _CON,@TIB   

;---------------------------------------
 
; HI LEVEL PRIMITIVES 


_DZ0    DW _POP,_XR
_NOPX   DW _RET
; : (SET2 @R+ DROP 
_SET2   DW _RLDP,_DROP
; : (SET !R+ RDROP; ; UNW
_SET    DW _RSTP,_RDRPX ; UNW

; _MARKF  DW  _H
; _ZCOMMA DW  __@COM,0
; _RELSB  DW  _H
; _SWPST  DW  _SWAP
; ; : ! PUSH        : (SET !R RDROP; ; UNW
; _ST     DW _PUSH
; _SET    DW _RSTP,_RDRPX ; UNW

; : @ PUSH        : (CON @R       : EXIT RDROP; ; UNW
__@COM  DW _DZ0   ; (@,
_@COM   DW _XCOM  ; @,
_LD     DW _PUSH  ; @     
_CON    DW _RLDP  ; (CON     
_EXIT   DW _RDRPX ; UNW
; 
; : STR PUSH @R+ XR POP; ; UNW 
_STR    DW _PUSH,_RLDP,_XR,_POPX 

; : CSTR PUSH C@R+ XR POP; ; UNW 
_CSTR   DW _PUSH,_RLDBP,_XR,_POPX 

; : @, PUSH   : (@, @R+ RDROP 
;_@@COM  DW _R 
;_COMAER DW _RLDP,_SKIP
; : ;, EX 
_XCOM   DW _EX
;: ,  H; : !+ PUSH !R+ POP; ; UNW 
_COMMA  DW _HX 
_STP    DW _PUSH,_RSTP
_VAR    DW _POPX

;_XCOMMA DW _EX,_JUMP,_COMMA 
_XLIT   DW _EX
_LITCC  DW _XCOM
; : (LIT, (@, (LIT ,<
_COMLIT DW __@COM,_LIT
; : (LIT @R+ ;  (#
_LIT    DW _RLDP,_RET 


; : ((A" (?S SWAP DROP; ?; 
_ABDOT  DW _OSTR,TO_+_MSG
        ;DW _BRK
        DW _IF,_NOPX,_ABORT 
 
; : ;#?? EX   : #?? 0=  ?? ;
_XN??     DW _EX   
_N??      DW _ZEQ;,_?? ;
_??       DW _ABDOT
          NAM_ "?" 
          DW _RET
          
          
; IO COMMANDS vvvvvvvvvv  ---------------------------

P_  _BRK
  INT   3
  JMP   @MAIN

;L_ _TOBYTE
;  DW _IO
;  JMPS  @W_TO_B
  
L_ _BK
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
  XCHG  W,IP
  MOV   BX,[DSP]
  MOV   CX,[DSP+2]
  MOV   DX,[DSP+4]
  CALL  W	 ; ,"^\~|~?~^V^A+~^R~+~X+~^S~+~^Q~+~C~"
  JMPS  @RETURN

; IO           COMMANDS  (IO  ^^^^^^^

; CONTROL      COMMANDS  ----------------------------

P_ _?SKIP			; ?SKIP
  Zero?_    TOP  
  JZ    @SKIPDR
  JMPS  @MAIN

P_ _IF	 			; (IF
  Zero?_    TOP  
  JE    @JUMPDR 
  
P_ _SKIPDR
@SKIPDR:
  DROP_
P_ _SKIP
@SKIP:
  INC   ip
  INC   ip
  JMPS  @MAIN

P_ _IFM    			; (IF-
  JMPS  @IFM
  
P_ _NEXTP
  POP   DR
  INC   DR
  JE    @SKIP  
@JUMPPH:
  PUSH  dr
  JMPS  @JUMP
    
P_ _NEXT
  POP   DR
  DEC   DR
  JS    @skip
  JMPS  @JUMPPH
  
P_ _MIF    			; (-IF
  INC   TOP
@IFM:
  DEC   TOP			; DECREMENT TOP AND BRANCH ON POSITIVE 
  JS    @SKIP		; ON NEGATIVE - SKIP BRANCH
  JMPS  @JUMP 
  
P_ _NFOR
  NOT   TOP
P_ _FOR
  TO_R	TOP
@JUMPDR:  
  DROP_
P_ _JUMP    			; (JUMP
@JUMP:
  MOV   IP,[IP]		; JUST BRANCH
  JMPS  @MAIN

; DATA TRANSFER  COMMANDS -----------------------------------

P_ _BE
  MOV     AH,0EH
  INT     10H
  JMPS    @DROP
        
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

P_ _1PX
  INC   TOP
  SKIPA
P_ _RDRPX
  R_TO  DR
P_ _RET  
@RETURN:
  r_to  IP			; POP IP FROM RETURN TOP ELEMENT  
@MAIN:
  MOV   DR,[IP]	
  LEA   IP,[IP+2]
  test 	DRL,1		; ADDRESS ODD ?
  je    @nest		; NOT ODD ADDRESS - NEST THEN
  dec   DR			; MAKE ODD ADDRESS EVEN
  JMP   DR			; BRANCH TO PRIMITIVE
P_ _EX
  R_TO  DR
@NEST:				  ; (NEST
  to_r  IP			; PUSH OLD IP
  MOV   IP,DR		; PUSH NEW IP
  JMPS  @MAIN   

;  STACK COMMANDS   --------------------------------

P_ _NIP
  SWAP_
P_ _DROP				; DUPLICATE TOP
  JMPS  @DROP

P_ _DROPX
  R_TO  IP
  SKIPB
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
P_ _ZEQ
  NEG   TOP
  SBB   TOP,TOP
P_ _NOT
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
 
        ; : TOKEN?  ;#??  
L_ _TOKEN?  
  DW _XN??
        ; : TOKEN BL  [ ?C@ ]
_TOKEN:
  DW _BL,_WORD
; : ?C@ DUP : C@ PUSH C@R+ RDROP; ; UNW 
_?C@    DW _DUP 
_C@     DW _PUSH
_BCON   DW _RLDBP,_RDRPX    ; (C@
  
; : WORD [ TBUF S>"! ] _XTBUF
_WORD:
  DW _XTBUF
        ; : PARSE NOP; ETIB LTIB; (PARS ;
_PARSE:
  DW _NOPX,_ETIB,_LTIBX
  ;,_BRK
  
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
  JMPS    @DCX2
	
; -----------------------
; searching
; -----------------------

 L_ _CFNDTAR
  DW  _vTARG
 L_ _CFIND
  ;DW _BRK
  DW  _IO      
  INC     PB [BX]
  CALL    @FIND  
  DEC     PB [BX]
  RET
  
L_ _COMTICK
  DW _XCOM
L_ _TICK
  DW _XN??,_TOKEN? 
L_ _FINDT
  DW _T
L_ _FIND
  ;DW _BRK
  DW  _IO
@FIND:  
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
@DCX2:  
  MOV     NXT,DI
@DCX: 
  XCHG    TOP,CX
  RET

;----------------   NUMBERS	 ---------------------

; : ">NUMC ;,  (LIT, :;
 
L_ _TONUMC   
  DW _XLIT; _XCOMMA,_SEMIGO,_COMLIT 
  
; : ">NUM CSTR (NUM   : ?? !"?" ;;  
L_ _TONUM    
  DW _CSTR,_ATOI,_JUMP,_??
  ;DW _BRK

L_ _ATOI
  DW  _IO

@@ADR   = BX
@@ACC   = DI
@@IND   = SI
@@BASE  = CX
@@OPADR = DX  ; OPTION ADDRESS
  
  PUSH    DSP
  XCHG    TOP,@@IND
  LEA     @@ADR,[@@ADR+@@IND]
  NOT     @@IND
	CALL	  @@ATOI
  XCHG    TOP,@@IND
  POP     DSP
  MOV     NXT,@@ACC
  RET

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
  
@@ERNUM:	
	DEC   	@@IND
@@STATE:	
	pop   	@@OPADR    ; rdrop
	RET
  
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
  
; : H>DICT H STR  : >DICT T; MPUSH ;
;     
L_ _HDICT    
  DW _H,_STR  
L_ _TODICT   
  DW _TX 
  
L_ _MPUSH ; TOP OF DICTIONARY   IN DI
  ;DW _BRK
  DW _IO
	POPR_   DI
	POPR_	  CX
  CALL    @MAKESTR
  INC     AX
  RET

;TBUF S>"! ]  
L_ _XTBUF
  DW      _EX
_TOTBUF:
  DW      _TBUF
  
 L_ _MKSTR         ; S>"!
  ;DW _BRK
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

MyCseg  ends
        end  Start

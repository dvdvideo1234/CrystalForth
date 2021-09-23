; COMMANDS      OF INTERPRETER  (MINIMAL SET)
; (JUMP (; (IF (IF-   CONTROLS
; push pop J DUP      STACK
; !R+ @R+ xR XA       TRANSFER
; NAND +2/ +* -/      MATH & LOGIC

locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_   = -2
AT_   = -4
VAL_  = 2

JMPS_   MACRO LBL
  jmp   SHORT LBL
  ENDM

SKIPA_  MACRO
  DB    03DH
  ENDM

SKIPB_  MACRO
  DB    03CH
  ENDM

SKIPr_  MACRO reg
  mov   reg,0
  org   $-2
  ENDM

SKIPc_  MACRO reg
  mov   reg,0
  org   $-1
  ENDM

X       MACRO
  xchg  Rsp,DSP
  ENDM

R2P_    macro   REG
  INC   REG
  INC   REG
  endm

R2M_    macro   REG
  DEC   REG
  DEC   REG
  endm

NIP_   macro
  R2P_ DSP ; LEA  DSP,[DSP+2]
  endm
        
DROP_   macro
  X
  POP   T
  X
  endm

DUP_    macro  REG
  X
  PUSH  REG
  X
        endm

SWAP_   macro
  XCHG  [DSP],T
  endm

rchg_   macro   reg
  xchg  ax,reg
  endm

Zero?_  MACRO   REG
  OR    REG,REG
  ENDM

CLR_    MACRO   REG
  XOR    REG,REG
  ENDM

ALiGN_  MACRO  FLAG
  IF ($-START+FLAG) AND 1
  NOP
  @NOPSCNT = @NOPSCNT+1
  ENDIF
  ENDM
        
@NOPSCNT = 0        

P_  MACRO NAM
  ALIGN_ 0
  NOP
NAM:
  org   $-1
  ENDM

L_  MACRO NAM
  ALIGN_  0
NAM:
  ENDM

N_  MACRO
  JMP SHORT   @NOP
  ENDM
  
; REGISTERS     for interpretter
T   = BX  ; DATA STACK TOP REGISTER
TL  = BL  ; DATA STACK TOP REGISTER
TH  = BH  ; DATA STACK TOP REGISTER
IP  = SI  ; INSTRUCTION POINTER
RSP = SP  ; RETURN STACK POINTER
DSP = BP  ; DATA STACK POINTER
AR  = DX  ; ARITHMETIC (ALTERNATIVE) REGISTER

WA  = DI  ; WORK ADDRESS REGISTER
;NP  = CX  ; TO NEXT POINTER
W   = AX  ; WORK REGISTER
WL  = AL  ; WORK REGISTER
WH  = AH  ; WORK REGISTER

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

@TBUF   = -256          ;  256
@TIB    = @TBUF  * 2    ;  256
                        ;  512 B FSTACK
@R_TOP  = @TIB   * 2    ; 1024 B RSTACK
@S_TOP  = @R_TOP * 2    ; 2048 B DSTACK
@VOCTOP = @S_TOP * 2    ; 4096 B = 4 BUFFERS * 1024 B

Start   Label byte
;_START:

 P_ _ABORT,@ABORT
    MOV     RSP,@R_TOP-2
    MOV     DSP,@S_TOP-2
    CALL    @DBG
    CALL    @RET
 L_ _@INIT,@INIT  
    DW      7 DUP(0) ; RESERVE SPACE FOR MAIN LOOP
  
 ;vvvvvv--------------   IO  ---------------

 P_ _ALPHA
		CMP		T,10
		JB		@ALP
		ADD		T,7
@ALP:    
 P_ _ALP
		ADD		T,'0'
    JMPS_   @NOP
 
 P_ _PLSX
    ADD  T,[IP]
    JMPS_   @RET
                
 P_ _ANDX
    AND  T,[IP]
    JMPS_   @RET
                
 P_ _QARY 
        SHL     T,1
 P_ _LARY    
        SHL     T,1
 P_ _WARY 
        SHL     T,1
 P_ _BARY
        LEA     T,[T+IP]
        JMPS_   @RET
 
 P_ _INT 
   LODSW
   MOV     PB @INT,AL
   PUSH    AR DS ES
   X
	 XCHG	AX,T
   POP BX  CX  DX
   INT     21H
@INT = $-1
   PUSH  DX CX BX AX
	 PUSHF
   POP T
   X
   POP ES DS 
@TOA1:  POP     AR 

 P_ _RET               ; ( (;
@RET:
    POP     IP
    JMPS_   @NOP
@DBG:   RET 

 P_ _RDROP      ; RDROP
    POP     W
    JMPS_   @NOP
		
 P_ _CRSTP		       ; (C!R+
    POP     WA
    XCHG    T,W
    STOSB
    PUSH    WA
    JMPS_   @DROP       
        
 P_ _RSTP              ; (!R+
    POP     WA
    XCHG    T,W
    STOSW
    PUSH    WA
    JMPS_   @DROP  
		    
 p_ _BE		           ; (BE
		XCHG    AX,T
    MOV     AH,0EH
    INT     10H
@DROP:          
    MOV   T,[DSP]       
 P_ _NIP
    NIP_
    N_

 P_ _AST                   ; A!
		MOV		AR,T
    JMPS_   @DROP
		
 P_ _FOR				; (FOR
    MOV     IP,[IP]
 P_ _PUSH		       ; (PUSH
    PUSH    T
 P_ _DROP              ; (DROP
    JMPS_   @DROP

 P_ _PUSHX             ; (PUSH;
		PUSH	T
 P_ _DROPX             ; (DROP;
    POP     IP
    JMPS_   @DROP
		
 P_ _OVER
    push    [DSP]
    SKIPB_
 P_ _CSEG
    PUSH    CS
    SKIPB_
 P_ _SPLD
    PUSH    DSP
    SKIPB_
 P_ _RPLD
    PUSH    RSP
    SKIPB_
 P_ _ALD
    PUSH    AR
    SKIPB_
 P_ _DUP           ; ( DUP
    PUSH    T
@RPOP:  POP     W
@WPUSH: DUP_    T
    MOV     T,W 
    SKIPA_
@NEST:  
    XCHG    IP,W
@RPUSH:
    PUSH    W
 P_ _NOP        
@NOP:   LODSW
    TEST    WL,1
    JZ      @NEST
    DEC     W
    JMP     W
		
 P_ _SLSKIP,@SLSKIP            ; ("SKIP  "
		POP		WA
    MOV   w,[WA]
    mov   wh,0
    OR      wl,1        ; MAKE CNT ODD
    ADD     w,WA
    XCHG    w,WA
    JMPS_   @WPUSH1
		
;-------------------------------------------
; CONTROL
;-------------------------------------------

 P_ _IFM	         ; (IF-
    JMP  SHORT    @IFM2
        
 P_ _NEXT,@NEXT        ; (NEXT
    POP     W
    DEC     W
    PUSH    W
    SKIPR_  W
 P_ _MIF	
    INC     T        
@IFM2:
    DEC     T        
    JS      @SKIP
 P_ _JUMP              ; (JUMP
@JUMP:
    MOV     IP,[IP]
    N_
		
 P_ _SKIP		        ; (SKIP
    jmp short @SKIP
    
 P_ _IF,@IF            ; (IF
    Zero?_ t
		DROP_
    JZ      @JUMP
		
@SKIP:
    LODSW
    N_
		
 P_ _RLDP              ; (@R+
    POP     WA
    MOV     w,[WA]
    INC     WA
    JMPS_   @WPUSH1
        
 P_ _CRLDP                 ; ( C@R+
		POP		WA
    MOV   w,[WA]
    mov   wh,0
@WPUSH1:        
    INC     WA
@_J:
    PUSH    WA      
    jMPS_   @WPUSH
        
 P_ _J,@J                ; ( J
    POP     WA
    POP     W
    PUSH    W
    JMPS_   @_J

 P_ _POP
    JMPS_   @RPOP    ; ( POP
 P_ _EX,@EX              ; ( EX
    POP     W
    JMPS_   @NEST        
 P_ _XR,@XR              ; ( XR  XCHG
    POP     W
    XCHG    T,W
    JMPS_   @RPUSH        
 P_ _XA,@XA              ; ( XA
    POP     W
    XCHG    W,AR
    JMPS_   @RPUSH
    
 P_ _PLAVG				; ( +2/
    ADD     T,[DSP]
    MOV     [DSP],T       
 P_ _2DIV               ; ( 2/
@2DIV:  RCR     T,1
@NOP2:  JMPS_   @NOP
		
 P_ _SDIV,@SDIV          ; ( -/
    SHL     PW [DSP],1
    RCL     T,1
    CMP     T,AR
    JB      @NOP
    SUB     T,AR        
		INC     PW [DSP]
    JMPS_   @NOP2
		
 P_ _PMUL,@PMUL          ; ( +*
    TEST    PB [DSP],1
    JNZ     @D2DIV
    ADD     T,AR
 P_ _D2DIV
@D2DIV: RCR     T,1
    RCR     PW [DSP],1
    JMPS_   @NOP2
		
 P_ _nAND	          ; ( AND
    AND     T,[DSP]
    NIP_
@NOT:   INC     T
 P_ _NEG,@NEG
    NEG     T
    JMPS_   @NOP2
 P_ _0LESS
    SHL     T,1
    SBB     T,T
    JMPS_   @NOP2
  
 P_ _ZEQ
    NEG     T
    SBB     T,T
 P_ _NOT
    JMPS_  @NOT
        
 P_ _SWAP
		XCHG	T,[DSP]
    JMPS_   @NOP2

; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

@PAX:
		PUSH	AX
		MOV		AL,AH
		CALL	@@PB
		POP		AX
@@PB:
		PUSH	AX
		SHR		AL,1
		SHR		AL,1
		SHR		AL,1
		SHR		AL,1
		CALL	@@PD
		POP		AX
@@PD:	
		AND		AX,15
		CMP		AL,10
		JB		@ALP1
		ADD		AL,7
@ALP1:
		ADD		AL,'0'
@PC:	MOV		AH,0EH
		INT		10H
		RET

@PHEX:  CALL	@PAX	
@PSPC:	MOV		AL,' '
		JMP		@PC

 P_ _BRK
		MOV   AX,[DSP+2]
		CALL	@PHEX
		MOV   AX,[DSP+0]
		CALL	@PHEX
		MOV		AX,BX
		CALL	@PHEX
		
		CALL	@PSPC

		MOV		AX,IP
		CALL	@PHEX
		MOV		AX,RSP
		CALL	@PHEX
		MOV		AX,DSP
		CALL	@PHEX
    INT 3
    JMP     @NOP
		NOP

MyCseg  ends
        end  Start

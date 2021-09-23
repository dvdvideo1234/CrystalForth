MADR    = 0          ;  HI MEMORY ADDRESS POINTER
DBG = 0

INCLUDE C4F.IMC

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h


Start   Label byte

 ADRS_  @TBUF,260
 ADRS_  @TIB,260
 ADRS_  @R_TOP,512
 ADRS_  @S_TOP,504

        org 100h

@ABORT:
  MOV   DSP,PW @S_TOP
  MOV   RSP,PW @R_TOP
  CLD
  CALL  @EXDBGM
  DW    _NOP   ; _INIT
@MAINLP:                  ; TEXT INTERPRETTER
  DW    _NOP,_NOP,_NOP
__@OK:
  DW  _NOP,_JUMP,@MAINLP

XT_ _LDZST,$+2
  CLR_  W
  XCHG  W,[T]
  JMP   @XCHG

__NIP:
  DROP_ W
  JMP   WA

XT_ _CLOSE,$+2
  MOV   AX,3E00H
  INT   21H
  JMP   @DROP

XT_ _WFND,__PAR
  CALL  @AFND
  CMP   SI,[DI-3]
  RET
  
@NUM@:
  CALL  @@numini
  CALL  @@SGN
@@NUMZ:
  CALL  @@N1
  JMPS_ @@NUMZ

@@n1:
  cmp   al,'$'     ; BASE := 16
  JNE   @@N2
  MOV   al,16
  jmpS_ @@setbas

@@N2:   cmp  al,'#'     ; BASE := CX
  JNE   @@N3
  mov   al,Bl
@@numini:
  Xor   Bx,Bx      ; ACCUMULATOR
@@setbas:
  mov   DI,W
@@END?:
  JCXZ  @@ERNUM
@@GETC:
  deC   CX
  LODSB
  RET

@@N3:
  cmp   al,'9'+1
  jc    @@ton2
  AND   AL,0DFH
  cmp   al,'A'      ; no case sensivity
  jc    @@ERNUM
  sub   al,7
@@ton2:
  sub   al,'0'
  cmp   W,DI
  jnc   @@ERNUM
  xchg  W,Bx
  mul   DI
  xchg  W,Bx
  add   Bx,W
  JCXZ  @@EXNUM
  JMP   @@GETC
@@ERNUM:
  INC   CX
@@EXNUM:
  pop   DX    ; rdrop
@@noEXn:
  RET

@@SGN:
  CMP   AL,'-'     ; SGN
  JNE   @@N1
  POP   DX
  CALL  @@END?
  CALL  DX
  NEG   bX
  RET

XT_ _CSTR,__1PDUP
  DEC   T
  JMPS_ @C@

XT_ _STR,__2PDUP
  DEC   T
  DEC   T
@LD:  
  MOV   T,[T]
  JMPS_ @NOP2

XT_ _DC@,__DUP    
@C@:
  MOV   TH,[T]
@HWTOB:
  MOV   TL,TH
@WTOB:
  CLR_  TH
  JMPS_ @NOP2
  
XT_ _STM,__NIP
  MOV   [T-2],W
@2M:
  DEC   T
@1M:  
  DEC   T
  JMPS_ @NOP2

XT_ _STMB,__NIP
  MOV   [T-1],WL
  DEC   T
  JMPS_ @NOP2

XT_ _STP,__NIP
  MOV   [T],W
@2P:
  INC   T
@1P:  
  INC   T
@NOP2:
  JMP   @NOP

XT_ @DOES3,__POPIP
@4P:
  ADD   T,4
  JMPS_ @NOP2

@APLSL:
  ADD   [DSP],T
  JMPS_ @NOP2

XT_ @DOES,__POPIP
  JMPS_ @NOP2

XT_ @DOES2,__POPIP
  JMPS_ @2P


XT_ _FND,__PAR
  JMPS_  @NAMESCAN
  
XT_ _INT ,__PAR
  POP   AX
  MOV   PB @INTA,AL
  POP   AX BX CX DX
  PUSH  DS ES BP
  INT     21H
@INTA = $-1
  POP   BP ES DS 
  PUSH  DX CX BX AX
  PUSHF
  JMPS_ @RAP

@RDROP:
  POP   W
  JMPS_ @NOP1
@RDROPX:
  POP   W
  JMPS_ @RET
	
__SETPNT:
  MOV   [WA+2],IP
  JMPS_ @RET

@BRK3:
  INT 3
  JMPS_ @NOP1

XT_ _MFND,__PAR
  MOV   CL,4
  ADD   CL,[BX+3]
@NAMESCAN:
  CALL  @AFND
  PUSH  SI
  repe  cmpsb
  POP   SI
  RET
@AFND:
  POP   DX
  POP   WA
  POP   SI
NEXTfnd:
  ADD   WA,CX
  MOV   BX,WA
  LEA   WA,[BX+3]
  mov   cl,[WA]
  Jcxz  @FEND
  INC   CX
  CALL  DX
  jNZ   NEXTfnd
  MOV   CL,1       ; fnd_ok
  MOV   SI,BX
@FEND:  
  PUSH  SI
@END:  
  PUSH  CX
@RAP:
  POP   T
@RAP2:  
  X
  POP   AR 
@RET:
  POP   IP
@NOP1:  
  JMP   @NOP

;  CHAR etib ltib  /  START LEN ltib
XT_ _PARS,__PAR
  POP   CX WA W
  SUB   WA,CX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   WA
  INC   CX
@@SKIPX:
  MOV   BX,WA    ;  START OF THE SOURCE
  JCXZ  @@WEX
  REPNE SCASB
  JNE   @@WEX
  DEC   WA      ; END OF THE SOURCE
@@WEX:          ; CX REST LEN OF BUF
  PUSH  BX      ; START OF THE SOURCE
  SUB   WA,BX
  PUSH  WA
  JMPS_ @END

XT_ _MPOP,__PAR
  POP   DI CX SI
  REP   MOVSB   ; NAME  MOVE
  MOV   [DSP],DI  ; AR SET   AS END
  JMPS_  @RAP2

XT_ _MPUSH,__PAR
  POP   DI CX SI
  MOV   [DSP],DI  ; AR SET AS END
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  INC   DI
  MOV   T,DI    ; T SET AS START
  JMPS_  @RAP2
  
XT_ _num,__PAR    ;= (>#       ; (NUM
  ;INT   3
  POP   CX SI
  MOV   AX,10     ; base := 10
  CALL  @NUM@
  PUSH  BX
@AEND:  
  JMP   @END

__DRLD:
  MOV   T,[T]
__DROP:
  PUSH  WA
@DROPW:
  XCHG  W,T
@DROPT:
  DROP_  T
  RET

__POPIP:
  POP   IP
__POP:
  X
  PUSH  T
  X
  POP   T
  JMP   WA

__PAR:
  CLR_  CX  
  PUSH  IP AR
__parxt:  
  X
  PUSH  T
  JMP   WA
  
__2PDUP:
  INC   T
__1PDUP:
  INC   T
__DUP:
  PUSH  WA
@DUPT:  
  DUP_  T
  RET
  
@BE:         ; (BE
  XCHG  T,W
  MOV     AH,0EH
  INT     10H
  JMPS_   @DROP

__SETVAR:
  MOV   [WA+2],T
  JMPS_   @DROP  

@INC:
  INC     PW [T]
  JMPS_   @DROP  
		    
@DEC:
  DEC     PW [T]
  JMPS_   @DROP  
		    
__QARY:
  SHL     T,1
__LARY:   
  SHL     T,1
__WARY: 
  SHL     T,1
__BARY:
  LEA     T,[T+WA]
  JMP   @NOP

XT_ _BK,__DUP          ; (BK
  CLR_   W
  INT   16H
  ZERO?_    WL
  JE    @BK
  CLR_   WH
  JMPS_  @BK

@PUSHX:
	PUSH	T
@DROPX:
  POP   IP
  JMPS_ @DROP
  
XT_ _Xstk,__PARXT
  JMPS_ @DROP
  
@FOR:
  MOV   IP,[IP]
@PUSH:
  PUSH  T
@DROP:  
  MOV   T,[DSP]
@NIP:
  INC   DSP
  INC   DSP
  JMPS_   @NOP

@ALPHA:
  XCHG  T,W
	CMP		WL,10
	JB		@ALP1
	ADD		WL,7
@ALP1:
	ADD		WL,'0'
@BK:  
  JMPS_   @XCHG

__PLUS:
  ADD     T,[WA]
  JMPS_   @NOP
                
__AND:
  AND     T,[WA]
  JMPS_   @NOP
    
;------------------------------------------------------
  
XT_ _AST,__DROP         ; A!
	MOV		AR,W
  JMPS_   @NOP
	
XT_ _CSEG,__DUP
   MOV   T,CS
   JMPS_ @NOP

XT_ _SPLD,__DUP
   MOV   T,DSP
   JMPS_ @NOP

XT_ _RPLD,__DUP
   MOV   T,RSP
   JMPS_ @NOP

XT_ _ALD,__DUP
   MOV   T,AR
   JMPS_ @NOP

XT_ _DUP,__DUP           ; ( DUP
  JMPS_   @NOP
  
XT_ _TUCK,__DUP  
@MROT:      
		XCHG	T,[DSP+2]
@SWAP:
		XCHG	T,[DSP]
    JMPS_   @NOP

@ROT:      
		XCHG	T,[DSP]
@U2SWAP:    
		XCHG	T,[DSP+2]
    JMPS_   @NOP

XT_ _POP,__POP  
  JMPS_   @NOP

@LIT:
  LODSW
  JMPS_  @WPUSH

__VAR3:
  SCASW
__VAR2:
  SCASW
__VAR:
  XCHG  W,WA  
  JMPS_ @WPUSH
  
@XR:
  POP     W
  XCHG    T,W
  JMPS_ @RPUSH
@XA:
  POP     W
  XCHG    W,AR
  JMPS_ @RPUSH

__CONS3:
  SCASW
__CONS2:
  SCASW
__CONST:
  MOV     W,[WA]  
@WPUSH:
  DUP_    T
@XCHG:
  XCHG    T,W   
@NOP:   
  LODSW
  TEST    WL,1
@TEST:  
  JZ      @NEST
  INC     W
  XCHG    W,WA
  JMP     [WA-2]  
  
@EXDBGM:
  ;CALL  @DEBUGOFF
@EX:
  POP     W
@NEST:  
  XCHG    IP,W
@RPUSH:
  PUSH    W
  JMPS_   @NOP

XT_  _PERFORM,__DRLD
@TEST1:
  ZERO?_  W
  JE      @NOP
@TEST2:
  TEST    WL,1
  JMPS_ @TEST

XT_  _EXEC,__DROP
  JMPS_ @TEST2

XT_ _OVER,__DUP
  MOV   T,[DSP+2]
  JMPS_ @NOP
__DBG:
  JMP     @ABORT
		
__DEFER:
  MOV     W,[WA]
  JMPS_   @TEST1

__POINT:
  MOV     W,[WA]
  JMPS_   @NEST

XT_ _SLSKIP,__POP       ; ("SKIP  "
  MOV     wL,[T]
  MOV     WH,0
  ADD     w,T
  OR      wl,1        ; MAKE CNT ODD
  INC     W           ; ALIGN 2
  JMPS_   @RPUSH      ; W
		
XT_ _CRLDP,__POP      ; ( C@R+
  MOV     WL,[T]
  MOV     WH,0
@RLDP:  
  INC     T
  XCHG    T,W
  jMPS_   @RPUSH
       
XT_ _RLDP,__POP           ; (@R+
  MOV     W,[T]
  INC     T
  JMPS_   @RLDP
        
;-------------------------------------------
; CONTROL
;-------------------------------------------

@NEXT:
    POP     W
    DEC     W
    PUSH    W
    SKIPR_  W
@MIF:
    INC     T        
@IFM2:
    DEC     T        
    JS      @SKIP
@JUMP:
    MOV     IP,[IP]
    N_
		
    
XT_ _IF,__DROP         ; (IF
    ZERO?_ W
    JZ      @JUMP
@SKIP:
    LODSW
    N_
		
XT_ _J,__DUP                ; ( J
  POP     WA
  POP     T
  PUSH    T
@_J:
  PUSH    WA      
  JMPS_   @NOP

XT_ _CRSTP,__DROP       ; (C!R+
   POP     WA
   STOSB
   JMPS_   @_J       
       
XT_ _RSTP,__DROP        ; (!R+
   POP     WA
   STOSW
   JMPS_   @_J  
   
@PLAVG:
  ADD     T,[DSP]
  MOV     [DSP],T       
@2DIV:               ; ( 2/
  RCR     T,1
  JMPS_   @NOP3
	
@SDIV:          ; ( -/
  SHL     PW [DSP],1
  RCL     T,1
  CMP     T,AR
  JB      @NOP3
  SUB     T,AR        
@U1P:  
	INC     PW [DSP]
  JMPS_   @NOP3
	
@PMUL:          ; ( +*
  TEST    PB [DSP],1
  JNZ     @D2DIV
  ADD     T,AR
@D2DIV:
  RCR     T,1
  RCR     PW [DSP],1
@NOP3:  
  JMP     @NOP
		
XT_ _NAND,__DROP
  AND     T,W
@NOT:
  INC     T
@NEG: 
  NEG     T
  JMPS_   @NOP3

@0LESS:
  SHL     T,1
  SBB     T,T
  JMPS_   @NOP3
  
@ZEQ:
  NEG     T
  SBB     T,T
  JMPS_   @NOT
      
XT_ _NOP,@NOP
XT_ _BYE,0
P_ _APLSL,@APLSL
P_ _LIT,@LIT            ; (LIT
P_ _PUSHX,@PUSHX        ; (PUSH;
P_ _C@,@C@              ; (C@
P_ _HWTOB,@HWTOB        ; (HW>B
P_ _WTOB,@WTOB          ; (W>B
P_ _SKIP,@SKIP		      ; (SKIP
P_ _ROT,@ROT            ; (ROT
P_ _MROT,@MROT          ; (-ROT
P_ _SWAP,@SWAP          ; (SWAP
P_ _D2DIV,@D2DIV        ; (D2/
P_ _NEG,@NEG            ; (NEG
P_ _NOT,@NOT            ; (NOT
P_ _0LESS,@0LESS        ; (0<
P_ _ZEQ,@ZEQ            ; (0=
P_ _MIF	,@MIF           ; (-IF
P_ _2DIV,@2DIV          ; (2/
P_ _NEXT,@NEXT          ; (NEXT
P_ _DROPX,@DROPX        ; (DROP;
P_ _ABORT,@ABORT
p_ _INC,@INC	          ; (INC
p_ _DEC,@DEC	          ; (DEC
P_ _ALPHA,@ALPHA
P_ _RDROP,@RDROP        ; RDROP
P_ _RDROPX,@RDROPX      ; RDROPX
P_ _FOR,@FOR				    ; (FOR	
p_ _BE,@BE
P_ _EX,@EX
P_ _BREAK,@BRK3
p_ _2M,@2M
p_ _1M,@1M  
p_ _2P,@2P
p_ _1P,@1P  
P_ _NIP,@NIP
P_ _LD,@LD
   
;----------------------------------	CORE

P_ _IFM,@IFM2           ; (IF-        
P_ _JUMP,@JUMP          ; (JUMP
;P_ _IF,@IF             ; (IF
P_ _RET,@RET            ; (;

P_ _PLAVG,@PLAVG				; (+2/
P_ _SDIV,@SDIV          ; (-/
P_ _PMUL,@PMUL          ; (+*
;P_ _nAND,@NAND	        ; (NAND

P_ _PUSH,@PUSH          ; (PUSH
;P_ _POP,@POP           ; (POP
;P_ _J,@_DUP            ; (J
;P_ _DUP,@_DUP          ; (DUP

;P_ _RSTP,@_DUP         ; (!R+
;P_ _RLDP,@_DUP         ; (@R+
P_ _XR,@XR              ; (XR  
P_ _XA,@XA              ; (XA  



freemem:
  DW ENDMEM-FREEMEM-2
;    ENTRY_  _NOP,'NOP'
;    ENTRY_  _LIT,'(#'
;    ENTRY_  _RET,'(;'
;    ENTRY_  _ENTRY,'=:'
;    ENTRY_  _BYE,'BYE'
;  INCLUDE C4F.INM
  DW 0,0
EndMem:

;  DB ' 123 DROP DROP DROP DROP DROP BYE '


  
MyCseg  ends
        end  Start

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

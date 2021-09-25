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

JMPS   MACRO LBL
  jmp   SHORT LBL
  ENDM

SKIPA  MACRO
  DB    03DH
  ENDM

SKIPB  MACRO
  DB    03CH
  ENDM

SKIPr  MACRO reg
MADR = $
  mov   reg,0
  IF $-MADR-2
  org   $-1
  ENDIF
  org   $-1
  ENDM

X       MACRO
  xchg  Rsp,DSP
  ENDM

SWAP   macro
  XCHG  [DSP],TOP
  endm

Z?  MACRO   REG
  OR    REG,REG
  ENDM

CLR    MACRO   REG
  XOR    REG,REG
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
  POP   TOP
  X
  endm

DUP_    macro  REG
  X
  PUSH  REG
  X
        endm

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

PP_  MACRO NAM,LBL
  P_ NAM
LBL:
  ENDM

L_  MACRO NAM
  ALIGN_  0
NAM:
  ENDM

N_  MACRO
  JMP SHORT   @NOP
  ENDM

BUF_ MACRO ADR,LEN
  MADR = MADR - (LEN)
  ADR  = MADR
ENDM
 
VAR_    macro   LBL,DAT
LBL  DW __VAR,DAT
  ENDM

value_  macro   lbl,dat
  DW     __setvar
  CONST_ lbl,dat
  endm

CONST_  macro   lbl,dat
LBL  DW __cons,dat
  endm

DEFER_  macro   lbl,dat
LBL  DW __defer,dat
  endm

vector_ macro   lbl,dat
  DW     __setvar
  DEFER_  lbl,dat
  endm

point_  macro   lbl,dat
  DW __setpnt
  DEFER_  lbl,dat
  endm

entry_  macro ADR,nam
  DW    ADR,0
  nam_  nam
  endm

nam_    macro   msg
  local endstr
  db    endstr-$-1
  db    msg
endstr  label   byte
        endm

; REGISTERS     for interpretter
TOP   = BX  ; DATA STACK TOP REGISTER
TOPL  = BL  ; DATA STACK TOP REGISTER
TOPH  = BH  ; DATA STACK TOP REGISTER
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

MADR = 65535-15 ;

Start   Label byte

BUF_ @TBUF,256          ;  256
BUF_ @TIB,256+16        ;  256
BUF_ @R_BTM,16+512      ;  512 B FSTACK
BUF_ @S_BTM,16+512      ;  512 B DSTACK
BUF_ @MACADR,4096/2+512-64       ; 4096 B = 4 BUFFERS * 1024 B
BUF_ @VOCTOP,4096       ; 4096 B = 4 BUFFERS * 1024 B

        org 100h
;_START:
  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
P_ _ABORT
  MOV   DSP,@S_BTM+512
P_ _QUIT
  MOV     RSP,@R_BTM+512
  CLD
  CALL    @DBG
  CALL    @RET
  DW    _INIT,_INIT  
@MAINLP DW _TIB,_TBL
_@_ACCEPT  DW _NOP,_EVAL
_@_OK  DW _NOP,_JUMP,@MAINLP

;-------------- VARIABLES ----------------

L_ _WFND          ;_STREQU
  DW    __PAR
  CALL  @METHOD
  CMP   BX,[DI-4]
  RET

P_ _BK          ; (BK
  CLR   TOP
  INT   16H
  Z?    TOPL
  JE    @@K
  CLR   TOPH
@@K:  
  JMP  @WPUSH

L_ _WSTR
  DW _PUSH,_RLDP,_XR,_POP,_RET ;
L_ _CSTR
  DW _PUSH,_CRLDP,_XR,_POP,_RET ;
L_ _OPER
   DW _WARY,_NUMBER,_@EXEC,_COMP_NUM,_@COMMA

  CONST_  _TBL,80H
  CONST_  _TIB,@TIB
  CONST_  _TBUF,@TIB
  CONST_  _BL,32
  CONST_  _0,0
  CONST_  _1,1
  _BYE    =_1+2
  
L_ _TIZ   ; SET BUFFER OF THE TEXT INTERPRETTER = EVAL
        DW _DUP,to_+_LTIB,_ADD  ;,to_+_ETIB,_RET       
  VALUE_   _ETIB,0
  L_ _LTIBX                  ; |LTIB
        DW _LTIB,_EX
  VALUE_   _LTIB,0
  L_ _TX                  ; |DICT
        DW _T,_EX
  VALUE_   _T,@VOCTOP
  L_ _HX                  ; |HERE
        DW _H,_EX
  VALUE_   _H,0
  VALUE_   _BLK,0
  VECTOR_  _VT,_T

  VAR_     _CNTC,0
  POINT_   _INIT,_@_INI
  POINT_   _FIND,@LPAR
    
L_ _DFLTEMT
  DW _LIT,_BE
  VALUE_    _@E,_BE
    DW _CNTC,_INC,_RET
  _EMIT = _@E+2
  
L_ _DFLTKEY
  DW _LIT,_BK
  VALUE_   _@K,_BK
    DW _RET
  _KEY = _@K+2

; ---------- INIT INTERPRETTER ----------------

L_ _REINIT
  DW  to_+_INIT
_@_INI:  DW  _UPDICT,_TBL,_sEVAL
  DW  to_+_INIT
_@_ABINI  DW _NOP

; ============   INTERPRETTER   ==============

L_ _LPAR              ; [`
   dw TO_+_FIND
@LPAR   DW _XOPER,_VT
L_ _FND          ;_STREQU
  DW    __PAR
  JMPS  @FNDZ
  
; : ITFND TBUF ++
; : TFND T CFND ;
; : TARG: NOP  TARG:!  \ CSP!  \ MAKE COLON ENTRY
; : >, TO LOXEC   `[]OPER  ITFND TBUF -- IF- (. TFND 
;  1+ THEN 1+ ; 

L_ _TARG
  DW _NOP,_TARG2D
L_ _TOCOMP
  DW TO_+_FIND,_XOPER,_ITFND,_TBUF,_DEC,_IFM,_1P,_DROP,_TFND
L_ _2P
  DW _1P
L_ _1P
  DW _PLSX,1
  
L_ _ITFND
  DW _TBUF,_INC
L_ _TFND
  DW _T
L_ _CFND          ;_STREQU
  DW    __PAR
  MOV   CL,5
  ADD   CL,[TOP+4]
@FNDZ:  
  CALL  @METHOD
  repe  cmpsb
  RET
@METHOD:
  POP   DX DI BX
@fnd:
  add   di,cx
  mov   Ax,di
  LEA   di,[bx+4]
  mov   cl,[di]
  jcxz  xfnd?
  INC   CX
  MOV   SI,BX
  CALL  DX
  jNZ   @fnd
  XCHG  BX,AX
  MOV   cL,1
  STC
  ADC   [BX+2],CX
xFND?:
  PUSH  BX CX ; DX == TBUF ADRS
@PARX1:  
  jmp   @parx

L_ _WORD                  
  DW _PARSE,_TBUF
L_  _MAKESTR
  DW    __PAR;3        ; (S!
  POP   DI BX SI
  PUSH  DI
  MOV   cL,BL
  MOV   [DI],CL
  INC   DI
  REP   MOVSB   ; NAME  MOVE
  MOV   PB [DI],'`'
  JMPS  @PARX1

L_ _UPDICT
  DW    _H,_WSTR
L_ _DPUSH                  ; >DICT
  DW    _TX
L_  _MPUSH
  DW    __PAR;3       ; TOP OF DICTIONARY   IN DI
  POP   DI CX SI  ;_@_MPUSH:  
  ADD   SI,CX                ; AFTER NAME ADDRESS
  STD                        ; BACKWARDS
  CMPSB                      ; PREPARE FOR DIRECTION
  REP   MOVSB                ; NAME  MOVE
  CLD
  inc   di
@MPUSH:  
  PUSH  di
  JMPS   @PARX1
  
L_    _TOKEN?              ; TOKEN?
  DW _TOKEN
L_ _N??  
  DW _ZEQ
L_ _??
  DW _ABORT?
  NAM_ "?"
  DW _RET

L_ _ALLERR
  DW _0
L_ _ABORT0?                  ; (A'
  DW _ZEQ
L_ _ABORT?                  ; (A'
  DW _ASTR,_SWAP,_IF,@ABORTX
_@_ERROR DW _NOP,_ABORT

L_ _HENTRY                  ; _HER_E  !!!
  DW _H
_@_H_CHK  DW _NOP
L_ _ENTRY                   ; =:
  DW _0,_TOKEN?,_DC@,_1P,_TX,_MPUSH,_STM
L_ _STM
  DW _2M,_PUSH,_RSTP,_POP
L_ _2M
  DW _PLSX,-2
L_ _DC@
  DW _DUP
L_ _C@
  DW _PUSH,_CRLDP,_RDROPX
  
; : TOKEN? |N??   : TOKEN  BL WORD   ?C@   ;

L_ _MAC                   ; EVAL
  DW _DZ1
L_ _SEVAL                   ; EVAL
  DW _CSTR
L_ _EVAL                   ; EVAL
  DW _TIZ,_SKIP
@EV  DW _FIND
L_ _@Eval
  DW _NOP,_TOKEN,_IF,@EV,_DROPX
L_  _XOPER
  DW _EX,_OPER,_@EXEC,_RET

; -------------- MATH ------------------

L_ _ADD
  DW _PLAVG
@ABORTX  DW _DROPX
  
 ;vvvvvv--------------   IO  ---------------
 
P_ __PAR
  PUSH  AR
  X
  PUSH  TOP
  CLR   CX
P_ _ASM
  JMP   IP

@SCANER:
  POP     AX
  XCHG    AX,TOP
  X   
  POP     CX DI
  X   
  push    cX
  CALL    TOP
  POP     TOP 
  JE      @@1
  MOV     CX,TOP
@@1:    
  INC     CX
  SUB     TOP,CX
  JMP     @RET
  
P_ _BSCAN
  CALL    @SCANER
  REPNE   SCASB
  RET

P_ _WSCAN
  CALL    @SCANER
  REPNE   SCASW
  RET

 P_ _WRITE 
  DW    __PAR
  MOV   AH,40H
  JMPS  @READ

 P_ _READ 
  DW    __PAR
  MOV   AH,3FH
@READ:
  POP   BX CX
  JMPS  @OPEN
  

 P_ _OPEN 
  DW    __PAR
  MOV   AX,3D02H
@OPEN:  
  POP   DX
  INT   21H
  SBB   DX,DX
  PUSH  AX DX
  jmpS  @parx
  
 P_ _INT 
  DW    __PAR
  POP   AX
  MOV   PB @INT,AL
  POP   AX BX  CX  DX
  PUSH  DS ES BP
  INT     21H
@INT = $-1
  POP   BP ES DS 
  PUSH  DX CX BX AX
	PUSHF
  jmpS  @parx

L_ _PARSE
  DW _ETIB,_LTIBX
L_ _PARS                ;= (PARS
  DW __PAR;3          
  POP CX DI AX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   DI
  INC   CX
@@SKIPX:
  MOV   BX,di      ;  START OF THE SOURCE
  JCXZ  @@WEX

  REPNE SCASB
  JNE   @@WEX
  DEC   DI
@@WEX:          ; END OF THE SOURCE  IN DI
  SUB   DI,BX
  PUSH  BX di CX     ; START OF THE SOURCE
@PARX:
  X
  POP   AR
P_ _DROPX               
@DROPX:               ; ( (DROP;
  POP    IP
  JMPS   @DROP
@DBG:   RET 

P_ __SETVAR
  MOV   [IP+2],top
  JMPS  @DROPX

 P_ _RDROPX
  POP W
  SKIPA
P_ _PLSX
  ADD  TOP,[IP]
  JMPS   @RET
               
P_ _CLOSE
  MOV   AH,3EH
  INT     21H
  JMPS   @DROP
                
P_ __setpnt
  POP   [IP+2]
  SKIPA
P_ _ANDX
  AND  TOP,[IP]
  JMPS   @RET
                
P_ _PUSHX            ; (PUSH;
  PUSH	TOP
  JMPS   @DROPX
		
P_ _ALPHA
  MOV   W,127
  AND   W,TOP
	CMP		WL,10
	JB		@ALP
	ADD		WL,7
@ALP:    
	ADD		WL,'0'
@SWAPREG:  
  XCHG  W,TOP
  JMPS   @NOP

P_ _QARY 
  SHL     TOP,1
P_ _LARY    
  SHL     TOP,1
P_ _WARY 
  SHL     TOP,1
P_ _BARY
  LEA     TOP,[TOP+IP]
P_ _RET               ;  (;
@RET:
  POP     IP
  JMPS   @NOP
 
 P_ _CRSTP		       ; (C!R+
    POP     WA
    XCHG    TOP,W
    STOSB
    PUSH    WA
    JMPS   @DROP       
        
 P_ _RSTP              ; (!R+
    POP     WA
    XCHG    TOP,W
    STOSW
    PUSH    WA
    JMPS   @DROP  
		    
 p_ _BE		           ; (BE
		XCHG    AX,TOP
    MOV     AH,0EH
    INT     10H
@DROP:          
    MOV   TOP,[DSP]       
PP_ _NIP,@NIP
    NIP_
    N_

P_ _XOR
  XOR   TOP,[DSP]
  JMPS  @NIP
  
 P_ _INC                   ; ++
		INC   PW [TOP]
    JMPS   @DROP
		
 P_ _DEC                   ; ++
		DEC   PW [TOP]
    JMPS   @DROP
		
 P_ _AST                   ; A!
		MOV		AR,TOP
 P_ _DROP              ; (DROP
    JMPS   @DROP
		
 P_ _FOR				; (FOR
    MOV     IP,[IP]
 P_ _PUSH		       ; (PUSH
    PUSH    TOP
    JMPS   @DROP

 P_ _CSEG
    PUSH    CS
    SKIPB
 P_ _SPLD
    PUSH    DSP
    SKIPB
 P_ _RPLD
    PUSH    RSP
    SKIPB
 P_ _ALD
    PUSH    AR
    SKIPB
 P_ _DUP           ; ( DUP
    PUSH    TOP
@RPOP:  POP     W
@WPUSH: DUP_    TOP
    MOV     TOP,W 
    SKIPA
@NEST:  
    XCHG    IP,W
@RPUSH:
    PUSH    W
 P_ _NOP        
@NOP:
   LODSW
_@_DBG:
    TEST    WL,1
    JZ      @NEST
    DEC     W
    JMP     W
    
P_ _@EXEC
  MOV   TOP,[TOP]
P_ _EXEC
  XCHG  W,TOP
  DROP_
  JMPS  _@_DBG   
        
P_ __VAR
  XCHG  W,IP
  SKIPB
P_ __CONS
  LODSW
  POP   IP
  JMPS  @WPUSH
  
P_ _OVER
  MOV     W,[DSP]
  SKIPB
P_ _LIT
  LODSW
  JMPS    @WPUSH
		
 P_ _ASTR            ; ("SKIP  "
		POP		WA
    MOV   w,[WA]
    mov   wh,0
    ADD     w,WA
    OR      wl,1        ; MAKE CNT ODD
    XCHG    w,WA
    JMPS   @WPUSH1
		
;-------------------------------------------
; CONTROL
;-------------------------------------------

 P_ _NEXT        ; (NEXT
    POP     W
    DEC     W
    PUSH    W
    INC     W
    JE      @RDROPSK
P_ _JUMP              ; (JUMP
P_ __POINT   
P_ __DEFER
@JUMP:
    MOV     IP,[IP]
    N_
@RDROPSK:    
    LODSW
@RDROP:
   POP     W
   JMPS   @NOP
P_ _RDROP      ; RDROP
   JMPS   @RDROP
	
P_ _IFM	         ; (IF-
  JMPS   @IFM2
       
P_ _MIF	
   INC     TOP        
@IFM2:
    DEC     TOP        
    JNS      @JUMP		
 P_ _SKIP		        ; (SKIP
    jmpS   @SKIP
    
 P_ _IF          ; (IF
    Z?     TOP
		DROP_
    JZ      @JUMP		
@SKIP:
    LODSW
    N_
		
 P_ _RLDP              ; (@R+
    POP     WA
    MOV     w,[WA]
    INC     WA
    JMPS   @WPUSH1
        
 P_ _CRLDP                 ; ( C@R+
	POP		WA
    MOV   w,[WA]
    mov   wh,0
@WPUSH1:        
    INC     WA
    JMPS   @_J
        
 P_ _J               ; ( J
    POP     WA
    POP     W
    PUSH    W
@_J:
    PUSH    WA      
    jMPS   @WPUSH

 P_ _POP
    JMPS   @RPOP    ; ( POP
 P_ _EX              ; ( EX
    POP     W
    JMPS   @NEST        
 P_ _XR             ; ( XR  XCHG
    POP     W
    XCHG    TOP,W
    JMPS   @RPUSH        
 P_ _XA            ; ( XA
    POP     W
    XCHG    W,AR
    JMPS   @RPUSH
    
 P_ _PLAVG				; ( +2/
    ADD     TOP,[DSP]
    MOV     [DSP],TOP       
 P_ _2DIV               ; ( 2/
@2DIV:  RCR     TOP,1
@NOP2:  JMPS   @NOP
		
 P_ _SDIV          ; ( -/
    SHL     PW [DSP],1
    RCL     TOP,1
    CMP     TOP,AR
    JB      @NOP2
    SUB     TOP,AR        
		INC     PW [DSP]
    JMPS   @NOP2
		
 P_ _PMUL          ; ( +*
    TEST    PB [DSP],1
    JNZ     @D2DIV
    ADD     TOP,AR
 P_ _D2DIV
@D2DIV: RCR     TOP,1
    RCR     PW [DSP],1
    JMPS   @NOP2
		
 P_ _nAND	          ; ( AND
    AND     TOP,[DSP]
    NIP_
 P_ _NOT
    INC     TOP
 P_ _NEG
    NEG     TOP
    JMPS   @NOP2
 P_ _ZEQ
    NEG     TOP
    cmc
    SKIPR   W
P_ _0LESS
    SHL     TOP,1
@FLAG: 
    SBB     TOP,TOP
    JMPS   @NOP2
        
 P_ _MROT
		XCHG	TOP,[DSP+2]
 P_ _SWAP
		XCHG	TOP,[DSP]
    JMPS   @NOP2

; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

IF 01

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
ENDIF

    ALIGN_ 0

 _NUMBER :
 _DZ1    :
 _TOKEN  :
_COMP_NUM:
_@COMMA:
_TARG2D:

MyCseg  ends
        end  Start

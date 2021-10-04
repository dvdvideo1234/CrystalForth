MAX = 1
DBG = 0

INCLUDE C4F.IMC

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

MADR = 65535-15 ;

Start   Label byte

BUF_ @TIB,114        ;  130
BUF_ _@FIB,130        ; 130
BUF_ @TBUF,258       ;  256
BUF_ _@R_TOP,10      ;  512 B FSTACK
BUF_ _@R_BTM,512     ;  512 B FSTACK
BUF_ _@S_TOP,16      ;  512 B DSTACK
BUF_ _@S_BTM,512     ;  512 B DSTACK
BUF_ _@MACTOP,16     ; 4096 B = 4 BUFFERS * 1024 B
BUF_ _@MACADR,2000   ; 4096 B = 4 BUFFERS * 1024 B
BUF_ @VOCTOP,4096    ; 4096 B = 4 BUFFERS * 1024 B

        org 100h

  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
@ABORT:
  CALL    @RET
  DW    _INIT
L_ _QUIT
@MAINLP DW _TIB,_TBL
_@_ACCEPT  DW _NOP,_EVAL
_@_OK  DW _NOP,_JUMP,@MAINLP

P_ _ABORT
  JMPS @ABORT

;-------------- VARIABLES ----------------

L_ _OPER
   DW _WARY
_@NUMBER  DW 0
    DW _@EXEC
_@COMPNUM DW 0
   DW _@COMMA,0,0   ;  FOR COMMENT

  CONST_  _TBL,80H
  CONST_  _TIB,@TIB
  CONST_  _TBUF,@TBUF
  CONST_  _FIRST,@VOCTOP
  CONST_  _BL,32
  CONST_  _0,0
  
;L_ _TIZ   ; SET BUFFER OF THE TEXT INTERPRETTER = EVAL
;        DW _DUP,to_+_LTIB,_ADD  ;,to_+_ETIB,_RET       
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
;  VALUE_   _BLK,0   ;  : MCLR $D800 ,<     0 VALUE MOBJ   
;L_ MCLR
;  DW _LIT,_@MACADR 
;  VALUE_   _MOBJ,_@MACADR
  VECTOR_  _VT,_T

;  VAR_     _CNTC,0
  POINT_   _INIT,_@_INI
  DW __VAR3
  POINT_   _FIND,@LPAR
    
;L_ _DFLTEMT
;  DW _LIT,_BE
;  VALUE_    @E,_BE
;    DW _CNTC,_INC,_RET
;  _EMIT = @E+2
;  
;L_ _DFLTKEY
;  DW _LIT,_BK
;  VALUE_   @K1,_BK
;    DW _RET
;  _KEY = @K1+2
;
; ---------- INIT INTERPRETTER ----------------

LL_ _REINIT,to_+_INIT
_@_INI:   DW  _CLRSTK,_UPDICT,_TBL,_POSTX,_sEVAL
LL_ _REINIT2,to_+_INIT
_@_ABINI  DW _NOP,_SKIP

; ============   INTERPRETTER   ==============

L_ _SEMICO
_@SEMICO DW _NOP
LL_ _LPAR,TO_+_FIND             ; [`
@LPAR DW _XOPER,_VT,_FND,_RET         

; ============== COMPILER ===================

L_ _COLON             ; :
  DW _NOP
L_ _COLONC             ; :`
  DW _HENTRY
LL_ _RPAR,TO_+_FIND
  DW _XOPER,_IFND,_TBUF,_DEC,_IFM,@RPAR,_DROP,_CFND,_1P
@RPAR DW _1P,_RET

L_ _TO_NAME
  DW _4P,_CSTR,_ADD,_RET
L_ _IFND
  DW _TBUF,_INC
L_ _CFND
  DW _T,_TO_NAME
LL_ _FND,__PAR         
  CALL  @METHOD
  repe  cmpsb
  RET
@METHOD:
  POP   DX DI AX
@fnd:
  add   di,cx
  mov   Bx,di
  LEA   di,[DI+4]
  mov   cl,[di]
  jcxz  xfnd?
  INC   CX
  MOV   SI,AX
  CALL  DX
  jNZ   @fnd
  MOV   cL,1
  STC
  ADC   [BX+2],CX
  XCHG  BX,AX
xFND?:
  PUSH  AX CX 
@PARX1:  
  jmp   @parx

L_ _WORD                  
  DW _PARSE,_TBUF
LL_  _MAKESTR,__PAR       ; (S!
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
LL_ _DPUSH,_TX                  ; >DICT
LL_ _MPUSH,__PAR    ; TOP OF DICTIONARY   IN DI
  POP   DI CX SI     ;_@_MPUSH:  
  ADD   SI,CX                ; AFTER NAME ADDRESS
  STD                        ; BACKWARDS
  CMPSB                      ; PREPARE FOR DIRECTION
  REP   MOVSB                ; NAME  MOVE
  CLD
  inc   di
@MPUSH:  
  PUSH  di
  JMPS   @PARX1
  
LL_ _TOKEN?,_TOKEN
LL_ _N??,_ZEQ
LL_ _??,_ABORT?
  NAM_ "?"
  DW _RET

L_ _ALLERR
  DW _0
L_ _ABORT0?                  ; (A'
  DW _ZEQ
L_ _ABORT?                  ; (A'
  DW _ASTR,_SWAP,_0X,_CLRSTK
_@_ERROR DW _NOP,_ABORT

LL_ _MAC,_DZ0               ; _MAC
LL_ _SEVAL,_CSTR            ; EVAL
L_ _EVAL                   ; EVAL
_@TIZ  DW _NOP,_SKIP
@EV  DW _FIND
L_ _@Eval
  DW _NOP,_TOKEN,_IF,@EV,_DROPX
  
; -------------- MATH ------------------

LL_ _RANGES,_1P
LL_ _OVERM,_OVER
LL_ _SUB,_NEG
LL_ _ADD,_PLAVG
  DW _DROPX
 
;L_ _DZ1
;  DW _POP,_XR,_RET

;L_ _MAKER
;  DW _DZ0,_hentry,_SKIP
;L_ _COMMAER
;  DW _DZ0,_WSTR,_comma,_@EXEC,_RET
;
;L_ _SEMICO
; DW _COMMAER,_RET,_LPAR  ; ;`
;
LL_ _@COMMA,_LD
LL_ _COMMA,_HX
L_ _STP
  DW  _PUSH,_RSTP,_POPX

LL_ _XOPER,_EX
  DW _OPER
L_ _@EXEC
  DW _LD,_EXEC,_RET

L_ _POSTENT                 ; ==:   \ N:  OR =,
  DW _DUP 
  DW _POSTX,_COMMA
L_ _HENTRY                  ; _HER_E  !!!
_@HERE   DW _H
L_ _ENTRY                   ; =:
  DW _0,_TOKEN?
L_ _ENTRYZ                   ; (=:
_@SAME  DW _NOP
  DW _DC@,_1P,_TX,_MPUSH,_STM
L_ _STM
  DW _2M,_PUSH,_IST,_POPX
LL_ _IST,_J
L_ _ST 
  DW _PUSH,_POPSTX ; 
LL_ _CIST,_J
L_ CST 
  DW _PUSH,_CRLDP
L_  _EXIT
  DW _RDROPX ; 
  
L_ _TOKEN                  
  DW _Bl,_WORD
L_ _DC@
  DW _DUP,__ARET
P_ _C@
  MOV   TOPH,[TOP]
P_ _HW_B
  MOV   TOPL,TOPH
P_ _W_B
  CLR   TOPH
  JMPS  @NOP3

  ;vvvvvv--------------   IO  ---------------
 
;L_ _UMUL
;  DW __ADROPX
;  MUL   TOP
;  XCHG  W,TOP
;  JMP   @NOP



;P_ _ALPHA
;  MOV   W,127
;  AND   W,TOP
;	CMP		WL,10
;	JB		@ALP
;	ADD		WL,7
;@ALP:    
;	ADD		WL,'0'
;@SWAPREG:  
;  XCHG  W,TOP
;  JMPS   @NOP3


P_ _4P
  INC     TOP
  INC     TOP
P_ _2P
  INC     TOP
@1P:
  INC     TOP
  JMPS    @NOP3
P_ _1P
  JMPS    @1P
P_ _2M
  DEC     TOP
@1M:
  DEC     TOP
  JMPS    @NOP3
P_ _1M
  JMPS    @1M
  
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
  JMPS   @RET
 
P_ __SCANER
  X   
  PUSH    TOP
  POP     DX CX DI
  X   
  XCHG    AX,TOP
  push    cX
  CALL    IP
  POP     TOP 
  JE      @@1
  MOV     CX,TOP
@@1:    
  INC     CX
  SUB     TOP,CX 
P_ _RET
@RET:
  POP     IP
@NOP3:  
  JMP     @NOP
  
P_ _CALL_IP
  CALL    IP
  JMPS    @RET
  
 P_ _RDROPX
  POP W
  SKIPA
P_ _PLSX
  ADD  TOP,[IP]
  JMPS   @RET
               
P_ __setpnt
  POP   [IP+2]
  SKIPA
P_ _ANDX
  AND  TOP,[IP]
  JMPS   @RET
     
L_ _WRITE 
  DW    __PAR
  MOV   AH,40H
  JMPS  @READ

L_ _READ 
  DW    __PAR
  MOV   AH,3FH
@READ:
  POP   BX CX
  JMPS  @OPEN

L_ _OPEN 
  DW    __PAR
  MOV   AX,3D02H
@OPEN:  
  POP   DX
  INT   21H
  SBB   DX,DX
  PUSH  AX DX
  jmpS  @parx
  
P_ _CLOSE
  MOV   AH,3EH
  INT     21H
  JMPS   @DROP        

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
_@PARSE  DW _NOP,_ETIB,_LTIBX
L_ _PARS                ;= (PARS
  DW __PAR          
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
  JMPS   @DROPX

P_ _DEC                   ; ++
	DEC   PW [TOP]
  JMPS   @DROP
	
P_ _AST                   ; A!
	MOV		AR,TOP
P_ _DROP              ; (DROP
  JMPS   @DROP
	
P_ _POPSTX
  POP   IP
  SKIPB
P_ __SETVAR
  LODSW
  MOV   [IP],top
  SKIPB  ;  JMPS  @DROPX
P_ _PUSHX            ; (PUSH;
  PUSH	TOP
@DROPX:               ; ( (DROP;
  POP    IP
  JMPS   @DROP
		
P_ _0X
  Z?      TOP
  JE      @DROPX
  JMPS   @DROP
  
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
		    
P_ _CSTR
  MOV   WL,[TOP]
  INC   TOP
  JMPS  @K0

p_ _BE		           ; (BE
	XCHG    AX,TOP
  MOV     AH,0EH
  INT     10H
  SKIPA
P_ _INC                   ; ++
	INC   PW [TOP]	
  JMPS   @DROP
P_ _FOR				; (FOR
  MOV     IP,[IP]
P_ _PUSH		       ; (PUSH
  PUSH    TOP
@DROP:  
  X
  R_TO    TOP
  JMPS    @SWPSTK
  
P_ _PMUL          ; ( +*
  TEST    PB [DSP],1
  JNZ     @D2DIV
  ADD     TOP,AR
PP_ _D2DIV,@D2DIV
  RCR     TOP,1
  RCR     PW [DSP],1
  N_
		
L_ _nAND	          ; ( AND
  DW __ADROPX
    AND     TOP,W
P_ _NOT
    INC     TOP
P_ _NEG
    NEG     TOP
    N_
    
P_ _ZEQ
    NEG     TOP
    cmc
    SKIPR   W
P_ _0LESS
    SHL     TOP,1
PP_ _ZERO,@FLAG
    SBB     TOP,TOP
    N_
    
P_ __VAR3
  LODSW
  LODSW
P_ __VAR
  XCHG      W,IP
  SKIPB
P_ _POPX
  POP       W
  SKIPB
P_ __cons
  LODSW
  POP   IP
  JMPS  @WPUSH
  
P_ _WSTR
  MOV   W,[TOP]
  INC   TOP
  INC   TOP
  JMPS  @WPUSH

P_ _BK          ; (BK
  CLR   W
  INT   16H
  Z?    WL
  JE    @K
@K0:  
  CLR   WH
@K:  
  JMPS  @WPUSH

  DW _RLDP,_RLDP
L_ _WITHIN
  DW _OVERM,_PUSH,_SUB,_POP 
L_ _ULESS
  DW __ADROPX
  SUB   W,TOP
  JMPS  @FLAG

P_ _PLAVG				; ( +2/
  ADD     TOP,[DSP]
  MOV     [DSP],TOP       
PP_ _2DIV,@2DIV               ; ( 2/
  RCR     TOP,1
  N_
		
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
  JMPS    @RPOP
  
P_ _OVER
  MOV     W,[DSP]
  SKIPB
P_ _LIT
  LODSW
  SKIPA
P_ _DUP           ; ( DUP
  MOV     W,TOP
  JMPS  @WPUSH
  
P_ _DZ2
  POP     W
  INC     W
  INC     W
  SKIPB
P_ _DZ1
  POP     W
  INC     W
  INC     W
  SKIPB
P_ _DZ0
P_ _POP
@RPOP:
  POP     W
PP_ __,@WPUSH
  XCHG    TOP,W 
  X
  TO_R    W
@SWPSTK:
  X
PP_ _NOP,@NOP
  LODSW
_@_DBG:
  TEST    WL,1        ; A8 01
  ;JMPS    @JDBG
@DBG2:
  JZ      @NEST
  DEC     W
  JMP     W
    
P_ _POSTX              ; (|
  LODSW
  SKIPA
P_ _EX              ; ( EX
  POP     W
@NEST:  
  XCHG    IP,W
@RPUSH:
  PUSH    W
  N_

  IF DBG
@JDBG: JMP  @BPDBG
  ELSE 
@JDBG: JMP  @ABORT
  ENDIF
  
;-------------------------------------------
; CONTROL
;-------------------------------------------

@RDROPSK:    
  LODSW
PP_ _RDROP,@RDROP      ; RDROP
  POP     W
  N_
@SKIP:		        ; (SKIP
  LODSW
  N_

P_ _NEXT        ; (NEXT
  POP     W
  DEC     W
  PUSH    W
  INC     W
  JNE     @JUMP
P_ _RDROPSK
  JMPS    @RDROPSK
    
P_ _JJM
  MOV     IP,[IP]
P_ _JM
  POP   W WA
  DEC   WA
  PUSH  WA
  JMPS  @RPUSH
  
P_ _MIF	
  INC     TOP        
@IFM2:
  DEC     TOP        
  JS      @SKIP
P_ __POINT   
P_ __defer
P_ _JUMP              ; (JUMP
@JUMP:
  MOV     IP,[IP]
  N_
	
P_ _IFM	         ; (IF-
  JMPS   @IFM2
       
L_ _OF
  DW _OVER,_XOR
LL_ _IF,__ADROPX
  Z?      W
  JZ      @JUMP		
P_ _SKIP
  jmpS    @SKIP
		
P_ _XR             ; ( XR  XCHG
  POP     W
  XCHG    TOP,W
  JMPS    @RPUSH        

P_ _XA            ; ( XA
  POP     W
  XCHG    W,AR
  JMPS    @RPUSH

P_ _XOR
  XOR   TOP,[DSP]       
PP_ _NIP,@NIP
  NIP_
  N_

P_ _MROT
  XCHG	TOP,[DSP+2]
P_ _SWAP
	XCHG	TOP,[DSP]
  SKIPA
P_ _LD
  MOV   TOP,[TOP]
  N_
  
LL_ _EXEC,__ADROPX    ;  TEST    WL,1    ; SKIP JMP TO DBG
  JMPS  _@_DBG
        
P_ _RLDP              ; (@R+
  POP     WA
  MOV     w,[WA]
  INC     WA
@WPUSH1:        
  INC     WA
@_J:
  PUSH    WA      
  jMPS    @WPUSH
        
P_ _ASTR            ; ("SKIP  "
  POP		WA
  MOV   w,[WA]
  mov   wh,0
  ADD     w,WA
  OR      wl,1        ; MAKE CNT ODD
  XCHG    w,WA
  JMPS   @WPUSH1
		
 P_ _CRLDP                 ; ( C@R+
	POP		  WA
  MOV     w,[WA]
  mov     wh,0
  JMPS    @WPUSH1
@DBG:  
  RET

P_ _J               ; ( J
  POP     WA
  POP     W
  PUSH    W
  JMPS    @_J
       
; -----------  ADDRESS INDEPENDANT CODE -------------

P_ _SDIV          ; ( -/
  SHL     PW [DSP],1
  RCL     TOP,1
  CMP     TOP,AR
  JB      @NOP4
  SUB     TOP,AR     
P_ _U1P  
  INC     PW [DSP]
@NOP4:
  JMP     @NOP
		
    
P_ _2MUL               ; ( 2*
  SHL     TOP,1
  JMPS    @NOP4
  
L_ _B? 
  DW _PUSH 
L_ _BSCN
  DW _XR,_CSTR,_POP
L_ _BSCAN
  DW      __SCANER
  REPNE   SCASB
  RET

L_ _WSCAN
  DW      __SCANER
  REPNE   SCASW
  RET

L_ _BSCANE
  DW      __SCANER
  REPE    SCASB
  RET

L_ _WSCANE
  DW      __SCANER
  REPE    SCASW
  RET

LL_ _WFND,__PAR          ;_STREQU
  CALL  @METHOD
  CMP   SI,[DI-4]
  RET

P_ __ADROPX
  XCHG  W,TOP
  D_TO  top
P_ __ARET
  POP   WA
  XCHG  WA,IP
  JMP   WA
  
P_ __PAR
  PUSH  AR
  X
  PUSH  TOP
  CLR   CX
P_ __ASM
  INT   3
  JMP   IP

P_ _CLRSTK
  MOV   DSP,_@S_TOP
  
  IF DBG
    CALL    @DBG_OFF
  ELSE
    CALL    @DBG
  ENDIF
  
  MOV     RSP,_@R_TOP
  ALIGN_ 1
  SKIPB
  
P_ _BP    
    INT 3
  JMP     @NOP
  
; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

IF DBG

LL_ _TROFF,_CALL_IP
@DBG_OFF:
  MOV     DI,1ABH
@DBG_:  
  XCHG    DI,PW _@_DBG
  RET
  
LL_ _TRON,_CALL_IP
@DBG_ON:
  SKIPR   DI      ;  EB 0C	
  DB      0EBH,@JDBG-@DBG2
  JMPS    @DBG_

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

@ACR:
  MOV AL,13
  CALL  @PC
  MOV   AL,10
  JMPS @PC
  
@ROT3:
	CALL	@PSPC
  D_TO  TOP
  CALL  @ROT1
  CALL  @ROT1
@ROT1:
  XCHG  [DSP],TOP
  XCHG  [DSP+2],TOP
  MOV   AX,TOP
@PHEX:  CALL	@PAX	
@PSPC:	MOV		AL,' '
	JMPS	@PC

@BPDBG:
  CALL  @DBG_OFF
  MOV   CX,RSP
  MOV   DI,[SI]
  PUSH  AX IP DI CX DSP AR
  X
  PUSH  TOP
  CALL  @ACR
	CALL	@ROT3
  ADD   DSP,4
	CALL	@ROT3
  X
  POP   DI CX
	CALL	@ROT3
  CLR   AX
  INT   16H
  AND   AL,0DFH
  CMP   AL,'S'
  JE    @DBHE
  CALL    @DBG_ON
@DBHE:
  XCHG  AX,CX
  TEST  AL,1
  JMP   @DBG2
   
ENDIF

    ALIGN_ 0
  
  
;freemem:
;  DW ENDMEM-FREEMEM-2
;;INCLUDE NF9_1.IC1
;  ENTRY_  _ENTRY,'=:'
;  ENTRY_  0,''
;EndMem:

MyCseg  ends
        end  Start

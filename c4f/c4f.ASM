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
BUF_ _@MACADR,2512   ; 4096 B = 4 BUFFERS * 1024 B
BUF_ @VOCTOP,4096    ; 4096 B = 4 BUFFERS * 1024 B

        org 100h

  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  MOV   AX,3
  INT   10H
P_ _ABORT
  MOV   DSP,_@S_TOP
  CALL    @DBG_OFF
;  CALL    @DBG_ON
P_ _QUIT
  MOV     RSP,_@R_TOP
  CALL  @RET
  DW    _INIT
@MAINLP DW _TIB,_TBL
_@_ACCEPT  DW _NOP,_EVAL
_@_OK  DW _NOP,_JUMP,@MAINLP

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
;  CONST_  _BL,32
  CONST_  _0,0
  
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
  
  VECTOR_  _VT,_T
  VECTOR_  _VDBG,_NOOP
  VECTOR_  _VPIN,_NOOP

  POINT_   _INIT,_@_INI
  
  DW __VAR3
  POINT_   _FIND,@LPAR
    
; ---------- INIT INTERPRETTER ----------------

LL_ _REINIT,to_+_INIT
_@_INI:
   DW  _UPDICT
   DW  _DLIT,8*1024,22*1024,_POSTX,_EVAL
   ;DW  _DLIT,8*1024,0,_POSTX,_EVAL
LL_ _REINIT2,to_+_INIT
_@_ABINI  DW _NOP,_SKIP

; ============   INTERPRETTER   ==============

L_ _SEMICO
_@SEMICO DW _NOP  ;  DW _TRON
LL_ _LPAR,TO_+_FIND             ; [`
@LPAR DW _VT,_FND,_RET         

LL_ _MAC,_DZ0               ; _MAC
;      DW AT_+ _FIND
;  DW _SKIP,_RPAR+2      ; FIX SKIP WITH |SAVE!
LL_ _SEVAL,_CSTR            ; EVAL
L_ _EVAL                   ; EVAL
;  DW _TRONM?
_@TIZ  DW _NOP          ; FIX WITH TI
L_ _@Eval
@EV  DW _NOP,_TOKEN,_IF,_EVALX,_FIND  ; FIX WITH STK?
_@OPER  DW _NOP,_OPER,_@EXEC,_JUMP,@EV

LL_ _XDROP,_EX
LL_ _EVALX,_DROPX

; ============== COMPILER ===================

L_ _COLON             ; :
  DW _NOP
L_ _COLONC             ; :`
  DW _HENTRY
LL_ _RPAR,TO_+_FIND
  DW _TBUF,_INC,_CFND,_TBUF,_DEC,_SKIP?,_RET,_CFND,_2P
LL_ _NOOP,_RET

L_ _CFND
  DW _NOP
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
  DW _PARSE,_TBUF         ;  DW _VDBG,2
LL_  _MAKESTR,__PAR       ; (S!
  POP   DI AX SI
  PUSH  DI
  MOV   cL,AL
;  MOV   [DI],CL
;  INC   DI
  STOSB
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

L_ _ABORT0?                  ; (A'
  DW _ZEQ
L_ _ABORT?                  ; (A'
  DW _ASTR,_PUSH  
  DW _IF,_ABORTX
L_ _ALLERR
  DW _POP
_@_ERR DW _NOP,_ABORT
L_ _N0X
  DW _0X
_ABORTX DW _RDROPX

; -------------- MATH ------------------

L_ _DLIT
  DW _RLDP
L_ _LIT
  DW _RLDP,_RET
  
LL_ _@COMMA,_LD
LL_ _COMMA,_HX
L_ _STP
  DW  _PUSH,_RSTP,_POPX

L_ _POSTENT                 ; ==:   \ N:  OR =,
  DW _DUP 
  DW _POSTX,_COMMA
L_ _HENTRY                  ; H=:  _HER_E  !!!
_@HERE   DW _H
L_ _ENTRY                   ; =:
  DW _0,_TOKEN?
;  DW _VDBG,3
L_ _ENTRYZ                   ; (=:
_@SAME  DW _NOP
  DW _DC@,_1P,_TX,_MPUSH,_STM
L_ _STM
  DW _2M,_PUSH,_IST,_POPX
LL_ _IST,_J
L_ _ST 
  DW _PUSH,_POPSTX ; 
  
L_ _TOKEN                  
  DW _LIT,32,_WORD
L_ _DC@
  DW _DUP,__ARET
P_ _C@
  MOV   TOPH,[TOP]
P_ _HW_B
  MOV   TOPL,TOPH
P_ _W_B
  CLR   TOPH
  JMPS  @NOP3

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
 ; INT 3           ; !!!!
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
     
  ;vvvvvv--------------   IO  ---------------
 
LL_ _INT,__PAR
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
;  DW _VDBG,1
L_ _PARS                ;= (PARS
  DW __PAR          
  POP CX DI AX
  SUB   DI,CX
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

P_ _NEQ    
P_ _XOR
  XOR     TOP,[DSP]       
  JMPS    @NIP

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
  MOV     TOP,[DSP]
PP_ _NIP,@NIP  
  INC     DSP
  INC     DSP
  N_
  
L_ _nAND	          ; ( AND
  DW __ADROPX
    AND     TOP,W
P_ _NOT
    INC     TOP
P_ _NEG
    NEG     TOP
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

P_ _PLAVG				; ( +2/
  ADD     TOP,[DSP]
  MOV     [DSP],TOP       
PP_ _2DIV,@2DIV               ; ( 2/
  RCR     TOP,1
  N_
		
  
P_ _CSEG
  PUSH    CS
  SKIPB
P_ _OVER
  PUSH    [DSP]
  SKIPB
P_ _SPLD
  PUSH    DSP
  SKIPB
P_ _RPLD
  PUSH    RSP
  SKIPB
P_ _DUP           ; ( DUP
  PUSH    TOP
P_ _DZ0
P_ _POP
  JMPS  @RPOP
  
P_ _DZ2
  POP     W
  INC     W
  INC     W
  SKIPB
P_ _DZ1
  POP     W
  INC     W
  INC     W
  SKIPA
P_ _ALD
  PUSH    AR
@RPOP:
  POP     W
  jMPS    @WPUSH
  
P_ _RLDP              ; (@R+
  POP     WA
  MOV     w,[WA]
  INC     WA
@WPUSH1:        
  INC     WA
@_J:
  PUSH    WA      
        
PP_ @_,@WPUSH
  XCHG    TOP,W 
  X
  TO_R    W
@SWPSTK:
  X
PP_ _NOP,@NOP
  LODSW
_@_DBG:
  TEST    WL,1        ; A8 01
  ;JMPS    _@JDBG
@DBG2:
  JZ      @NEST
  DEC     W
  JMP     W
    
P_ _POSTX              ; (|
  LODSW
  SKIPA
PP_ _EX,@EX              ; ( EX
  POP     W
@NEST:  
  XCHG    IP,W
@RPUSH:
  PUSH    W
  N_

_@JDBG: JMP  @BPDBG

;-------------------------------------------
; CONTROL
;-------------------------------------------

P_ _IFM	         ; (IF-       
  JMPS    @IFM
  
P_ _NEXT        ; (NEXT
  POP     W
  DEC     W
  PUSH    W
  SKIPR   W
  
P_ _MIF	         ; (-IF       
  INC     TOP        
@IFM:  
  DEC     TOP        
  JNS     @JUMP
P_ _SKIP
@SKIP:		        ; (SKIP
  LODSW
  N_

P_ _SKIP?
  Z?      TOP
  JZ      @IF1
  N_
  
P_ _IF
  INC     TOP
@IF1:
  DEC     TOP
  CALL    @ADROP
@IFZ:
  JNZ     @SKIP	
	
P_ __POINT   
P_ __defer
P_ _JUMP              ; (JUMP
@JUMP:
  MOV     IP,[IP]
  N_
		
P_ _RDROP      ; RDROP
  POP     W
  SKIPB
P_ _BP    
    INT 3
  SKIPA
P_ _LD
  MOV   TOP,[TOP]
  N_
  
P_ _XR             ; ( XR  XCHG
  POP     W
  XCHG    TOP,W
  JMPS    @RPUSH        

P_ _XA            ; ( XA
  POP     W
  XCHG    W,AR
  JMPS    @RPUSH

L_ _@EXEC
  DW _LD
LL_ _EXEC,__ADROPX    ;  TEST    WL,1    ; SKIP JMP TO DBG
  JMPS  _@_DBG
        
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

L_ _ULESS
  DW __ADROPX
  SUB   TOP,W
  JMPS  @FLAG

P_ _ZEQ
    NEG     TOP
    cmc
    SKIPR   W
P_ _0LESS
    SHL     TOP,1
PP_ _ZERO,@FLAG
    SBB     TOP,TOP
    JMPS    @NOP4
    
; -----------  ADDRESS INDEPENDANT CODE -------------

P_ _PMUL          ; ( +*
  TEST    PB [DSP],1
  JZ      @D2DIV
  ADD     TOP,AR
PP_ _D2DIV,@D2DIV
  RCR     TOP,1
  RCR     PW [DSP],1
  JMP     @NOP
		
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
		
P_ _MROT
  XCHG	TOP,[DSP+2]
P_ _SWAP
	XCHG	TOP,[DSP]
  SKIPA
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

L_ _WSCN
  DW _XR,_WSTR,_POP
L_ _WSCAN
  DW      __SCANER
  REPNE   SCASW
  RET

P_ __ADROPX
  CALL  @ADROP
P_ __ARET
  POP   WA
  XCHG  WA,IP
  JMP   WA
@ADROP:
  XCHG  W,TOP
  D_TO  top
  RET
  
P_ __PAR
  PUSH  AR
  X
  PUSH  TOP
  CLR   CX
P_ __ASM
  JMP   IP

; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

LL_ _WFIND,_T
LL_ _WFND,__PAR          ;_STREQU
  CALL  @METHOD
  CMP   SI,[DI-4]
  RET

  ALIGN_ 0
  DW _EX
LL_ _TROFF,_CALL_IP
@DBG_OFF:
  SKIPR   DI 
  TEST    WL,1
@DBG_:  
  XCHG    DI,PW _@_DBG
  RET
  
P_ _TROFF?
  CALL    @DBG_OFF
  CMP     WA,12345
  org     $-2
  TEST    WL,1
  JMP     @IFZ
  
L_ _TRONM?
  DW _TROFF?,_NOOP
  DW _EX
LL_ _TRON,_CALL_IP
@DBG_ON:
  SKIPR   DI      ;  EB 0C	
  DB      0EBH,_@JDBG-@DBG2
  JMPS    @DBG_

    ;ALIGN_ 0
@BPDBG:
  PUSH    AX
  CALL    @DBG_OFF
  CALL    @EX
  DW      _JUMP
_BPDBG    DW _NOP,_BK,__ADROPX  
  CMP     AL,'S'
  JE      @DBHE
  CALL    @DBG_ON
@DBHE:  
  POP     AX 
  TEST    AL,1
  JMP     @DBG2
   
    ALIGN_ 0
  
;  DB "GAGA"
  
  
;freemem:
;  DW ENDMEM-FREEMEM-2
;;INCLUDE NF9_1.IC1
;  ENTRY_  _ENTRY,'=:'
;  ENTRY_  0,''
;EndMem:

MyCseg  ends
        end  Start

;L_ _CONVERT
;  DW    __PAR
;  POP   BX AX SI DI
;  XCHG  AX,CX
;@@1:
;  LODSB
;  CMP   AL,'A'
;  JB    @@2
;  SUB   AL,7
;@@2:
;  SUB   AL,'0'
;  CMP   AX,BX
;  JNC   @@9
;  XCHG  DI,AX
;  MUL   BX
;  XCHG  DI,AX
;  ADD   DI,AX
;  LOOP  @@1
;  SKIPB
;@@9:
;  DEC   SI
;@@8:
;  PUSH  DI SI CX
;  JMP   @PARX
  
IF 0

L_ _BSCANE
  DW      __SCANER
  REPE    SCASB
  RET

L_ _WSCANE
  DW      __SCANER
  REPE    SCASW
  RET

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
		AND		AL,15
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


INCLUDE ITSY.IMC ;

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 0100h

Start   Label byte

  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  MOV   AX,3
  INT   10H

; -------------------
; Initialisation
; -------------------

P_ _abort
  xor DSP,DSp
  mov Rsp,-1024
  CALL  @RET
  
; -----------------------
; Outer Interpreter
; -----------------------

  DW _INITEX
NEWLINE   DW _CMD,_L
_@ACCEPT  DW _ACC,_EVAL
_@ok      DW _CR,_JUMP,NEWLINE

_STATES DW _WARY,_TO_NUM,_@EXEC,_TO_NUMC,_@COMMA

_COMMAX DW _EX,_COMMA,_RET

_RET_COM  DW __@COMM,_RET
_SET_COM  DW __@COMM,__SETVAR

_LIT   dw _RLDP
_NOOP  DW _RET

_NERRX  DW _EX
_NERR   DW _ZEQ
_error  dw _IF,_NOOP,_STEMIT,_STOKEY
_@err   dw _err,_ABORT

_TO_NUMC  DW _TO_NUM,_COMMAX
_LIT_COM  DW __@COMM,_LIT

_TO_NUM DW _count,_ATOI,_error
_2DROP DW _drop
DROPX   DW _dropX

_SEVALx dw _ex
_SEVAL  dw _COUNT
_EVAL   dw _TIBZ
@EVAL   dw _TOKEN
;        dw _brk
        DW _IF,DROPX
;        dw _brk
;        dw _cr,_dup,_print,_bkey,_drop
;        dw _brk
        dw _FINDEX
;        dw _brk
        dw _STATES
;        dw _brk
        dw _@exec
;        dw _brk
        dw _JUMP,@EVAL
        
; -----------------------
; Constants
; -----------------------

_value dw _SET_COM
_consT dw _commaX,_HENTRY,__@COMM,__CONS

  const_ _0,0
  const_ _BL,32
  const_ _L,64
  const_ _CMD,128

; -------------------
; Variables
; -------------------

_VARiable dw _0
_VAR      DW _COMMAX
_CREATE   DW _HENTRY,__@COMM,__VAR

  vaLUE_ _Ltib,0
_TIBZ     DW _DUP,TO_+_Ltib,_PLUS  
  vaLUE_ _Etib,0
; _SETBASE  DW _2M,_W_B,_2P  
;   vaLUE_ _base,10

  vaLUE_ _CNTC,0
  @cntc = _CNTC+2
  
L_ _TX 
  DW _T,_EX
  VALUE_ _T,-2048
L_ _HX 
  DW _H,_EX
  VALUE_ _H,freemem
  
 POINT_ _FINDEX,VAL_+_TOint
 POINT_ _INITEX,_REINIT
 
_STEMIT DW _LIT,_bemit
 VALUE_ EMIT,_bemit
_EMIT = $-2 
 DW @inc_cntcX
 
_STOKEY DW _LIT,_bkey
 VALUE_ KEY,_bkey
_KEY = $-2 
 DW _RET

; -----------------------
; Headers
; -----------------------

_HENTRY DW _H
_ENTRY: ; DW _0,
  dw _TOKEN?,_DUP,_C@,_1p,_TX,_MPUSH
_STM DW _PUSH,_RSTM,_POPX
  
__@COMM DW _POP
_@COMMA DW _@ 
_COMMA  DW _HX
_STP    DW _PUSH,_RSTP,_POPX

; -------------------
; print, Peek and Poke
; -------------------

_XDROP  DW _EX,_DROPX
_EXECUTE DW _PUSHX

_XSTR   DW _XR,_POP,_XDROP   
_TIMES  DW _PUSH,_XR  
_XTIMES DW _FOR,@@2
@@1     DW _J,_EXECUTE
@@2     DW _NEXT,@@1
_2EXIT  DW _RDROP
_EXIT   DW _RDROPX

_emiter dw _POP
_print  dw _COUNT
_TYPE   DW _XSTR,_COUNT,_EMIT,_RET

_CR dw _EMITer
  db 2,13,10,0
_err dw _CR,_H,_PRINT,_EMITer
  db 1,'?'

_STR DW _PUSH,_RLDP,_XR,_POPX

__SETVAR DW _DZ1
_ST DW _STP,_DROPX

; ------------------------------------
; Initialisation OF THE INTERPRETTER
; ------------------------------------

_REINIT DW _UPDICT,_CMD,_SEVALx
  DW TO_+_INITEX
  DW _JUMP,_TOint

; -----------------------
; Interpetation
; -----------------------

P_ _semicolon
  dw _RET_com
_TOint:
  DW TO_+_FINDEX,_T,_fnd,_RET
  
; -------------------
; Compilation
; -------------------

_colon:
  dw _HENTRY
_TOCOMP:
  DW TO_+_FINDEX,_H,_INC,_cfnd,_H,_DEC,_IF,@TOCOMPX
 CONST_ _ONE,1 
@TOCOMPX  DW _cfnd
_2P  DW _PLSX,2
  
;------------------------------------------

P_ __PAR
  TO_R  AR 
  TO_R  BP
  mov   bp,rsp
  X
  TO_R  TOP
  CLR   CX
;  int 3
P_ __ASM
  JMP   IP

;--------------------
;  NNUMBERS
;--------------------

L_ _ATOI
  DW  __PAR

@@ACC2  = BX
@@ACC   = DI
@@ADR   = SI
@@CNT   = CX
@@HR    = DX  ; OPTION ADDRESS
@@BASE  = BP
  
  R_TO     @@CNT 
  R_TO     @@ADR
  TO_R    @@BASE 
  CALL    @@ATOI
  R_TO     @@BASE
  TO_R    @@ACC
  TO_R    @@ACC2
  TO_R    @@ADR
  TO_R    @@CNT
  JMP     @PARX

@@setbasE:  
  cmp     al,'$'      
  JE      @@HEX
  cmp     al,'%'      
  JE      @@BIN
  cmp     al,'#'      
  JNE     @@N5
@@DIEZ: 
  XCHG    @@acc,AX 
@@numini:   
  CLR     @@acc      ; ZEROING ACCUMULATOR
  CLR     @@acc2     ; HI PART ACCUMULATOR
  SKIPA
@@HEX:
  MOV     AL,16
  SKIPA
@@BIN:
  MOV     AL,2
  DEC     AX
  DEC     AX
  xor     ah,ah
  mov     @@base,ax
  INC     @@base
  INC     @@base
  RET

  
@@N5:   
  cmp     al,'9'+1
  jc      @@ton2
  cmp     al,'A'      ; no case sensivity
  jc      @@ERNUM
  sub     al,7
@@ton2: 
  sub     al,'0'
  jc      @@ERNUM
  cmp     ax,@@base
  jc      @@ACCUM
@@ERNUM:    
  R_TO     @@HR    ; rdrop
@@ERNUM2:    
  INC     @@CNT
  RET
@@TICK?:
  JCXz    @@N5
  cmp     al,''''      
  JE      @@TICK
  cmp     al,'^'      
  JNE     @@setbasE
  LODSB
  AND     AL,31
  SKIPB
@@TICK:  
  LODSB
  DEC     CX
@@ACCUM:    
  Xchg    @@acc2,AX
  mul     @@base
  Xchg    @@acc2,AX
  Xchg    @@acc,AX
  mul     @@base
  Xchg    @@acc,AX
  add     @@acc,ax
  ADC     @@acc2,DX
  RET
  
@@ATOI:
  MOV     AL,10       ; BASE 10 INITIALLY
  CALL    @@numini
  JCXz    @@ERNUM2
  LODSB
  DEC     @@CNT
  JCXz    @@GOTC
  CMP     AL,'-'
  Jz      @@SIGN
@@GOTC:
  CALL    @@TICK?
@@GETC: 
  JCXz    @@ENDATOI
  LODSB
  DEC     @@CNT
  JMPS    @@GOTC
@@SIGN:
  CALL    @@GOTC ;@@DNEG NEXT
  not     @@acc
  not     @@acc2
  inc     @@acc
  jne     @@ENDATOI
  inc     @@acc2
@@ENDATOI:
  RET
  

L_ _TOKEN?
  DW    _NERRX
L_ _TOKEN
  DW    _Bl,_ETIB,_Ltib,_H,__PAR
  MOV    BX,CX    ; CX IS ZERO
  R_TO   DI       ;GET parametterS
  R_TO   CX    
  R_TO   SI   
  R_TO   DX   
  SUB    SI,CX
wordf:
        JCXz wordz
  lodsb
  DEC cx
  cmp al,DL
        je wordf
wordc:  
  inc  bL
  MOV  [DI+BX],Al  ; COUNT STRING
  JNE @@1
  DEc  bL
@@1:
        jCXz wordz
  lodsb
  DEC cx
  cmp al,DL
        jne wordc
wordz:   
  mov PW [VAL_+_Ltib],cx
  MOV PB [DI],BL
  MOV  pw [DI+BX+1],'`'
  TO_R  DI 
  TO_R  BX
  JMPS   @PARX

L_ _UPDICT
  DW    _H,_STR
LL_ _DICT,_TX                  ; >DICT
LL_ _MPUSH,__PAR    ; TOP OF DICTIONARY   IN DI
  R_TO   DI  ;_@_MPUSH:  
  R_TO   CX 
  R_TO   SI 
  ADD   SI,CX                ; AFTER NAME ADDRESS
  STD                        ; BACKWARDS
  CMPSB                      ; PREPARE FOR DIRECTION
  REP   MOVSB                ; NAME  MOVE
  CLD
  JMPS  @ACCEPT

; -----------------------
; Terminal Input / Output
; -----------------------

L_ _bemit
  dw    __PAR
  R_TO   Ax
  MOV   AH,0EH
  INT   10H
  jmp   @PARX

p_ _pushx
  TO_R  top
  nop
p_ _DROPX  
  jmps  @DROPX


L_ _ACC
  DW ACC_1,_COUNT,_RET
L_ ACC_1
  dw    __PAR
  R_TO   BX
  R_TO   DI
  MOV   [DI],BL
  MOV   DX,DI
  MOV   AH,10
  INT   33
@ACCEPT:  
  inc   di
@MPUSH:  
  TO_R  di
@PARX:
  MOV   DSP,BP
  X
  R_TO   BP
  R_TO   AR 
@DROPx:
  R_TO   ip
  jmps  @DROP

  
; -------------------
; String
; -------------------

P_ _C@
  mov TOPl, PB[TOP]
P_ _W_B
  mov TOPh,0
  jmpS @nop

p_ _bkey
  clr   cx
  XCHG  AX,CX
  INT   16H
  XCHG  AX,CX
  Z?    cL
  JE    @K
@K0:  
  CLR   cH
@K:
  JMPS  @WPUSH
P_ _cOUNT 
  MOV   CL,[TOP]
  INC   TOP
  JMPS  @K0

;---------------------
; RST RLD
;-----------------------

P_ _RSTM              ; (!R-
  R_TO     WA
  DEC     WA
  DEC     WA
  MOV     [WA],TOP
  TO_R    WA
  jmps    @DROP

P_ _RSTP              ; (!R+
  R_TO     WA
  XCHG    AX,TOP
  STOSW
  XCHG    AX,TOP
  TO_R    WA
  SKIPA
P_ _DEC                   ; --
	DEC   PW [TOP]
P_ _DROP
  JMPS   @DROP
	  
P_ _INC                   ; ++
	INC   PW [TOP]
  JMPS   @DROP

p_ _for 
  mov   ip,[ip]
P_ _PUSH
  TO_R TOP
@DROP:
  d_to  top
  JMPs  @nOP
  	  
P_ _LARY
  SHL   TOP,1
P_ _WARY
  SHL   TOP,1
P_ _BARY
  add   TOP,ip
  jmps  @ret
P_ _PLSX
  ADD  TOP,[IP]
  JMPS   @RET               
P_ __setpnt
  R_TO   [IP+2]
  SKIPA
P_ _ANDX
  AND  TOP,[IP]
  jmpS  @ret

P_ _J
  R_TO   wa
  R_TO   w
  TO_R  w 
  TO_R  wa
  JMPS    @WPUSH

P_ _1m
  dec  TOP
  SKIPB
P_ _1P
  INC   TOP
  JMPS  @NOP

; -------------------
; Inner Interpreter
; -------------------
  
P_ _RLDP              ; (@R+
  R_TO     WA
  MOV     w,[WA]
  INC     WA
@WPUSH1:        
  INC     WA
@_J:
  TO_R    WA  
  JMPS    @WPUSH

P_ __VAR
  MOV   W,IP
  JMPS  @WPUSHX
P_ _POPX
  R_TO   W
  SKIPA
P_ __cons
  MOV   W,[IP]
@WPUSHX:
  R_TO   IP
@WPUSH:  
  TO_D    TOP
@XCHG:
  MOV    TOP,W 
  skipa
@rdropx:  
  R_TO   w
P_ @inc_cntcX
  inc @cntc
P_ _RET
@RET:  
  R_TO   IP
@NOP:
  mov   W,[ip]
@DBG1:
  lea   ip,[ip+2]
@DBG2:
  TEST  wL,1       
  JZ    @NEST
  DEC   W
  JMP   W
    
PP_ _EX,@EX              ; ( EX
  R_TO   W
@NEST:  
  TO_R  IP
  MOV   IP,W
  N_

P_ _RDROPX
  jmps  @RDROPX
  
p_ _RDROP
  R_TO W
  SKIPB
p_ _brk
  int 3
  SKIPA
P_ _@
  MOV   TOP,[TOP]
  N_

p_ _@EXEC
  MOV   TOP,[TOP]
p_ _EXEC
  mov w,top
  d_to top
  jmpS @DBG2

; -------------------
; Stack
; -------------------

P_ _XR
  R_TO   W
  TO_R  TOP
  jmp SHORT @XCHG
  
P_ _DZ2
  R_TO  W
  INC  W
  INC  W
  SKIPB
P_ _DZ1
  R_TO  W
  INC  W
  INC  W
  SKIPB
P_ _POp   ;DZ0
@POP:  
  R_TO  W
  SKIPA
P_ _dup
  MOV W,TOP
  jmp SHORT @WPUSH

; -------------------
; Maths / Logic / ARRAY
; -------------------

LL_ _PRV_NAME,_T
_NXT_NAME DW _2P  
_END_NAME DW _COUNT
_PLUS     DW _PLAVG,_DROPX
  
P_ _PLAVG				; ( +2/
  X
  R_TO   W
  ADD   TOP,W
  TO_R  TOP
  X
P_ _2DIV  
  RCR     TOP,1
  N_
		
P_ _nAND	          ; (NAND
  D_TO W
    AND     TOP,W
@not:
    INC     TOP
P_ _NEG
    NEG     TOP
@NOP2:
    N_
    
P_ _ZEQ
  neg TOP
  sbb TOP,TOP
p_ _not  
  jmp @NOt

; -------------------
; Flow Control
; -------------------


P_ _IFM 
  JMPS    @IFM
P_ _NEXT  
  R_TO   W
  DEC   W
  TO_R  W
  SKIPR W
P_ _MIF 
  INC   TOP
@IFM: 
  DEC   TOP
  JS    @SKIP
P_ __DEFER
P_ _JUMP
@JUMP:        
  mov   iP,PW [iP]
  jmpS  @nOP

P_ _IF
  Z?    TOP
  D_TO  TOP
  je    @JUMP
P_ _SKIP
@SKIP:
  INC   IP
  INC   IP
  jmpS  @nOP

; -----------------------
; Dictionary Search
; -----------------------
 
L_ _CFND
  DW _PRV_NAME      ; SKIP LAST NAME
LL_ _FND,__PAR         
  CALL  @METHOD
  repe  cmpsb
  RET
@METHOD:
  R_TO   DX
  R_TO   DI
  R_TO   AX
@fnd:
  add   di,cx
  mov   Bx,di
  INC   DI    ;  LEA   di,[DI+4]
  INC   DI    ;  LEA   di,[DI+4]
  mov   cl,[di]
  jcxz  xfnd?
  INC   CX
  MOV   SI,AX
  CALL  DX
  jNZ   @fnd
  MOV   cL,1
;  STC
;  ADC   [BX+2],CX
  XCHG  BX,AX
xFND?:
  TO_R  AX
  TO_R  CX 
@PARX1:  
  jmp   @parx
@WFND:
  CALL  @METHOD
  CMP   SI,[DI-4]
  RET

LL_ _WFIND,_T
LL_ _WFND,__PAR         
  JMPS  @WFND

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
  jmpS  @parx1

  ALIGN_ 0
  
freemem:
  dw  endcode-freemem-2
  entry_ _entry,'=:'
  entry_ 1,'bye'
  entry_ _emit,'emit'
  entry_ _const,'const'
  entry_ _colon,':'
  entry_ _semicolon,';`'
  ;dw 0
  db 0
  
endcode:  

MyCseg  ends
        end  Start

L_ _PK
  dw    __PAR
  XCHG  AX,CX
  R_TO   DI
  R_TO   CX
  R_TO   SI
  SKIPA
@DO_BL:  
  MOV   AL,' '
@PK_ST:  
  STOSB
@PK_END?:  
  JCXz  @PK_END
  LODSB
  DEC   CX
  JCXz  @?BL
  CMP   AL,'"'
  JE    @2KAV
  CMP   AL,'^'
  JNE   @?BL
  LODSB
  AND   AL,31
  SKIPB
@2KAV:
  LODSB
  DEC   CX
  JMPS  @PK_ST
@?BL:
  CMP   AL,'_'
  JE    @DO_BL
  CMP   AL,'~'
  JNE   @PK_ST
  XOR   PB [DI-1],80H
  JMPS  @PK_END?
@PK_END:
  DEC   DI
  SUB   DI,BX
  XCHG  DI,BX
  MOV   [DI],BL
  TO_R  DI
  jmpS  @PARX

;p_ _bkey?
;  XCHG  AX,CX
;  mov   ah,1
;  INT   16H
;  XCHG  AX,CX
;  CLc
;  JE    @K1
;  stc
;@K1:
;  sbb   cx,cx
;  JMPS  @WPUSH

;P_ _NIP
;  nip_
;  N_
  
;L_ _CONV
;  DW    __PAR
;  mov   bx,cx
;  mov   di,cx
;  xchg  AX,cx
;  POP   BP CX SI  
;
;to_numl:
;        jcxz to_numz
;  lodsb
;	dec  cx
;  CMP   AL,'0'+0AH
;        JC    OK_DIG?
;  CMP   AL,'A'
;        JC    to_numERR
;  SUB   AL,7
;OK_DIG?:
;  SUB   AL,'0'
;        JC    to_numERR
;  CMP   AX,BP
;        JNC   to_numERR
;@MULADD:
;  xchg ax,di
;  mul  bp
;	xchg ax,di
;  xchg ax,BX
;  mul  bp
;	xchg ax,BX
;  adD  di,AX
;  adC  BX,DX
;        jmp  to_numl
;to_numERR:
;  INC   CX
;  DEC   SI
;to_numz:
;  push di BX SI CX
;    JMPS   @PARX
    

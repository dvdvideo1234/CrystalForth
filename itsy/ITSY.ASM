INCLUDE ITSY.IMC

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
  DW _INITEX
  
; -----------------------
; Outer Interpreter
; -----------------------

NEWLINE: 
        dw _emiter
        db 13,10,'>',0
        DW _READLN
        dw _emiter
        db ' ',0
        dw _EVAL
        dw _emiter
        db ' Ok',0
        DW _JUMP,NEWLINE

 ALIGN_ 0
 
_STATES DW _WARY,_TO_NUM,_@EXEC,_TO_NUMC,_@COMMA

_COMMAX DW _EX,_COMMA,_RET

_LIT_COMX DW _EX,_COMMAX
_LIT_COM  DW __@COMM,_LIT
_RET_COM  DW __@COMM,_RET

_VAR  DW _COMMAX
_CREATE   DW _HENTRY,__@COMM,__VAR

LL_ _2LIT,_RLDP
LL_ _LIT,_RLDP
_NOP DW _RET

_@NERR  DW _?C@
_NERR   DW _ZEQ
_error  dw _IF,_NOP,_emiter
        db '?',0
        dw _ABORT

_TO_NUMC  DW _LIT_COMX
_TO_NUM DW _PUSH,_0,_0,_POP,_count,_CONV,_error
_2DROP DW _drop
DROPX   DW _dropX


P_ _?C@
  DW _DUP,_C@,_RET
  
_SEVAL  dw _COUNT
_EVAL   dw _TIBZ
@EVAL   dw _TOKEN,_?C@
        DW _IF,DROPX,_FINDEX,_STATES,_@exec,_JUMP,@EVAL
        
_TO_T DW _T,_2PLUS,_2PLUS,_COUNT,_PLUS,_RET

; -----------------------
; Constants
; -----------------------

_consT dw _commaX,_HENTRY,__@COMM,__CONS

  const_ _0,0
  const_ _BL,32
  const_ _L,64
  const_ _CMD,128
  const_ _tib,-2048

; -------------------
; Variables
; -------------------

  vaLUE_ _Ltib,0
_TIBZ     DW _DUP,TO_+_Ltib,_PLUS  
  vaLUE_ _Etib,0
_SETBASE  DW _2M,_W_B,_2P  
  vaLUE_ _base,10

L_ _TX 
  DW _T,_EX
  VALUE_ _T,-2048
L_ _HX 
  DW _H,_EX
  VALUE_ _H,freemem
  
 POINT_ _FINDEX,VAL_+_TOint
 POINT_ _INITEX,_REINIT

; -----------------------
; Headers
; -----------------------

_HENTRY DW _H
_ENTRY DW _0,_TOKEN,_@NERR,_?C@,_TX,_MPUSH,_STM,_STM,_RET
  
__@COMM DW _POP
_@COMMA DW _@ 
_COMMA  DW _HX,_STP,_RET

; -------------------
; print, Peek and Poke
; -------------------

_emiter dw _CRLDP,_DUP,_IF,DROPX,_EMIT,_JUMP,_EMITER

_STR DW _PUSH,_RLDP,_XR,_POPX

_@ DW _STR,_NIP,_RET

_ST DW _STP,_DROPX

_JMPX DW _RLDP,_XR,_PUSH,_RET

P_ _STP
  D_TO  [TOP]
P_ _2P
  INC   TOP
@1P:  
  INC   TOP
  JMPS  @NOP3
P_ _1P
  JMPS  @1P

P_ _STM
  D_TO [TOP-2]
@2M:
  DEC TOP
P_ _1M
  DEC TOP
@NOP3:  
  JMP @NOP
P_ _2M
  JMPS @2M

; ------------------------------------
; Initialisation OF THE INTERPRETTER
; ------------------------------------

_REINIT DW _UPDICT,_CMD,_JMPX,_SEVAL
  DW TO_+_INITEX
  DW _SKIP

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

;_BRK: DW $+2
;    INT 3
;    JMP NEXT
    
_colon dw _HENTRY

_TOCOMP:
  DW TO_+_FINDEX,_H,_INC,_cfnd,_H,_DEC
  DW _DUP,_IF,@TOCOMPX,_ret
@TOCOMPX  DW _DROP,_cfnd
_2PLUS DW _LIT,2,_PLUS
  DW _RET
  
;------------------------------------------

P_ __PAR
  PUSH  AR BP
  X
  PUSH  TOP
  CLR   CX
P_ __ASM
  JMP   IP

P_ __ASMX
  POP   WA
  XCHG  WA,IP
  JMP   WA
  
LL_ _TOKEN,_Bl
LL_ _word,_H,_ETIB,_Ltib,__PAR
  XCHG  AX,CX
  POP  CX SI BX DX   ;GET parametterS
  PUSH BX
	mov DI,bx
  STOSB 
  SUB SI,CX
wordf:
        JCXz wordz
  lodsb
  DEC cx
  cmp al,DL
        je wordf
wordc:  
  inc  Pb [bx]
  STOSB
        jCXz wordz
  lodsb
  DEC cx
  cmp al,DL
        jne wordc
wordz:   
  mov PW [VAL_+_Ltib],cx
  MOV PB [DI],'`'
    JMPS   @PARX

PP_ _CONV,_PAR
	PUSH CX
  CALL @POPAL
to_numl:
        jcxz to_numz
  lodsb
	dec  cx
  CMP   AL,'0'+0AH
        JC    OK_DIG?
  CMP   AL,'A'
        JC    to_numERR
  SUB   AL,7
OK_DIG?:
  SUB   AL,'0'
        JC    to_numERR
  CMP   AX,BP
        JNC   to_numERR
  CALL @MULADD
        jmp  to_numl
to_numERR:
  INC   CX
  DEC   SI
to_numz:
  push BX di SI CX
    JMPS   @PARX
    
@MULADD:
  xchg ax,di
  mul  bp
	xchg ax,di
  xchg ax,BX
  mul  bp
	xchg ax,BX
  adD  di,AX
  adC  BX,DX
  RET
  
@POPAL:
  POP DX AX CX SI BX DI 
  MOV  BP,PW [VAL_+_BASE]
  JMP DX

P_ _RSTM              ; (!R+
  POP     WA
  DEC     WA
  DEC     WA
  MOV     [WA],TOP
  JMPS   @PUSHWA
		    
P_ _RSTP              ; (!R+
  POP     WA
  MOV     [WA],TOP
  SCASW
PP_ PUSHWA,@PUSHWA
  PUSH    WA
  SKIPA
P_ _DEC                   ; ++
	DEC   PW [TOP]
P_ _DROP
  JMPS   @DROP
	  
P_ _INC                   ; ++
	INC   PW [TOP]
  JMPS   @DROP
p_ _for 
  mov   ip,[ip]
P_ _PUSH
  PUSH TOP
@DROP:
  d_to  top
  JMPs  @nOP
  	  
L_ _UPDICT
  DW    _H,_STR
LL_ _DICT,_TX                  ; >DICT
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
@PARX:
  MOV   RSP,BP
  X
  POP   BP AR
P_ _DROPx
  jmps  @DROPx

P_ __VAR
  MOV   W,IP
  JMPS  @WPUSHX
P_ __cons
  push   [IP]
P_ _POPX
  POP   W
@WPUSHX:
  POP   IP
  JMPS  @WPUSH
  
 P_ _CRLDP                 ; ( C@R+
	POP		  WA
  MOV     wL,[WA]
  mov     wh,0
  JMPS    @WPUSH1

P_ _RLDP              ; (@R+
  POP     WA
  MOV     w,[WA]
  INC     WA
@WPUSH1:        
  INC     WA
@_J:
  PUSH    WA  
@WPUSH:  
  TO_D    TOP
@XCHG:
  MOV    TOP,W 
  jmpS  @nop

; -------------------
; Inner Interpreter
; -------------------

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
  jmpS  @ret
P_ __SETVAR
  MOV   [IP+2],top
  skipb 
p_ _pushx
  push  top
@DROPX:
  D_TO  TOP
P_ _RET
@RET:  
  POP   IP
@NOP:
  mov    WA,[ip]
@DBG1:
  lea   ip,[ip+2]
@DBG2:
  TEST    wa,1       
  JZ      @NEST
  DEC     WA
  JMP     WA
    
PP_ _EX,@EX              ; ( EX
  POP     WA
@NEST:  
  XCHG    IP,WA
@RPUSH:
  PUSH    WA
  N_

P_ _@EXEC
  MOV TOP,[TOP]
P_ _EXEC
  MOV WA,TOP
  D_TO TOP
  jmpS @DBG2

; -------------------
; Stack
; -------------------

P_ _NIP
  X
  POP W
  X
  N_
  
P_ _XR
  POP   W
  PUSH  TOP
  jmp SHORT @XCHG
  
P_ _POp
@POP:  
  POP  W
  SKIPA
P_ _dup
  MOV W,TOP
  jmp SHORT @WPUSH

; -------------------
; Maths / Logic / ARRAY
; -------------------

L_ _MINUS
  DW _NEG
L_ _PLUS
  DW _PLAVG,_DROPX
  
P_ _PLAVG				; ( +2/
  X
  POP   W
  ADD   TOP,W
  PUSH  TOP
  X
P_ _2DIV  
  RCR     TOP,1
  N_
		
P_ _nAND	          ; ( AND
  D_TO W
    AND     TOP,W
@not:
    INC     TOP
P_ _NEG
    NEG     TOP
    N_
    
P_ _ZEQ
  neg TOP
  sbb TOP,TOP
p_ _not  
  jmp @NOt

P_ _WARY
  SHL   TOP,1
P_ _BARY
  pop WA
  add TOP,WA
@NOP2:
  jmp @NOP

; -------------------
; Flow Control
; -------------------

P_ __DEFER
P_ _JUMP
@JUMP:        
  mov iP,PW [iP]
  jmpS @nOP

P_ _IF
  Z? TOP
  D_TO TOP
  je @JUMP
P_ _SKIP
  INC IP
  INC IP
  jmpS @nOP2

; -----------------------
; Terminal Input / Output
; -----------------------

LL_ _emit,__PAR
  MOV Dx,bx
  mov  Ah,2
  int  021h
  jmp  @PARX

P_ _key
  MOV  WH,7
  XCHG AX,W
  int 021h
  mov ah,0
  XCHG AX,W
  JMP @WPUSH

L_ _READLN
  DW _CMD,_L
LL_ _ACCEPT,__ASMX
  PUSH DX
  MOV DX,BX
  D_TO BX
  PUSH AX
  MOV  [BX],DL
  MOV DX,BX
  MOV AH,10
  INT  33
  POP  AX DX
  INC  BX 
  
; -------------------
; String
; -------------------

P_ _cOUNT 
  inc  TOP
  TO_D TOP
  DEC  TOP
P_ _C@
  mov TOPl, PB[TOP]
P_ _W_B
  mov TOPh,0
  jmp @NOP

; -----------------------
; Dictionary Search
; -----------------------

L_ _CFND
  DW _TO_T
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
@WFND:
  CALL  @METHOD
  CMP   SI,[DI-4]
  RET

LL_ _WFIND,_T
LL_ _WFND,__PAR         
  JMPS  @WFND

  ALIGN_ 0
  
freemem:
  dw  endcode-freemem-2
  entry_ _entry,'=:'
  entry_ 0,0
  
endcode:  

MyCseg  ends
        end  Start

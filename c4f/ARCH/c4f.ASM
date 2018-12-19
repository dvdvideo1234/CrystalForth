; COMMANDS      OF INTERPRETER
; JUMP EXIT IF NEXT   CONTROLS
; push pop J DUP      STACK
; !R+ @R+ xR XA       TRANSFER
; +2/ +* AND XOR      MATH & LOGIC

locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_     =  -1
AT_     =  -2

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

X_      MACRO
  xchg  Rsp,DSP
        ENDM

pushR_  MACRO  REG
  PUSH  REG
        ENDM

popR_   MACRO  REG
  xchg  t,reg
  drop_
        ENDM

R2P_    macro   REG
  INC   REG
  INC   REG
  endm

R2M_    macro   REG
  DEC   REG
  DEC   REG
  endm

@IP_    macro  REG
  MOV   REG,[IP]
  R2P_  IP
  endm

cf_to_  macro  reg
  sbb   reg,reg
        endm

DROP_   macro
  LODSW
        endm

DUP_    macro  REG
  R2M_  DSP
  MOV   [DSP],REG
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

L_      MACRO NAM,L@
  ALIGN_  0
L@:
  NAM   = (($-START+100H) SHR 1)+8000H
        ENDM

P_      MACRO NAM,L@
  ALIGN_  0
L@:
  NAM   = ($-START+100H) SHR 1
  ENDM

N_      MACRO
  JMP   NP
  ENDM
  
; REGISTERS     for interpretter
IP  = BX  ; INSTUCTION POINTER
RSP = SP  ; RETURN STACK POINTER
DSP = SI  ; DATA STACK POINTER
NP  = DX  ; TO NEXT POINTER

T   = AX  ; DATA STACK TOP REGISTER
TL  = AL  ; DATA STACK TOP REGISTER
TH  = AH  ; DATA STACK TOP REGISTER
WA  = DI  ; WORK ADDRESS REGISTER
W   = CX  ; WORK REGISTER
WL  = CL  ; WORK REGISTER
WH  = CH  ; WORK REGISTER

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
_START:

 P_ _ABORT,@ABORT
  mov   bX,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  CALL  @NEXTS
  
 P_ _NOP,@NOP           ; ( NOP
  @IP_    WA
  SHL     WA,1
  JC      @NEST
  JMP     WA
  
 P_ _EX,@EX             ; ( EX
  POP     WA

@NEST:  
  PUSH    IP
  MOV     IP,WA
  JMPS_   @NOP
  
 
@NEXTS:
  POP   NP
  MOV   RSP,@R_TOP-2
  MOV   DSP,@S_TOP-2
  CALL  @RET
  
_@INIT  DW 0
AR      DW 0

;vvvvvv--------------   IO  ---------------

 P_ _IODD,@IODD              ; ( IO
  DUP_    T
  
 P_ _IOD,@IOD              ; ( IO
  DUP_    T
  
 P_ _IO,@IO              ; ( IO
  PUSH    NP
  MOV     DI,[DSP]
  MOV     CX,[DSP+2]
  MOV     DX,[DSP+4]
  CALL    IP
  POP     NP 
  
;^^^^^^--------------   IO  ---------------


;-------------------------------------------
; CONTROL
;-------------------------------------------

 P_ _DROPX,@DROPX       ; DROP;
        DROP_
        SKIPB_
        
 P_ _RDROPX,@RDROPX
        POP     W
  
@RETA:  POP     IP
        N_
        
 P_ _RET,@RET           ; ( (;
        JMPS_   @RETA

 P_ _NEXT,@NEXT
        POP     W
        DEC     W
        PUSH    W
        SKIPC_  WL
        
 P_ _IFM,@IFM
        DEC     T        
        JS      @SKIP
        
 P_ _JUMP,@JUMP             ; ( (JUMP
        @IP_    IP
        N_
        
 P_ _?SKIP,@?SKIP
        Zero?_  T
        JE      @1P?
        N_
        
 P_ _IF,@IF              ; ( IF
        DEC     T        
@1P?:        
        INC     T
        DROP_
        JZ      @JUMP
        
 P_ _SKIP,@SKIP          ; ( SKIP
        R2P_    IP
        N_
        
 P_ _RSKIP,@RSKIP
        POP     WA
        R2P_    WA
        SKIPA_
 
 P_ _XR,@XR              ; ( XR  XCHG
        POP     WA
        XCHG    T,WA
        JMPS_   @_XA
        
 P_ _XA,@XA              ; ( XA
        POP     WA
        XCHG    WA,AR
@_XA:
        PUSH    WA
        N_

@_RSTP:
        PUSH    WA
        SKIPB_
        
 P_ _PUSH,@PUSH          ; ( PUSH
        PUSH    T
@DROP1:
        DROP_
        N_
      
 P_ _BE,@BE
        MOV     AH,0EH
        INT     10H
        JMPS_   @DROP1
      
 P_ _RSTM,@RSTM         ; ( !R-
        POP     WA
        R2M_    WA
        SKIPB_
        
 P_ _RST,@RST         ; ( !R
        POP     WA
@RST1:        
        PUSH    WA
        STOSW
        DROP_
        N_
        
 P_ _RSTP,@RSTP         ; ( !R+
        POP     WA
        STOSW
        JMP     @_RSTP
        
 P_ _RSTBP,@RSTBP         ; ( C!R+
        POP     WA
        STOSB
        JMP     @_RSTP
        
 P_ _RLDP,@RLDP          ; ( @R+
        POP     WA
        MOV     W,[WA]
        R2P_    WA
        JMPS_   @_J
        
 P_ _RLDBP,@RLDBP          ; ( C@R+
        POP     WA
        MOV     WL,[WA]
        CLR_    WH
        INC     WA
        JMPS_   @_J
        
 P_ _J,@J                ; ( J
        POP     WA
        POP     W
        PUSH    W
@_J:
        PUSH    WA
@WPUSH:
        DUP_    T
        XCHG    W,T
        N_
        
 P_ _POP,@POP            ; ( POP
        POP     W
        SKIPA_
        
 P_ _DUP,@DUP            ; ( DUP
        MOV     W,T
        JMPS_   @WPUSH
                
 P_ _ALIGN,@ALIGN
        DEC     T
        OR      TL,1
        
 P_ _1P,@1P        
        INC     T
        N_
        
 P_ _PLAVG,@PLAVG        ; ( +2/
        ADD     T,[DSP]
        MOV     [DSP],T
        
 P_ _2DIV,@2DIV          ; ( 2/
        RCR     T,1
        N_
        
 P_ _SDIV,@SDIV          ; ( -/
        SHL     PW [DSP],1
        RCL     T,1
        CMP     T,AR
        JB      @_NO_DIV
        SUB     T,AR      
        
 P_ _U1P,@U1P
        INC     PW [DSP]
@_NO_DIV:
        N_

 P_ _PMUL,@PMUL          ; ( +*
        MOV     W,[DSP]
        SHR     W,1
        JNC     @D2DIV
        ADD     T,AR
        
 P_ _D2DIV,@D2DIV
        RCR     T,1
        
 P_ _U2DIV,@U2DIV        
        RCR     PW [DSP],1
        N_

 P_ _4MUL,@4MUL        
        SHL     T,1
        
 P_ _2MUL,@2MUL        
        SHL     T,1
        N_

 P_ _nAND,@nAND          ; ( AND
        POPR_   W
        AND     T,W
        
 P_ _NOT,@NOT
        INC     T
        
 P_ _NEG,@NEG         
        NEG     T
        N_

 P_ _XOR,@XOR            ; ( XOR
        POPR_   W
        XOR     T,W
        N_
        
 P_ _ZEQ,@ZEQ
        SUB     T,1
        SKIPR_  W
 P_ _ZLESS,@LESS
        SHL     T,1
        CF_TO_  T
        N_

 L_ _CTX,@CTX      ; ( c -- ) \ Send character c to output device.
  DW  _IO      ; char in DL
  XCHG  AX,DX
  CMP   DL,0FFH ; 0FFH is interpreted as input
  JNZ   @TX1    ; do NOT allow input
  MOV   DL,32   ; change to blank
@TX1:
  MOV   AH,6    ; MS - DOS Direct Console I/O
  INT   021H    ; display character
  RET
  
 L_ _?CRX,@?CRX      ; (  -- c T | F )  
  DW _IODD
  MOV   DX,0FFFFH ; input command & setup for TRUE flag
  MOV   [DSP],DX  
  CALL  @TX1      ; MS - DOS Direct Console I/O
  JNZ   QRX0    ; ?key ready
  DEC   DX      
  DROP_
  MOV   [DSP],DX
  RET
QRX0:  
  OR    AL,AL   ; AL=0 if extended char
  JNZ   QRX1    ; ?extended character code
  INT   021H    ;
  STC
QRX1:
  MOV   AH,0
  JNC   QRX2
  XCHG  AH,AL   ; extended code in msb
QRX2:
  MOV   [DSP+2],AX
  RET
    
_END:
    
MyCseg  ends
        end  Start

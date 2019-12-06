; COMMANDS      OF INTERPRETER
; JUMP EXIT IF IFM   CONTROLS
; push pop J DUP      STACK
; !R+ @R+ xR XA       TRANSFER
; +2/ +* AND -/       MATH & LOGIC

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
  MOV   T,[DSP]
  LEA   DSP,[DSP+2]
        endm

DUP_    macro  REG
  LEA   DSP,[DSP-2]
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
  JMP SHORT   @NOP
  ENDM
  
; REGISTERS     for interpretter
T   = BX  ; DATA STACK TOP REGISTER
TL  = BL  ; DATA STACK TOP REGISTER
TH  = BH  ; DATA STACK TOP REGISTER
IP  = SI  ; INSTRUCTION POINTER
RSP = SP  ; RETURN STACK POINTER
DSP = BP  ; DATA STACK POINTER
NP  = CX  ; TO NEXT POINTER
AR  = DX  ; ARITHMETIC (ALTERNATIVE) REGISTER

WA  = DI  ; WORK ADDRESS REGISTER
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
_START:

 P_ _ABORT,@ABORT
  MOV   RSP,@R_TOP-2
  MOV   DSP,@S_TOP-2
  CALL  @DBG
  CALL  @RETA
 _@INIT  DW 0
;AR      DW 0

 
  
 ;vvvvvv--------------   IO  ---------------

 P_ _IO,@IO              ; ( IO
  PUSH    AR
  XCHG	  AX,BX
  MOV     BX,[DSP]
  MOV     CX,[DSP+2]
  MOV     DX,[DSP+4]
  CALL    IP
  POP     AR 
  
;^^^^^^--------------   IO  ---------------


;-------------------------------------------
; CONTROL
;-------------------------------------------

 P_ _RET,@RETA           ; ( (;
        POP     IP
        N_
@DROP:  DROP_		
@DBG:	RET		
        
 P_ _SKIP,@SKIP          ; ( SKIP
        JMP  SHORT    @SKIP2
 P_ _IFM,@IFM
        JMP  SHORT    @IFM2
 P_ _MIF,@MIF
        INC     T        
@IFM2:
        DEC     T        
        JS      @SKIP2
        
 P_ _JUMP,@JUMP             ; ( (JUMP
        MOV     IP,[IP]
        N_
        
 P_ _IF,@IF              ; ( IF
        DEC     T        
        INC     T
        CALL    @DROP
        JZ      @JUMP         
@SKIP2: 
        LODSW
        N_
        
 P_ _RDEC1,@RDEC1
        POP     W
        SKIPA_
 P_ _RDEC2,@RDEC2
        POP     W
        R2P_    W
        SKIPA_
 
 P_ _XR,@XR              ; ( XR  XCHG
        POP     W
        XCHG    T,W
@_XA:
        PUSH    W
        N_
        
 P_ _XA,@XA              ; ( XA
        POP     W
        XCHG    W,AR
        JMPS_   @_XA

 P_ _RSTP,@RSTP         ; ( !R+
        POP     WA
        XCHG    T,W
        STOSW
        PUSH    WA
 P_ _DROP,@_DROP          ; ( DROP
        JMPS_   @DROP1
        
 P_ _PUSH,@PUSH          ; ( PUSH
        PUSH    T
@DROP1:
        CALL    @DROP
        N_
      
 P_ _J,@J                ; ( J
        POP     WA
        POP     W
        PUSH    W
        JMPS_   @_J

 P_ _RLDP,@RLDP          ; ( @R+
        POP     WA
        MOV     W,[WA]
        R2P_    WA
@_J:
        PUSH    WA
        SKIPA_
        
@_DUP_:
        PUSH    T
		
 P_ _POP,@POP            ; ( POP
        POP     W
@WPUSH:
        DUP_    T
        XCHG    W,T
 P_ _NOP,@NOP           ; ( NOP
        LODSW
        SHL     W,1
        JC      @NEST
        JMP     W
@NEST:  
        PUSH    IP
        MOV     IP,W
        JMPS_   @NOP
		
 P_ _DUP,@DUP            ; ( DUP
        JMPS_   @_DUP_
                        
 P_ _PLAVG,@PLAVG        ; ( +2/
        ADD     T,[DSP]
        MOV     [DSP],T
        
 P_ _2DIV,@2DIV          ; ( 2/
        RCR     T,1
        N_
 P_ _MSB1,@MSB1
        STC
        JMPS_   @2DIV
        
 P_ _SDIV,@SDIV          ; ( -/
        SHL     PW [DSP],1
        RCL     T,1
        CMP     T,AR
        JB      @_NO_DIV
        SUB     T,AR      
        INC     PW [DSP]
@_NO_DIV:
        N_

 P_ _PMUL,@PMUL          ; ( +*
        MOV     W,[DSP]
        SHR     W,1
        JNC     @D2DIV
        ADD     T,AR
@D2DIV:
        RCR     T,1
        RCR     PW [DSP],1
        N_

 P_ _nAND,@nAND          ; ( AND
        AND     T,[DSP]
        INC     DSP
        INC     DSP
 P_ _NOT,@NOT
        NOT     T
        N_

_END:
    
MyCseg  ends
        end  Start

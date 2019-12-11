; COMMANDS      OF INTERPRETER
; JUMP EXIT IF IFM   CONTROLS
; push pop J DUP      STACK
; !R+ @R+ xR XA       TRANSFER
; +2/ +* AND -/       MATH & LOGIC

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

NIP_   macro
  R2P_  DSP
        endm
        
DROP_   macro
  MOV   T,[DSP]
  NIP_
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

P_  MACRO NAM
  ALIGN_ 0
  NOP
NAM:
  org   $-1
ENDM

L_      MACRO NAM
  ALIGN_  0
NAM:
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
AR  = DX  ; ARITHMETIC (ALTERNATIVE) REGISTER

WA  = DI  ; WORK ADDRESS REGISTER
NP  = CX  ; TO NEXT POINTER
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
        DW      0
;AR      DW 0

 
  
 L_ _SLSKIP,@SLSKIP            ; ("SKIP
        POP     WA
        MOV     WL,[WA]
        CLR_    WH
        OR      WL,1        ; MAKE CNT ODD
        ADD     W,WA
        XCHG    W,WA
        JMPS_   @WPUSH1

;-------------------------------------------
; CONTROL
;-------------------------------------------

 P_ _IFM,@IFM
        JMP  SHORT    @IFM2
        
 P_ _NEXT,@NEXT
        POP     W
        DEC     W
        PUSH    W
        SKIPR_  W
 P_ _MIF,@MIF
        INC     T        
@IFM2:
        DEC     T        
        JP      @JUMP
 P_ _SKIP,@SKIP          ; ( SKIP
        LODSW
        SKIPA_
 P_ _JUMP                ; ( (JUMP
@JUMP:
        MOV     IP,[IP]
        N_
 P_ _IF,@IF              ; ( IF
        DEC     T        
        INC     T
        JZ      @JUMP         
 P_ _SKIPDR,@SKIPDR          ; ( SKIP
        LODSW
        SKIPA_
 P_ _JUMPDR,@JUMPDR             ; ( (JUMPDR
        MOV     IP,[IP]
 P_ _DROP                    ; ( DROP
@DROP:          
        MOV   T,[DSP]       
 P_ _NIP,@NIP
        NIP_
        N_
 P_ _FOR,@FOR          ; ( FOR
        MOV     IP,[IP]
 P_ _PUSH,@PUSH              ; ( IF
        PUSH    T
        JMPS_   @DROP
@DBG:   RET 

 P_ _DROPX          ; ( DROP;
        POP     IP
        JMPS_   @DROP
 P_ _CRSTP,@CRST         ; ( C!R+
        POP     WA
        XCHG    T,W
        STOSB
        PUSH    WA
        JMP     @DROP       
        
 P_ _RSTP,@RST         ; ( !R
        POP     WA
        XCHG    T,W
        STOSW
        PUSH    WA
        JMP     @DROP       
 P_ _RLDP,@RLD          ; ( @R
        POP     WA
        MOV     W,[WA]
        INC     WA
@WPUSH1:        
        INC     WA
        PUSH    WA      
        JMPS_   @WPUSH
        
 P_ _CRLDP                 ; ( C@R+
        POP     WA
        MOV     WL,[WA]
        INC     WA
        JMPS_   @BPUSH0
        
 P_ _STR,@STR
        MOV     W,[T]
        INC     T
        INC     T
        JMPS_   @WPUSH
        
 P_ _DEA,@DEA
        MOV     WL,[T+4]
        SKIPA_
 P_ _?C@,@?C@
        MOV     WL,[T]
        JMPS_   @BPUSH
        
 P_ _J,@J                ; ( J
        POP     WA
        POP     W
        PUSH    W
@_J:
        PUSH    WA
        JMPS_   @WPUSH
 P_ _OVER,@OVER
        push    [DSP]
        SKIPB_
 P_ _SPLD,@SPLD
        PUSH    DSP
        SKIPB_
 P_ _RPLD,@RPLD
        PUSH    RSP
        SKIPB_
 P_ _ALD,@ALD
        PUSH    AR
        SKIPB_
 P_ _DUP,@DUP            ; ( DUP
        PUSH    T
@RPOP:  POP     W
        JMPS_   @WPUSH

@BPUSH0:PUSH    WA
@BPUSH: CLR_    AH
@WPUSH: DUP_    T
        XCHG    W,T 
        SKIPA_
@NEST:  
        XCHG    IP,W
@RPUSH:
        PUSH    W
@NOP:   LODSW
        TEST    WL,1
        JZ      @NEST
        INC     W
        JMP     W
 P_ _EX,@EX              ; ( EX
        POP     W
 P_ _NOP,@NOOP           ; ( NOP
        JMPS_   @NOP
 P_ _POP
        JMPS_   @RPOP    ; ( POP
        
                
 P_ _XR,@XR              ; ( XR  XCHG
        POP     W
        XCHG    T,W
        JMPS_   @RPUSH        
 P_ _XA,@XA              ; ( XA
        POP     W
        XCHG    W,AR
        JMPS_   @RPUSH
 P_ _R1M
        POP     WA
 P_ _R2M
        POP     WA
        DEC     WA
        DEC     WA
        PUSH    WA
        JMPS_   @NOP
 P_ _1M
        JMPS_   _2M
 P_ _2M
        R2M_    T
        JMPS_   @NOP
        
 P_ _PLAVG,@PLAVG        ; ( +2/
        ADD     T,[DSP]
        MOV     [DSP],T       
 P_ _2DIV                ; ( 2/
@2DIV:
        RCR     T,1
        N_
 P_ _MSB1,@MSB1
        STC
        JMPS_   @2DIV 
 P_ _SDIV,@SDIV          ; ( -/
        SHL     PW [DSP],1
        RCL     T,1
        CMP     T,AR
        JB      @NOP
        SUB     T,AR        
@U1MM:  INC     PW [DSP]
        N_
 P_ _U1P,@U1P          ; ( U1-
        JMPS_   @U1MM 
 P_ _PMUL,@PMUL          ; ( +*
        MOV     W,[DSP]
        SHR     W,1
        JNC     @D2DIV
        ADD     T,AR
@D2DIV: RCR     T,1
        RCR     PW [DSP],1
        N_
 P_ _nAND,@nAND          ; ( AND
        AND     T,[DSP]
        NIP_
@NOT:   INC     T
 P_ _NEG,@NEG
        NEG     T
        N_
 P_ _0LESS,@0LESS
        SHL     T,1
        SBB     T,T
        N_
  
 P_ _ZEQ,@ZEQ
        NEG     T
        SBB     T,T
 P_ _NOT,@@1
        JMPS_  @NOT
        
 L_ _XDROP,@XDROP
        DW _EX
_DROPXX DW _DROPX
        
 P_ _INTST
        POP     W
        MOV     PB @INT,WL
        SKIPB_
 P_ _BRK
        INT 3
        SKIPB_
 P_ _RDROP,@RDROP      ; RDROP
        POP     W
        SKIPB_
 P_ _RET               ; ( (;
@RET:
        POP     IP
@NOP2:  JMP     @NOP

 P_ _RDROPX         ; ( RDROP;
        POP     W
        POP     IP
        JMP     @NOP2
        
 P_ _4PX,@4PX
        INC     T
        INC     T
 P_ _2PX
@2PX:
        INC     T
        INC     T
        JMPS_   @RET
 P_ _1PX,@1PX
        JMPS_   @2PX+1
                
 P_ _TARY,@LARY     
        SHL     T,1
 P_ _5ARY,@5ARY     
        ADD     IP,T
 P_ _LARY,@LARY     
        SHL     T,1
 P_ _WARY,@WARY     
        SHL     T,1
 P_ _BARY,@BARY 
        LEA     T,[T+IP]
        JMPS_   @RET
 
 ;vvvvvv--------------   IO  ---------------
 
 L_ _INT
        DW      _PUSH,_INTST
 L_ _DOINT      
        DW      _IO
        INT     21H
@INT = $-1      
        PUSHF
        XCHG    AX,BX
        MOV     [DSP+0],BX
        MOV     [DSP+2],CX
        MOV     [DSP+4],DX
        DUP_    T
        POP     T
        RET
 P_ _TOA,@TOA              ; (R>A;
        JMP SHORT @TOA1
 P_ _IO,@IO              ; ( IO
        PUSH    AR
        XCHG    AX,BX
        MOV     BX,[DSP]
        MOV     CX,[DSP+2]
        MOV     DX,[DSP+4]
        CALL    IP
@TOA1:  POP     AR 
        JMPS_   @RET
 P_ _BE,@BE              ; (BE
        XCHG    W,T
        MOV     AH,0EH
        INT     10H
        JMP     @DROP   
        DW      _XDROP
 L_ _BK,@BK
        DW _DUP,_IO
        CLR_    AH
        INT     16H
        OR      AL,AL
        JE      @@1
        CLR_    AH
@@1:    XCHG    AX,T
        RET
        
;^^^^^^--------------   IO  ---------------

 P_ _COD
        JMP     IP  
            
 P_ _CODRET
        POP     W
        XCHG    IP,W
        JMP     W   

MyCseg  ends
        end  Start

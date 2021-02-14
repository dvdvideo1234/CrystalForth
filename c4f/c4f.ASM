DBG = 1
INCLUDE C4F.IMC

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 100h

MADR    = -260          ;  MEMORY ADDRESS POINTER

Start   Label byte

@ABORT:
  MOV   RSP,PW @R_TOP
  MOV   DSP,PW @S_TOP
  CALL  @DEBUGOFF
  CALL  @RET
  DW    _INIT
@MAINLP:                  ; TEXT INTERPRETTER
  DW    _READLN,_EVAL
__@OK:
  DW  _OK
  DW _JUMP,@MAINLP

 ;vvvvvv--------------   IO  ---------------

L_ _AND
  DW _NAND,_NOT,_RET
  
L_ _XREADLN
  DW _XLDSTO,_NOP
L_ _READLN
  DW    _TBL,_TBL,_ACCEPT,_RET
  
L_ _SKIPROW  
  DW _BLK,_IF,_SLASHES
L_ _BACKSLASH  
  DW _LTIB,_DUP,_IF,@SLASH,_1M,_LIT,-64,_AND
@SLASH:
  DW TO_+_LTIB,_RET
L_ _SLASHES ;_REM  //
  DW 0,_PARS
L_ _2DROP  
  DW _DROP,_DROPX
  
L_ _STRENDZ
  DW _CSTR,_TBUF,_MAKESTR,_ALD,_OFF,_RET
  
L_ _FKEY
  DW _HTOP,_DOSkey,_RET
  
L_ _INCLUDE
  DW _TOKEN?
L_ _INCLUDED  
  DW _SKIPROW
L_ FEVAL
  DW _XLDSTI,_FKEY
  DW _STRENDZ,_1P,TO_+_HANDLES,_HANDLES ; CHK FOR PUSH
  DW _OPENR,_??,TO_+_HANDLES
@ALINE:
  DW _XREADLN,_EVAL,_TEOF,_LDZST,_IF,@ALINE
L_ _CLOSE1
  DW _HANDLES,_CLOSE,_RET
  
L_ _XLDSTO
  DW _GTEMIT,_XR,_PUSH,_RLDP,_STEMIT,_EX,_POP,_STEMIT,_RET
  
L_ _XLDSTI
  DW _GTKEY,_XR,_PUSH,_RLDP,_STKEY,_EX,_POP,_STKEY,_RET
  
L_ _STDEMIT
  DW _LIT,_BE,_STEMIT,_RET
L_ _STDKEY
  DW _LIT,_BK,_STKEY,_RET
  

VAR_ _TEOF,0
@TEOF = $-2

XT_ _LDZST,$+2
  CLR_  W
  XCHG  W,[T]
  JMP   @XCHG

XT_ _DOSkey,__PAR
  MOV   AH,3fh
  INC   CX
  POP   BX
  MOV   DX,OFFSET @LASTCH
  INT   21H
  XCHG  AX,CX
  JCXZ  @FEOF
  MOV   BX,DX
  MOV   AL,[BX]
  cmp   al,1Ah
  JNE   @FEOF1
@FEOF:  
  INC   PW  @TEOF
  MOV   AL,0DH
@FEOF1:  
  XCHG AX,BX
  JMP   @RAP2
@LASTCH  DB 0

__BOUND: ; __VAR LOWBOUND HIBOUND OF STACK
  CMP   T,[WA+4]
  JNBE  @EMPTY_ERR
  CMP   T,[WA+2]
  JNAE  @FULL_ERR
  JMPS_ @ADROP

__TO_PUSH:
  MOV   W,[WA+4]
  LEA   CX,[WA+6]
  CMP   CX,W
  JNB   @FULL_ERR
  XCHG  W,T
  DEC   T
  DEC   T
  MOV   [T],W
  MOV   [WA+4],T
@ADROP:  
  ADROP_

__TO_POP:
  MOV   W,[WA+2]
  CMP   W,[WA]
  JNB   @EMPTY_ERR
  XCHG  W,T
  INC   T
  INC   T
  MOV   PW [WA+2],T
  MOV   T,[T-2]
  XCHG  W,T
  ADUP_
  
@FULL_ERR:
  CALL  SHOW_ERR
  NAM_ "STACK FULL"
@EMPTY_ERR:
  CALL  SHOW_ERR
  NAM_ "STACK EMPTY"
SHOW_ERR: 
  POP   T
  CALL  @RET
  DW __@ERR ;  CALL ERROR - DOES NOT RETURN

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
  mov   AR,W
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
  cmp   W,AR
  jnc   @@ERNUM
  xchg  W,Bx
  mul   AR
  xchg  W,Bx
  add   Bx,W
  JCXZ  @@EXNUM
  JMP   @@GETC
@@ERNUM:
  INC   CX
@@EXNUM:
  pop   AR    ; rdrop
@@noEXn:
  RET

@@SGN:
  CMP   AL,'-'     ; SGN
  JNE   @@N1
  POP   AR
  CALL  @@END?
  CALL  AR
  NEG   bX
  RET

XT_ _CSTR,__1PDUP
  DEC   T
  JMPS_ @C@

@BS:
  CALL  @BS2
  MOV   AL,32
  CALL  @OEMIT
@BS2:
  MOV   AL,8
@OEMIT:
  CALL  @DUPT
  XCHG  W,T
  MOV   AX,OFFSET _EMIT
@IOZ:           ; NOP
  PUSH  IP CX WA AR AX
  CALL  @RET    ; TO FORTH
  DW    _POP,_EXECUTE,_FROMF ;ORTH
  POP   AR WA CX IP
  RET

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
  
XT_ _STM,__DROP
  XCHG   W,T
  MOV   [T-2],W
@2M:
  DEC   T
@1M:  
  DEC   T
  JMPS_ @NOP2

XT_ _STP,__DROP
  XCHG   W,T
  MOV   [T],W
@2P:
  INC   T
@1P:  
  INC   T
@NOP2:
  JMP   @NOP

XT_ _@DOES3,__POPIP
@4P:
  ADD   T,4
  JMP  @NOP

XT_ _@DOES,__POPIP
  JMPS_ @NOP2

XT_ _@DOES2,__POPIP
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

XT_ _MAKESTR,__PAR
  POP   DI AX SI
  MOV   cL,AL
  STOSB
  REP   MOVSB   ; NAME  MOVE
  MOV   [DSP],DI  ; AR SET
  JMPS_  @RAP2

XT_ _MPUSH,__PAR
  POP   DI CX SI
@MPUSH:  
  SUB   T,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  JMPS_  @RAP2
  
XT_ _ACCEPT,__PAR
  POP  SI DI
  PUSH DI
@ACC:
  CMP   CX,SI
  JE    @END
@AKEY:  
  MOV   AX,OFFSET _KEY
  CALL  @IOZ
  CALL  @DROPW
  CMP   AL,13
  JE    @END
  CMP   AL,10   ;DISCARD LF
  JE    @AKEY
  CMP   AL,8
  JNE   @BL?
  JCXZ   @ACC
  DEC   CX      ;DISCARD LAST CHAR
  DEC   DI
  CALL  @BS
  JMPS_ @ACC
@BL?:
  CMP   AL,' '
  JG    @ACHAR
  MOV   AL,' '
@ACHAR:
  STOSB         ; ADD CHAR
  INC   CX
  CALL  @OEMIT
  JMPS_ @ACC
  
XT_ _STRPUSH,__PAR
  POP   DI SI
  MOV   CL,[SI]
  INC   CX
  JMP   @MPUSH
  
XT_ _num,__PAR     ;= (>#       ; (NUM
  POP   CX SI
  MOV   T,10  ; base := 10
  CALL  @NUM@
  PUSH  BX
@AEND:  
  JMP   @END

XT_ _OPENR,__PAR
  MOV   AL,00H
  JMPS_ @OPENRW
  
XT_ _OPENW,__PAR
  MOV   AL,01H
  JMPS_ @OPENRW
  
XT_ _OPENRW,__PAR
  MOV   AL,02H
@OPENRW:  
  MOV   AH,3DH
  POP   DX
  INT   21H
  SBB   CX,CX
  PUSH  AX
  JMPS_ @AEND  

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

@HTOP:
  MOV   WA,[WA+8]
  MOV   W,[WA]
  JMP   @WPUSH
  
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

XT_ _OVER,__DUP
  MOV   T,[DSP+2]
  JMPS_ @NOP
__DBG:
  JMP     @DO_TRACE
		
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
  JMPS_   @NOP
	
@SDIV:          ; ( -/
  SHL     PW [DSP],1
  RCL     T,1
  CMP     T,AR
  JB      @NOP3
  SUB     T,AR        
@U1P:  
	INC     PW [DSP]
@NOP3:  
  JMP     @NOP
	
@PMUL:          ; ( +*
  TEST    PB [DSP],1
  JNZ     @D2DIV
  ADD     T,AR
@D2DIV:
  RCR     T,1
  RCR     PW [DSP],1
  JMPS_   @NOP3
		
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
      
XT_ _FROMF,@FROMF
@FROMF:
  JMP IP

ADR?_
INCLUDE C4F.IKR ; KERNEL
ADR?_

; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

XT_ _TROFF,@ACALL  
@DEBUGOFF:
  SKIPR_ W
  LODSW
  TEST  WL,1
  ORG   $-1
@DBG?:  
  XCHG  W,PW @NOP
  RET

@ACALL:  
  CALL    WA
  JMP     @NOP
  
@DO_TRACE:
  CALL  @DEBUGOFF
  MOV   AX,OFFSET _BE
  XCHG  AX,PW @EMIT
  PUSH  AX AR 
  CALL  @EX  
  DW    _CR,_PUSH,_PUSH,_PUSH,_ROTD,_POP,_POP,_POP,_ROTD
  DW  _H,_WDOT,_J,_WDOT
  DW    _RPLD,_WDOT,_SPLD,_2P,_WDOT
  DW  _SPC,_I,_WDOT,_I,_2P,_LD,_WDOT,_ILD,_WIDOT
;  BP_
;  BP_
;  BP_
;  BP_
  DW  _BK
  DW  _FROMF
  AND   T,0DFH
  CMP   T,'S'
  JE    @STOPDBG
  CALL  @DEBUGON
@STOPDBG:
  CALL  @DROPT
  POP   IP AR
  POP   PW @EMIT
  LODSW
  JMP   @TEST2
  
XT_ _TRON,@ACALL  
@DEBUGON:  
  SKIPR_ W
  JMPS_  $
  ORG $-1
  DB __DBG-(@NOP+2)
  JMPS_  @DBG?  
  
ALIGN_ 0
L_ _ILD
  DW _J,_LD,_RET

freemem:
  DW ENDMEM-FREEMEM-2
;    ENTRY_  _NOP,'NOP'
;    ENTRY_  _LIT,'(#'
;    ENTRY_  _RET,'(;'
;    ENTRY_  _ENTRY,'=:'
;    ENTRY_  _BYE,'BYE'
  INCLUDE C4F.INM
  DW 0,0
EndMem:

  DB ' DROP DROP DROP DROP DROP BYE GAMEL OT GARY  '


  
MyCseg  ends
        end  Start


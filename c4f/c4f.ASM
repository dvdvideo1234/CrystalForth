DBG = 0
INCLUDE C4F.IMC

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

@ABORT:
  MOV   RSP,@R_TOP-2
  MOV   DSP,@S_TOP-2
  CALL  @DBG
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
L_ _READLN
  DW    _TIB,_TBL,_ACCEPT,_RET
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
  DW _STRENDZ,_1P,TO_+_HANDLES,_HANDLES ; CHK FOR PUSH
  DW _OPENR,_??,TO_+_HANDLES
@ALINE:
  DW _READLN,_EVAL,_TEOF,_LDZST,_IF,@ALINE,_HANDLES,_CLOSE
L_ _ENDREAD  
  DW _POP,_POP
L_ _SETIO  
  DW _STEMIT,_STKEY,_RET
L_ _STDIO
  DW _LIT,_BK,_LIT,_BE,_JUMP,_SETIO
  

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
  CMP   SI,[DI]
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

XT_ _OPENR,__PARR
  DW    _DROP
  DW    _FKEY
  MOV   AL,00H
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
  
__PARR:
  MOV   AX,[WA]
  XCHG  AX,PW @EMIT
  PUSH  AX
  SCASW
__PARW:
  MOV   AX,[WA]
  XCHG  AX,PW @KEY
  PUSH  AX
  SCASW
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
@DBG:   
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
  
XT_ _swpstk,__PARXT
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
@TEST:  
  TEST    WL,1
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
  JMPS_ @TEST

XT_ _OVER,__DUP
  MOV   T,[DSP+2]
  JMPS_ @NOP
__DBG:
  JMP     @DBG
		
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
  JB      @NOP
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

XT_ _AND15,__AND
  DW 15
  
XT_ _CNTC,__VAR
  DW 0
    
;XT_ _U2SWAP,@U2SWAP
;L_ _2SWAP
;  DW _U2SWAP,_PUSH,_U2SWAP,_POP,_RET
  
; vvvvvvvvvv----------- MINI DEBUGGER -------------vvvvvvvvvvv

XT_ _BYE,0
P_ _LIT,@LIT           ; ( DUP
P_ _PUSHX,@PUSHX            ; (PUSH;
P_ _C@,@C@
P_ _HWTOB,@HWTOB
P_ _WTOB,@WTOB
P_ _SKIP,@SKIP		      ; (SKIP
P_ _ROT,@ROT
P_ _MROT,@MROT
P_ _SWAP,@SWAP
P_ _D2DIV,@D2DIV
P_ _NEG,@NEG
P_ _NOT,@NOT
P_ _0LESS,@0LESS
P_ _ZEQ,@ZEQ
P_ _MIF	,@MIF
P_ _2DIV,@2DIV          ; ( 2/
P_ _NEXT,@NEXT          ; (NEXT
P_ _DROPX,@DROPX        ; (DROP;
P_ _NOP,@NOP        
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
   
;----------------------------------	

P_ _IFM,@IFM2           ; (IF-        
P_ _JUMP,@JUMP          ; (JUMP
;P_ _IF,@IF              ; (IF
P_ _RET,@RET            ; ( (;

P_ _PLAVG,@PLAVG				; ( +2/
P_ _SDIV,@SDIV          ; ( -/
P_ _PMUL,@PMUL          ; ( +*
;P_ _nAND,@NAND	        ; ( NAND

P_ _PUSH,@PUSH          ; (PUSH
;P_ _POP,@POP            ; ( POP
;P_ _J,@_DUP            ; ( J
;P_ _DUP,@_DUP          ; ( DUP

;P_ _RLDP,@_DUP         ; (@R+
P_ _XR,@XR           ; ( XR  XCHG
P_ _XA,@XA

P_ _STKEY,__SETVAR
P_ _GTKEY,__CONST
L_ _KEY
@KEY  DW _BK,_RET
  
P_ _STEMIT,__SETVAR
P_ _GTEMIT,__CONST
L_ _EMIT
@EMIT  DW _BE,_CNTC,_INC,_RET
  
L_ _TRICE
  DW _PUSH,_J,_XR
L_ _IXEC
  DW _J,_PUSH
L_ _EXECUTE
  DW _PUSHX

L_ _XSPC
  DW _EX
L_ _SPC
  DW _BL,_JUMP,_EMIT
P_ _BL,__CONST
  DW 32

L_ _3ROTD
  DW _XSPC,_ROTDOT,_ROTDOT
L_ _ROTDOT
  DW _ROT,_DUP
L_ _WDOTSPC
  DW _XSPC 
L_ _WDOT
  DW _DUP,_HWTOB,_BDOT
L_ _BDOT
  DW _DUP,_2DIV,_2DIV,_2DIV,_2DIV,_HDOT
L_ _HDOT  
  DW _AND15,_ALPHA,_EMIT,_RET
  
;L_ _I
;  DW _J,_RET
;  
;  
;L_ _BRK
;  DW _I,_WDOTSPC,_RPLD,_WDOTSPC,_SPLD,_WDOTSPC
;  DW _ALD,_WDOTSPC,_SPC,_SPC,_3ROTD,_BP,_RET

ADR?_
INCLUDE C4F.IKR ; KERNEL
ADR?_

  DW __VAR3,__TO_PUSH
XT_ _FORWARDS,__TO_POP
  DW @@1,@@1,20 DUP (0)
@@1:  
  DW __VAR3,__TO_PUSH
XT_ _BACKWARDS,__TO_POP
  DW @@2,@@2,20 DUP (0)
@@2:  
XT_ _HTOP,@HTOP
  DW __VAR3,__TO_PUSH
XT_ _HANDLES,__TO_POP
  DW @@3,@@3,20 DUP (0)
@@3:  

L_ _ABORT_INI
  DW AT_+_FORWARDS,_STKINI
  DW AT_+_BACKWARDS,_STKINI
  DW _CLOSE_ALL,_STDIO
L_ _HANDLES_INI
  DW AT_+_HANDLES
L_ _STKINI
  DW _STR
L_ _SWAPST  
  DW _SWAP
L_ _ST  
  DW _STP,_DROPX
  
L_ _SHOW_ERR
  DW _TBUF,_ID,_ID
L_ _CR
    DW _SDOT
    DB 2,13,10,0
    DW _CNTC
L_ _OFF
    DW _LDZST,_DROPX
    
L_ _DLD
  DW _LDP,_XDROP
L_ _LDP
  DW _PUSH,_RLDP,_POP,_RET
L_ _STKSIZE
  DW _DLD,_SUB,_2DIV,_RET
  
L_ _CLOSE_ALL
  DW AT_+_HANDLES,_2P,_LD,_XDROP   ; ADRES
  DW AT_+_HANDLES,_STKSIZE
  DW _TIMES,_STR,_CLOSE,_RET

L_ _XDROP
  DW _EX,_DROPX

L_ _TIMES
        DW _FOR,@@LPS
@@LPS0  DW _J,_EXECUTE
@@LPS   DW _NEXT,@@LPS0
__@EXT2 DW _RDROP
__@EXIT DW _RDROPX

L_ _0X 
  DW _IF,__@EXIT,_RET

L_    _SDOT
  DW _SLSKIP
L_ _TYPES
  DW _CSTR
L_ _TYPE
  DW _XDROP
L_ _ATP
    DW _TIMES,_CSTR,_EMIT,_RET

L_ _OK
    DW _SDOT
    NAM_ ' Ok'
    DW _CR
    DW _SDOT
    NAM_ '>'
    DW _RET
    
L_ _ID
    DW _XSPC,_TYPES,_RET
    
freemem:
  DW ENDMEM-FREEMEM-2
    ENTRY_  _ENTRY,'=:'
  DW 0,0
EndMem:


  
MyCseg  ends
        end  Start


; :TODO
; 1 DEBUGGER
; 2 UNIT TESTS FOR EVERY PRIMITIVE
; 3 DESA ASEMBLER DESASEMBLER
; 4 MODULED TARGET COMPILATION

TO_   = -2
AT_   = -4
VAL_  = 2

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

Z?  MACRO   REG
  OR    REG,REG
ENDM

JMPS    MACRO LBL
  jmp   SHORT LBL
ENDM

SKIPA   MACRO
  DB    03DH
ENDM

SKIPB   MACRO
  DB    03CH
ENDM

SKIPR   MACRO reg
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

TO_R    MACRO  REG
  PUSH   REG
ENDM

R_TO    MACRO  REG
  POP    REG
ENDM

TO_D    MACRO  REG
  X
  PUSH   REG
  X
ENDM

D_TO    MACRO  REG
  X
  POP    REG
  X
ENDM

DROP_   macro   
  LODSW
endm

SWAP_   macro   
  XCHG  TOP,NXT
endm

PUSHR_  MACRO REG
  DEC   DSP
  DEC   DSP
  MOV   [DSP],REG
ENDM  

POPR_   macro   reg
  xchg  ax,reg
  DROP_
endm

CLR     macro   reg
  XOR   reg,reg
endm

TWICE_  MACRO
  DW $+2
ENDM

ALIGN_  MACRO
  IF ($-START) AND 1
  NOP
  ENDIF
ENDM

P_  MACRO NAM
  ALIGN_  0
  NOP
NAM:
  org   $-1
ENDM

L_      MACRO NAM
  ALIGN_  0
NAM:
ENDM

nam_    macro   msg
  local endstr
  db    endstr-$-1
  db    msg
endstr  label   byte
        endm

DEFER_ MACRO NAM,VAL
L_ NAM  
  DW _JUMP,VAL
ENDM


VECTOR_ MACRO NAM,VAL
  ALIGN_ 0
  DW __SET2
  DEFER_ NAM,VAL
ENDM

DOER_ MACRO NAM2,VAL
  ALIGN_ 0
  DW __pntSET
  DEFER_ NAM2,VAL
ENDM

CONST_ MACRO NAM,VAL
L_ NAM  
  DW __CON,VAL
ENDM


VALUE_ MACRO NAM,VAL
  ALIGN_ 0
  DW __SET2
  CONST_ NAM,VAL
ENDM

BUF_ MACRO ADR,LEN
  MADR = MADR - (LEN)
  ADR  = MADR
ENDM
 
; REGISTER usage
ip  = BX  ; BX INSTRUCTION POINTER
dsp = SI  ; SI DATA STACK POINTER
rsp = sp  ; SP RETURN STACK POINTER
top = Ax  ; AX DATA STACK TOP REGISTER
NXT   EQU PW [DSP]
topL= AL  ; AX DATA STACK TOP REGISTER
topH= AH  ; AX DATA STACK TOP REGISTER
w   = di  ; DI WORK REGISTER
ar  = DX  ; DX ARITHMETIC ( ADDRESS ) register 
DR  = CX  ; CX DATA REGISTER
DRL = CL  ; CX DATA REGISTER
DRH = CH  ; CX DATA REGISTER


; MINIMAL SET INTERPRETTER COMMANDS
; CONTROL      COMMANDS  (IF (JUMP (RETURN (IF-  ;(IO
; RETURN STACK COMMANDS  POP PUSH 
; DATA STACK   COMMANDS  DUP J
; DATA TRANSF  COMMANDS  @R+ !R+ XCHG XR
; MATH         COMMANDS  +2/ +* -/ NAND

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

MADR = 65535-15 ;

        org 100h

BUF_ _@TIB,66        ;   82
BUF_ _@FIB,66        ;   66
BUF_ _@BCK,40        ;   40
BUF_ _@FWD,50        ;   50
BUF_ _@FLS,40        ;   40
BUF_ _@TBUF,258      ;  256
BUF_ _@R_TOP,40      ;  512 B FSTACK
BUF_ _@R_BTM,512     ;  512 B FSTACK
BUF_ _@S_TOP,16      ;  512 B DSTACK
BUF_ _@S_BTM,512     ;  512 B DSTACK
BUF_ _@MACTOP,16     ; 4096 B = 4 BUFFERS * 1024 B
BUF_ _@MACADR,2464   ; 4096 B = 4 BUFFERS * 1024 B
BUF_ _@VOCTOP,4096   ; 4096 B = 4 BUFFERS * 1024 B

        org 100h

_BYE   = 1

Start  Label byte   
L_ _START
  mov   ah,4ah     
  mov   bx,1000h          ; only 64k allocate
  int   21h
P_ _ABORT
  CALL  @NO_TRACE
  MOV   RSP,_@R_TOP
  MOV   DSP,_@S_TOP
  CALL  @4TH
  DW    _BYE              ; H>T  STARTUP ADDRESS
@QUIT DW _BYE,_BYE        ; EVAL vOK 
_QUIT DW _BYE,_JUMP,@QUIT ; READLN @QUIT
  DW    0 
_HIATOI DW 0              ; HI RESULT OF ATOI

; CONTROL      COMMANDS  ----------------------------
         
P_ _PAR
  JMPS  @PAR

;-----------------------
;      searching
;-----------------------

L_ _FND
  DW  _PAR
  CALL  @METHOD
  repe  cmpsb
  RET

L_ _WFND
  DW  _PAR
  CALL  @METHOD
  CMP   SI,[DI-4]
@NO_TRACE:
  RET

@PAR:
  PUSH  AR BP
  MOV   BP,RSP
  X
  PUSH  TOP
  XOR   CX,CX
P_ _FROMF
  JMP   IP

;----------------   NUMBERS  ---------------------

@@ADR   = BX
@@ACC   = DI
@@IND   = SI
@@BASE  = CX
@@OPADR = DX  ; OPTION ADDRESS
@@AR    = BP
  
COMOPT  DW @@KOLI,@@TICK,@@DIEZ,@@HEX,@@BIN
;OPTAB   DB "^'#$%"
OPTAB   DB "%$#'^"

@@SGN:
  INC     @@IND                 ; ZERO LEN
  JZ      @@ERNUM
  CMP     pb [@@ADR+@@IND],'-'  ; SGN?
  jne     @@EXSGN
  INC     @@IND                 ; SKIP '-'
  JZ      @@ERNUM               ; LAST CHAR ?
  POP     @@OPADR
  CALL    @@OPADR         ; return to caller
@@DNEG:  
  ;NEG    @@acc
  not     @@acc
  not     @@AR
  inc     @@acc
  jne     @@EXSGN
  inc     @@AR
@@EXSGN: 
  RET

@@ERNUM:    
  DEC     @@IND
@@STATE:    
  pop     @@OPADR    ; rdrop
  RET
  
@@DIEZ: 
  XCHG    @@acc,AX
  
@@numini:   
  CLR     @@acc      ; ZEROING ACCUMULATOR
  CLR     @@AR        ; HI PART ACCUMULATOR
  SKIPA
@@HEX:
  MOV     AL,16
  SKIPA
@@OCT:
  MOV     AL,8
  SKIPA
@@BIN:
  MOV     AL,2
@@setbasE:  
  DEC     AX
  DEC     AX
  xor     ah,ah
  mov     @@base,ax
  INC     @@base
  INC     @@base
@@NORMAL?:
  CALL    @@STATE
  
@@N16:  
  PUSH    DI
  MOV     DI, OFFSET OPTAB
  PUSH    CX
  MOV     CX,6
  REPNE   SCASB
  MOV     DI,CX
  POP     CX
  JNE     @@N5  
  SHL     DI,1
  MOV     @@OPADR,COMOPT[DI]
  POP     DI
  INC     @@IND
  JZ      @@ERNUM
  DEC     @@IND
  JMP     @@OPADR
  
@@N5:   
  POP     DI 
  cmp     al,'9'+1
  jc      @@ton2
  cmp     al,'A'      ; no case sensivity
  jc      @@ERNUM
  sub     al,7
@@ton2: 
  sub     al,'0'
  jc      @@ERNUM
  cmp     ax,@@base
  jnc     @@ERNUM
@@ACCUM:    
  Xchg    @@AR,AX
  mul     @@base
  Xchg    @@AR,AX
  Xchg    @@acc,AX
  mul     @@base
  Xchg    @@acc,AX
  add     @@acc,ax
  ADC     @@AR,DX
  JMPS    @@NORMAL?
  
@@TICK:  
  CALL    @@STATE
  JMPS    @@ACCUM
@@KOLI: 
  CALL    @@STATE
  AND     AL,31
  JMPS    @@ACCUM
  
@@ATOI:
  MOV     AL,10       ; BASE 10 INITIALLY
  CALL    @@SGN
  CALL    @@numini
@@GETC: 
  MOV     AL,[@@ADR+@@IND]
  CALL    @@OPADR
  INC     @@IND
  JNZ     @@GETC
  RET

L_ _ATOI
  DW  _PAR
  POP     @@IND @@ADR
  PUSH    @@AR 
  LEA     @@ADR,[@@ADR+@@IND]
  NOT     @@IND
  CALL    @@ATOI
  MOV     _HIATOI,@@AR
  POP     @@AR
  PUSH    @@ACC @@IND
  JMPS    @PARX
  
L_ _MPUSH ; TOP OF DICTIONARY   IN DI
  DW _PAR
  POP   DI CX AX
  PUSH  CX 
  XCHG    AX,SI
  ADD     SI,CX       ; AFTER NAME ADDRESS
  STD                 ; BACKWARDS
  CMPSB               ; PREPARE FOR DIRECTION
  REP     MOVSB       ; NAME (MEMORY) MOVE
  CLD
  XCHG    AX,SI
  INC     DI
  PUSH    DI
@PARX:
  MOV   DSP,BP
  X
  POP   BP DX
  JMP   @DROPX

 L_ _PARS
  DW  _PAR 
  POP     DI CX AX
  JCXZ    @@SKIPX
  CMP     AL,' '
  JNE     @@SKIPX
  REPE    SCASB
  JE      @@SKIPX
  DEC     DI
  INC     CX
@@SKIPX:
  MOV     DX,DI  ;  START OF THE SOURCE
  PUSH    DI
  JCXZ    @@WEX        
  REPNE   SCASB        
  JNE     @@WEX        
  DEC     DI           
@@WEX:                ; END OF THE SOURCE  IN DI
  SUB     DI,DX   ; LENGTH OF THE WORD
  PUSH    DI CX
  JMP     @PARX
   
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
  JMP     @PARX
 
;L_ _TRON
;  DW  _IO
;@DO_TRACE:
;  SKIPR DR
;  DB 0EBH,@dbg-@MAIN2
;@X_TRACE:
;  XCHG  DR,PW @MAIN
;  RET
;    
;P_ _TROFF
;  CALL  @IO
;@NO_TRACE:
;  SKIPR DR
;  MOV   DR,[IP]
;  JMPS  @X_TRACE
;  
;P_ _LP 
;  PUSHR_  TOP
;  MOV   TOP,1
;  POP   CX DI
;@LP0:  ; XR POP POP I- +2/ 0<   IF
;  SUB   CX,DI
;  ADD   TOP,CX
;  JNC   @LP3 ;  DROP RDROP 2+ PUSH; 
;@LP1:  
;  DROP_
;  JMPS  @SKIP
;
;P_ _ADD_LP
;  POP   CX DI
;  Z?    TOP ; (-IF `(+LP
;  JNS   @LP0
;  NEG   TOP ;NEG XR POP J POP -
;  SUB   CX,DI
;  NEG   CX
;  ADD   TOP,CX ; 0< (IF `(-LP `(LP; ;
;  JC    @LP1
;  NEG   TOP
;@LP3:   ; NEG  THEN I+ PUSH @ PUSH;
;  ADD   TOP,DI
;  PUSH  DI
;  JMP   @PUSH
;   
P_ _MDIV                  ; -/ DIVIDE PRIMITIVE
  SHL     NXT,1     ; SHIFT LEFT NEXT TO CARRY
  RCL   TOP,1         ; ROTATE LEFT WITH CARRY
  CMP   TOP,ar      ; COMPARE TOP WITH AR
  JB      @MDIV       ; IF BELOW SUBTRACT IS NOT POSSIBLE
  SUB   TOP,ar      ; SUBTRACT SAR FROM TOP
P_ _U1P  
  INC     NXT         ; SUCSESSFULL SUBTRACT
@MDIV:  
  JMPS  @MAIN
   
P_ _PMUL                  ; +* MULTIPLY PRIMITIVE
  TEST  NXT,1     ; TEST LEAST SIGNIFICANT BIT
  JE    @PMUL2      ; IF CLEAR - NOT ADD
  ADD   TOP,ar      ; ADDING SAR TO TOP
P_ _D2DIV  
@PMUL2:
  RCR   TOP,1         ; JUST SHIFT RIGHT TOP WITH CARRY
  RCR   NXT,1     ; SHIFT RIGHT NEXT WITH CARRY
  JMPS  @MAIN

P_ _DUPUSH
  PUSH  TOP
  SKIPA
P_ _ALP
  ADD   NXT,TOP
  JMPS  @MAIN
  
P_ _DROPOP
  POP   TOP
  SKIPA
P_ _ALM
  SUB   NXT,TOP
  JMPS  @MAIN
  
;P_ _SKIP?
;  Z?    TOP 
;  JNE   @MAIN
;  INC   TOP 
P_ _IF              ; (IF
  Z?    TOP  
  DROP_
  JE    @JUMP 
P_ _SKIP
@SKIP:
  INC   ip
  INC   ip
  JMPS  @MAIN

P_ _IFM             ; (IF- TROFF
  JMPS  @IFM
P_ _NEXT            ; (NEXT
  POP   dr
  DEC   dr
  PUSH  dr
  SKIPR DR
P_ _MIF             ; (IF- TROFF
  INC   TOP         ; INCREMENT TOP AND BRANCH ON POSITIVE 
@IFM:               ; (IF- TROFF
  DEC   TOP         ; DECREMENT TOP AND BRANCH ON POSITIVE 
  JS    @SKIP       ; ON NEGATIVE - SKIP BRANCH
P_ _JUMP            ; (JUMP
@JUMP:
  MOV   IP,[IP] ; JUST BRANCH
  JMPS  @MAIN
  
  
P_ _QARY
  SHL   TOP,1
P_ _LARY
  SHL   TOP,1
P_ _WARY
  SHL   TOP,1
P_ _BARY
  ADD   TOP,IP
  JMPS  @4TH

P_ _POPX
  R_TO  DR
  R_TO  IP
  JMPS  @DRPUSH
  
; DATA TRANSFER  COMMANDS -----------------------------------

P_ _RSTPB             ; !R+
  R_TO  W             ; USE RETURN TOP AS DATA ADDRESS
  STOSB
  JMPS  @WSAVE

;P_ _DOLP  
;  XCHG  TOP,W
;  DROP_
;  TO_R  TOP
;  SKIPA
  
P_ _RSTP              ; !R+
  R_TO  W             ; USE RETURN TOP AS DATA ADDRESS
  STOSW
@WSAVE:
  TO_R  W
  DROP_
  JMPS  @MAIN       ; FETCH NEXT DATA TO TOP

P_ _RSTMB             ; !R+
  R_TO  W             ; USE RETURN TOP AS DATA ADDRESS
  DEC   W
  MOV   [W],TOPL
  JMPS  @WSAVE

P_ _RSTM              ; !R+
  R_TO  W             ; USE RETURN TOP AS DATA ADDRESS
  DEC   W
  DEC   W
  MOV   [W],TOP
  JMPS  @WSAVE

@DBG:   
  JMP   @NO_TRACE

P_ _RLDPB             ; @R+
  R_TO  W             ; TAKE TOP OF THE RETURN STACK
  CLR   DR
  MOV   DRL,[W]  ; USE RETURN TOP AS DATA ADDRESS
  INC   W             ; INCREMENT ADDRESS
  JMPS  @DUPW

P_ _RLDP              ; @R+
  R_TO  W             ; TAKE TOP OF THE RETURN STACK
  MOV   DR,[W]        ; USE RETURN TOP AS DATA ADDRESS
  SCASW               ; INCREMENT ADDRESS
@DUPW:  
  TO_R  W             ; STORE ADDRESS BACK TO RETURN STACK
@DRPUSH:  
  PUSHR_    TOP       ; DUPLICATE DATA TOP REGISTER
@XCHG:  
  XCHG  TOP,DR
  SKIPA
@RDRPX:
  POP   DR

; MAIN  LOOP  ---------------------------------------
 
P_ _RET
@4TH:
  r_to  IP          ; POP IP FROM RETURN TOP ELEMENT  
@MAIN:
  ;JMPS @DBG
  MOV   DR,[IP]
@MAIN2:  
  INC   IP
  INC   IP
@MAIN3:  
  test  DRL,1       ; ADDRESS ODD ?
  je    @nest       ; NOT ODD ADDRESS - NEST THEN
  dec   DR          ; MAKE ODD ADDRESS EVEN
  JMP   DR          ; BRANCH TO PRIMITIVE

P_ _EX
_@JSR4TH:
  R_TO  DR
@NEST:                ; (NEST
  to_r  IP          ; PUSH OLD IP
  to_r  DR       ; PUSH NEW IP
  JMPS  @4TH
  
; IO COMMANDS vvvvvvvvvv  ---------------------------

P_ _RDRPX      
  JMPS  @RDRPX
P_ _PLUS@X
  ADD   TOP,[IP]
  JMPS  @4TH  
  
P_ _@ADD
  MOV   W,NXT
  ADD   [W],TOP
P_ _2DROP
  DROP_
  DROP_
  JMP   @MAIN
  
P_ _XR                ; XCHG
  R_TO  DR          ; EXCHANGE TOP ELEMENTS
  TO_R  TOP         ; OF TWO STACKS
  JMPS  @XCHG 
  
P_ _XA                ; XA
  R_TO  W             ; EXCHANGE RETURN TOP ELEMENT
  TO_R  ar          ; 
  MOV   ar,W          ; WITH ADDED REGISTER
P_ _NOP
  JMPS  @MAIN 

P_ _@EXEC
  MOV   W,TOP
  MOV   TOP,[W]
P_ _EXEC
  XCHG  TOP,DR
  DROP_
  JMPS  @MAIN3
  
;P_ _MROT
;  XCHG  TOP,NXT+2
;P_ _SWAP
;  SWAP_
;  JMPS  @MAIN

P_ _PUSHX
  TO_R  TOP
P_ _DROPX  
@DROPX:   
  DROP_
  skipa
P_ _AND@X
  AND   TOP,[IP]
  JMPS  @4TH  
  
P_ _BEMIT
  MOV     AH,0EH
  INT     10H

; IO           COMMANDS  (IO  ^^^^^^^

;  STACK COMMANDS   --------------------------------

P_ _DROP               ; DROP TOP
  JMPS    @DROP
        
P_ _FOR
   MOV   IP,[IP]
P_ _PUSH                ; PUSH
@PUSH:
  TO_R  TOP
@DROP:
  DROP_
  JMPS  @MAIN

P_ _J                 ; J - DATA FROM SECOND ELEMENT OF RETURN STACK
  R_TO  W           ; POP W FROM RETURN
  R_TO  DR      ; POP TOP FROM RETURN  - SECOND ELEMENT
  TO_R  DR      ; PUSH TOP
  TO_R  W           ; PUSH W - STATE OF RETURN STACK IS 
  JMPS  @DRPUSH    ;          LIKE BEFORE OPERATION
  
P_ _ARP             ; A@
  TO_R  AR
  SKIPB
P_ _RSTKP           ; RSTACK PTR
  TO_R  RSP
  SKIPB
P_ _STKP            ; STACK PTR
  TO_R  DSP
  SKIPB
P_ _DUP             ; DUPLICATE TOP
  TO_R  TOP     ; PUSH TOP TO RETURN STACK
@POP:  
  R_TO  DR      ; - THIS WAY WE ACHIVE DUPLICATE OF TOP
  JMPS  @DRPUSH        
  
P_ _OVER
  TO_R  NXT  
P_ _POP             ; POP 
  JMPS  @POP
     
; MATH, LOGIC AND SHIFT COMMANDS   +2/ +* -/ NAND

P_ _ULESS
  SUB   NXT,TOP
  DROP_
  SKIPR  CX
  
P_ _0LESS
  SHL   TOP,1
  SBB   TOP,TOP
  JMPS  @MAIN
  
P_ _P2DIV               ; +2/ SUM AND SHIFT PRIMITIVE
  ADD   NXT,TOP     ; NEXT := NEXT + TOP;
  MOV     TOP,NXT       ; PREPARE FOR SHIFT
P_ _2DIV  
  RCR   TOP,1         ; SHIFT RIGHT TOP WITH CARRY
  JMPS  @MAIN
   
P_ _NAND                  ; NAND - LOGICAL PRIMITIVE
  AND   NXT,TOP   ; AND TO SECOND DATA ELEMENT - NEXT
  DROP_
@NOT:
  INC   TOP
P_ _NEG  
  NEG   TOP             ; NOT  2  1 & 2 => NAND
  JMPS  @MAIN
P_ _XOR               ; XOR - LOGICAL PRIMITIVE
  XOR     TOP,NXT
P_ _NIP
  INC     DSP
  INC     DSP
  JMPS    @MAIN
  
P_ _ZEQ
  NEG   TOP
  SBB   TOP,TOP
P_ _NOT
  JMPS  @NOT
   
; 
;L_ @DBGW0
;  CALL  @NO_TRACE
;  call  _@JSR4TH
;  DW _JUMP
;_@DBGW1:        ; show stacks / address, code, nextcode & name  
;  DW    0       ;DW @SV_EMIT,TO_+@EMIT
;  dw   _FROMF   ;_BKEY,
;  and   al,0dfh
;  cmp   al,'S'
;  DROP_
;  je    @@2
;  CALL  @DO_TRACE
;@@2:   
;  DROP_
;  POP   iP
;  MOV   DR,[IP] 
;  jmp   @MAIN2
;
;P_ _IO                    ; IF INPUT PARAMS = OUTPUT PARAMS 
;  PUSH  IP
;@IO:  
;  POP   W  ;  INT 3
;  CALL  W
;  JMP   @4TH

MyCseg  ends
        end  Start

;P_ _BRK 
;  INT 3
;  JMPS  @MAIN

;P_ _4TH
;  JMP  IP
  

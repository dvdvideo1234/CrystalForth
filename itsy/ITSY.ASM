
INCLUDE ITSY.IMC

DTOP = 10000  ;- 1A44H
DPTR = DTOP

LISTGEN = 01
DBG_FLAG= 01
DBG_ON  = 0;1

IF LISTGEN
   DIVE EQU ENTRYB
ELSE 
   DIVE EQU DUCK
ENDIF

; REGISTER usage
top = Bx  ; AX DATA STACK TOP REGISTER
ip  = SI  ; BX INSTRUCTION POINTER
dsp = BP  ; SI DATA STACK POINTER
rsp = sp  ; SP RETURN STACK POINTER
NXT   EQU PW [DSP]
topL= BL  ; AX DATA STACK TOP REGISTER
topH= BH  ; AX DATA STACK TOP REGISTER
wA  = di  ; DI WORK REGISTER
W   = AX
WL  = AL
WH  = AH
ar  = DX  ; DX ARITHMETIC ( ADDRESS ) register 



MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

MADR = 65535-15 ;

        org 0100h

BUF_  @FLS,2        ;   16 B FILE STACK  OF INCLUDE FILES
BUF_  @TIB,64       ;   64 B TEXT INPUT BUFFER
BUF_  @FIB,64       ;   64 B FILE INPUT BUFFER
BUF_  @FOB,64       ;   64 B FILE OUTPUT BUFFER
BUF_  _@BCK,20      ;   22 B BACKWORD STACK FOR BRANCHES
BUF_  _@FWD,20      ;   22 B FOREWORD STACK FOR BRANCHES
BUF_  @TBUF,256     ;  256 B TEXT BUFFER 
BUF_  @R_TOP,6
BUF_  @R_BTM,512    ;  512 B RSTACK
BUF_  @D_TOP,0
BUF_  @D_BTM,512    ;  512 B DSTACK
BUF_  _@MACTOP,0
BUF_ _@MACADR,2560  ; 2560 B = MACROSES
BUF_ _@VOCTOP,4096  ; 4096 B = 4 BUFFERS * 1024 B IO


Start   Label byte

IF LISTGEN
  ENTRYB '',Start0
ENDIF

; -------------------
; Initialisation
; -------------------

  jmp  @reset

PRIM 'R@+',_RLDP,@JPDUP
  POP   WA
  MOV   TOP,[WA]
@RINC2:
  SCASW
  PUSH  WA
  Jmp   NEXT
  
PRIM 'R@-',_RLDM,@JPDUP
  POP   WA
  MOV   TOP,[WA-2]
    JJ @RDEC2
  
PRIM 'R!-',_RSTM,@JPDROP
  POP   WA
  MOV   [WA-2],W
@RDEC2:
  DEC   WA
@RDEC1:
  DEC   WA
  PUSH  WA
  Jmp   NEXT
  
PRIM 'R!+',_RSTP,@JPDROP
  POP   WA
  STOSW
  PUSH  WA
  Jmp   NEXT
  
PRIM 'CR!-',_CRSTM,@JPDROP
  POP   WA
  MOV   [WA-1],WL
    J @RDEC1
  
PRIM 'CR!+',_CRSTP,@JPDROP
  POP   WA
  STOSB
  PUSH  WA
  Jj @NEXT1
  
DOSETP:
  MOV [WA+2],IP
doRET:
  POP   IP
@next1:           ; 11A
  JMP   NEXT
  
doGETP:   
  PUSH IP
doGETADR:
  MOV  IP,[WA]
  Jj @next1

prim '0;',_0RET,@JPDROP
  JE  DORET
    j @next1

@HERE:
  MOV   W,[WA]
  MOV   WA,[WA+2]
  ADD   W,[WA]
  JMP   DOPUSHW

prim 'ABORT',_abort,@ABORT

; -------------------
; Variables &  constantS
; -------------------

        VECTOR 'TEXT>',_TEXT_IN,_INI

        vaLUe 'DICT',_DICT,_@VOCTOP
        
        vaLUe '#tib',_LTIB,0

          DW DOVAR-2
        VECTOR 'EMIT',_EMIT,_Bemit

          DW DOVAR-2
        VECTOR 'KEY',_KEY,_BKEY

          DW DOVAR-2
        POINT 'LOCATE',_LOCATE,@LOCINI

        constant '0',_0,0

        vaLUe '>IN',_ETIB,0

        vaLUe '"STAT',_STATE,0

        vaLUe 'BASE',_base,10

        PRIM 'UN,',_UNcomma,@STK2ATD
        PRIM ',',_comma,@STK2TOU
        VARIABLE 'DP',_dp,ENDADR
            DW 100H,_@MACTOP

          DW DOVAR-2
        PRIM 'DP+',_DPP,DOCONST-1
        PRIM 'HERE',_HERE,@HERE
          DW 0,VAL_+_DP    ;DP+

        constant 'TIB',_tib,@TIB

        constant 'FIB',_Fib,@Fib

        constant 'TBUF',_TBUF,@TBUF

        constant 'BL',_BL,' '

; ^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Variables &  constantS
; -------------------

; -----------------------------
; DEBUG WORDS
; ------------------------------
 
@BP   EQU PW [DSP+00]
@SP   EQU @BP  + 2
@DI   EQU @SP  + 2
@SI   EQU @DI  + 2
@CX   EQU @SI  + 2
@BX   EQU @CX  + 2
@AX   EQU @BX  + 2
@FL   EQU @AX  + 2
@DX   EQU @FL  + 2
@RA   EQU @DX  + 2  ; RETURN ADDRESS
@TOP  EQU @RA  + 2

@SAVEREGS:
  POP   DX ;16
  PUSHF ;14 12 10  8  6  4  2  0
  PUSH      AX BX CX SI DI SP BP
  JMP   DX
  
@LOADREGS:
  POP   DX BP DI DI SI CX BX AX
  POPF
  JMP   DX

;PRIM '(EMT',_EMT,@DRCALL
@EMIT:
  PUSH  DX
  CALL @SAVEREGS
  PUSH  AX
  CALL  DORET
  DW _POP,_EMIT,_4TH
@POPREGSZ:
  CALL  @LOADREGS
  POP   DX
  RET
  
;PRIM '(KEY',_KE,@CALLPH
@KEY:   
  PUSH  DX
  CALL @SAVEREGS
  CALL  DORET
  DW _KEY,_PUSH,_4TH
  POP   AX
  MOV   BP,SP
  MOV   @AX,AX
    J @POPREGSZ
  
@SEARCH2:
; INPUT: AX:=[ADDRESS_TO_SEARCH]
; OUTPUT: 
;    ON ZF=0 FOUND      AX:=NAME
;    ON ZF=1 NOT_FOUND  DI:=AX+2
; USED REGS: AX CX DI

  MOV   DI,PW [VAL_+_DICT]
  XOR   CX,CX
  SKIPB
@@IDLP:  
  SCASW
  ADD   DI,CX
  MOV   CL,[DI+4]
  JCXZ  @IDLPX
  INC   CX
  SCASW
  JNE    @@IDLP
@@ID:
  SCASW
  XCHG  AX,DI
  SKIPA
@IDLPX:
  MOV   DI,AX
  SCASW
  OR    CX,CX
  RET
  
@PREFIXTO:
  CALL  @PREFIX
  MAKESTR 'TO'
@PREFIXAT:
  CALL  @PREFIX
  MAKESTR 'AT'  
@PREFIXCLN:
  CALL  @PREFIX
  MAKESTR ':'  ; COLON DEFINITION

PRIM 'LBL?.',_LBL?,@DRCALL
@LBLID:
  CALL  @SEARCH2
  JNZ    @PREFIXCLN
@NOLBL:
  RET
@PREFIX:
  POP   DI
  PUSH  AX
  XCHG  AX,DI
  CALL  @NOPREFIX
  POP   AX
@NOPREFIX:  
  CALL  @SHOWSTR
  JJ @SPDOT

PRIM 'ID.',_IDOT,@DRCALL
  J @NOPREFIX
  
PRIM 'ID?.',_ID?,@DRCALL
@STRID:
  CALL  @SEARCH2
    JNZ    @NOPREFIX
  XCHG  AX,DI   ;AX+=2
  CALL  @SEARCH2
    JNZ    @PREFIXTO
  XCHG  AX,DI   ;AX+=2
  CALL  @SEARCH2
    JNZ    @PREFIXAT
  ADD   AX,-4
@HDOT2:  
  JMP    @HDOT
  
PRIM 'H.',_HDOT,@DRCALL
@HDOT:
  CALL  @WORDOUT
  JJ @SPDOT
  
PRIM 'SPC',_SPC,@CALL
@SPDOT:  
  MOV   AL,' '
  JMP   @COUT
    
@WORDOUT:
  CALL  @BYTEOUT
@BYTEOUT:
  CALL  @HDOT1
@HDOT1:
  ROL   AX,1
  ROL   AX,1
  ROL   AX,1
  ROL   AX,1
  PUSH  AX
  CALL  @DIGOUT
  POP   AX
  RET

@DIGOUT:
  AND   AL,15
  CMP   AL,10
  JC    @DIG1
  ADD   AL,7
@DIG1:          ; 0-7
  ADD   AL,'0'
@COUT:
  JMP  @EMIT
  
; DBG

; -------------------
; Stack & ERRORS
; -------------------
 
@STK2TOU:
  CALL  _@DOES-1
  DW _2?UP,_RLDP,_STP,_RSTM,_RDROPX
  
@STK2ATD:
  CALL  _@DOES-2
  DW _2?DN,_RLDP,_LDM,_RSTM,_RDROPX
  
@STK2TOD:
  CALL  _@DOES-1
  DW _2?DN,_RLDP,_STM,_RSTM,_RDROPX
  
@STK2ATU:
  CALL  _@DOES-2
  DW _2?UP,_RLDP,_LDP,_RSTM,_RDROPX
  
; FOR USE IN DOES
 
@ceiling:
    CALL  @?ERR
    MAKESTR 'ceiling:'
    
  PRIM 'N+?',_N?UP,@JPDROP  ; CHK FOR STACK MOVE UP  - LIKE ",
    SKIPA
@?STKPHU1:    ; STACK MOVE UP  - LIKE C,
    MOV   WL,1
    SKIPA
@?STKPHU2:    ; STACK MOVE UP  - LIKE ,
    MOV   WL,2
    MOV   WH,0    ; 0-255 BYTES OF ELEMENT - MO MORE
    MOV   WA,[TOP]
    ADD   WA,W
    CMP   WA,[TOP+4] ; CHK UPPR LIMIT
      JNG  @ceiling
    SKIPA
DOFOR:
    MOV   IP,[IP]
DOPUSH:
    PUSH  BX
      JMP DODROP

    
  PRIM '2+?',_2?UP,@?STKPHU2  ; CHK FOR STACK MOVE UP  - LIKE ",
  PRIM '1+?',_1?UP,@?STKPHU1  ; CHK FOR STACK MOVE UP  - LIKE ",

  PRIM 'N-?',_N?DN,@JPDROP  ; CHK FOR STACK MOVE  DOWN  - LIKE UN,
    SKIPA
@?STKMVD1:    ; STACK MOVE DOWN  - LIKE UN,
    MOV   WL,1
    SKIPA
@?STKMVD2:    ; STACK MOVE DOWN  - LIKE UN,
    MOV   WL,2
    MOV   WH,0    ; 0-255 BYTES OF ELEMENT - MO MORE
    MOV   WA,[TOP]
    SUB   WA,W
    CMP   WA,[TOP+2] ; CHK UPPR LIMIT
      JNGE  @floor
    J DOPUSH

  PRIM '2-?',_2?DN,@?STKMVD2  ; CHK FOR STACK MOVE UP  - LIKE ",
  PRIM '1-?',_1?DN,@?STKMVD1  ; CHK FOR STACK MOVE UP  - LIKE ",


@floor:
    CALL  @?ERR
    MAKESTR 'floor'
      
PRIM 'TR-',_TRM,@CALL
@TRM:
  MOV AX,0FFA7H
@TRZ:  
  XCHG AX, PW [@INDIR]
  CMP AX,0FFA7H
  RET

PRIM 'TR',_TR,@CALL
  MOV AX,0B890H
  J @TRZ

 PRIMITIVE '>4TH',_4TH
    JMP IP

@?ERR:
    CALL  @CR
    POP  AX
    CALL  @NOPREFIX
    JJ  @?ERR2
    
PRIM '("+',_STRSKIP,@JPDUP
  POP   TOP
  XOR   AX,AX
  MOV   AL,[TOP]
  INC   AX
  ADD   AX,TOP
  PUSH  AX
  JMP   NEXT
  
COLON '("0A',_0ABRT
    DW _ZEQ
COLON '("A',_ABRT
    DW _STRSKIP,TO_+_STATE,_0RET
@ONERR:
    DW _CR,_STATE,_IDOT,_4TH
@?ERR2:
    MOV  AX,PW [VAL_+_TBUF]
    CALL  @NOPREFIX
    MOV   AL,'?'
    CALL  @COUT
    JMP   @ABORT
      
  PRIM 'CR',_CR,@CALL
@CR:
    CALL  @?STR
    DB  2,13,10

PRIM '".',_SDOT,@DRCALL
    SKIPB
@?STR:
    POP   AX
@SHOWSTR: 
    PUSH  SI CX
    XCHG  AX,SI
    XOR   AH,AH
    LODSB
    XCHG  AX,Cx
      JCXZ  @CHLPE
@CHLP:
    LODSB
    CALL  @COUT
@CHLP?:
      LOOP @CHLP
@CHLPE:   
    XCHG  AX,SI
    POP   CX SI
    RET
    
; -------------------
; STACK
; -------------------

prim 'DUP',_DUP,DODUP

prim 'POP',_POP,DOPOP

prim 'PUSH',_PUSH,DOPUSH

prim 'DROP',_DROP,DODROP

prim 'NIP',_NIP,DONIP

prim 'OVER',_OVER,DOOVER

prim 'SWAP',_swap,@CALL
  XCHG TOP,NXT
  RET

PRIM 'LIT',_LIT,@CALLPH
  LODSW
  RET

; -------------------
; Maths / Logic
; -------------------

prim 'U<',_ULESS,@DRCALL
  SUB BX,AX
  JJ @ZEQ 

prim '0=',_Zeq,@CALL
  ;sub bx,1
  NEG BX
  CMC
@Zeq:
  sbb bx,bx
  RET

PRIM '(>EL',_TOEL,@CALL
  ADD  NXT,TOP
  RET

PRIM '1+',_1P,@1P

PRIM '2+',_2P,@2P

PRIM '1-',_1M,@1M

PRIM '2-',_2M,@2M

prim 'XOR',_XOR,@DRCALL
  XOR BX,AX
      IF DBG_FLAG EQ 0 
@DBG:  
      ENDIF
  RET
  
prim 'AND',_AND,@DRCALL
  AND BX,AX
  RET
  
prim '-',_MINUS,@DRCALL
  SUB BX,AX
  RET
  
prim '+',_plus,@DRCALL
  ADD BX,AX
  RET
  
  
; -------------------
; String & ARRAY
; -------------------

PRIM 'OPER',_OPER,@WARY
  DW _NUMBER,  _PERFORM  ; INTERP
  DW _COMPNUM, _@COMMA ; COMPILE
  
PRIM 'DIG?',_DIG,@CALL
    MOV   AX,NXT
    CALL  DIGIT?
    CMC
    SBB   TOP,TOP
      JNC  @DIG
    MOV   NXT,AX
@DIG:
    RET
    
digit?: xor   ah,ah
        cmp   al,'9'
        jbe   @@okdig
        and   al,0dfh
        cmp   al,'A'
        jb    @@notdig
        sub   al,7
@@okdig:  sub   al,'0'
        jb    @@notdig
        cmp   ax,TOP
        cmc
@@notdig: ret

@MULADDZ:
  XOR   AX,AX
@MULADD:        ; NXT:NXT+2 *= BX
  XCHG  AX,NXT+2    ; LO W
  MOV   DI,NXT      ; HI W
  XCHG  DI,AX       ; AX-HI DI-LO
  mul   TOP
  XCHG  DI,AX       ; DI-HI
  mul   TOP         ; AX-LO DX-HI
  ADD   NXT+2,AX
  adC   DI,dx
  MOV   NXT,DI
  RET

prim '>NUM',_tonum,@PAR ; 0 0 ADR CNT BASE
  POP   CX SI
  X
@@numl: 
    jCXZ @@numz
  LODSB
@@nums: 
  CALL  digit?
    jc @@numh
  CALL  @MULADD
  dec   Cx
    JJ   @@numl
@@numh: 
  DEC   SI
@@numz: 
  X
  push  SI cx
_@RETPAR:  
  POP   BX
_@RETPARZ:  
  X
  POP   IP DX
    jmp next

;COLON 'NUM',_NUMBER
COLONM 'NUM',_NUMBER
  DW _STRSKIP?,_NOP,_0SWAP,_0SWAP,_COUNT,_BASE
  DW _TONUM,_ABRT
  MAKESTR 'NUM'
@EXIT2: DW _DROP
@EXIT1: DW _DROP,_RET 
  
  ;_IF,@EXIT2
;_@ONERR   dw _JUMP,@ONERR
;
;COLON '2DROP',_2DROP

COLON '"Z',_STRZ
    DW _COUNT,_OVER,_PLUS,_0SWAP,_CST,_RET
    
    
COLONM 'NUMC',_COMPNUM
  DW _STRSKIP?,_NOP,_NUMBER,_COMPILE,_LIT,_COMMA,_RET
  
; -----------------------
; Terminal Input / Output
; -----------------------

  PRIM '(DK',_DKEY,@CALLZPH
@DOSKEY:
  mov ah,7
  int 021h
  RET

  prim '(DE',_Demit,@DRCALL
@DOSEMIT:  
  PUSH  DX
  XCHG  AX,DX
  mov ah,2
  int 021h
  POP   DX
  RET

  PRIM '(BK',_BKEY,@CALLPH
@BIOSKEY:
  XOR   AX,AX
  INT   16H
  RET
  
  prim '(BE',_Bemit,@DRCALL
@BIOSEMIT:  
  MOV   AH,0EH
  INT   10H
  RET

acc:
  call @KEY   
	cmp  al,8
        jne  acc2   ; NOT A BS
        jCXz   acc  ; NO CHARS IN LINE
  dec  Cx
  dec  DI
  CALL @?STR
    DB  3,8,' ',8
acc2:	
  cmp  al,13      
        jne  acc3   ; NOT A CR
  mov  Bx,Cx
  ret
acc3:	
  cmp  al,' '
        jc   acc    ; ; LITTLE THEN A SPC
  STOSB
  inc  Cx
  j @BIOSEMIT

prim '(PARS',_PARSPRIM,@PAR
  PUSH  TOP
  POP   CX DI AX  
  SUB   DI,CX
  CMP   AL,' '
  JNE   @@SKIPX
  JCXZ  @@SKIPX
  REPE  SCASB
  JE    @@SKIPX
  DEC   DI
  INC   CX
@@SKIPX:
  PUSH  DI    ;  START OF THE SOURCE
  JCXZ  @@WEX
  REPNE SCASB
  JNE   @@WEX
  DEC   DI      ; END OF THE SOURCE
@@WEX:          ; CX REST LEN OF BUF
  MOV   BX,CX
  POP   AX
  SUB   DI,AX
  PUSH  AX DI 
  JMP   _@RETPARZ
  
COLONM 'WORD',_word
  DW  _SUSPEND,_SM
  
COLON 'PARS',_PARS
  DW  _ETIB,_LTIB,_PARSPRIM,TO_+_LTIB,_RET
  
COLON 'S>T!',_SM
  DW  _TBUF,_MAKESTR,_RET

COLONM 'TOKEN',_TOKEN
  DW _BL,_WORD,_?C@,_RET

; -----------------------
; LOOPS
; -----------------------

;: ..TIMES ;DROP : .TIMES ;DROP : TIMES SWAP : >TIMES PUSH
;: LOOPS (FOR MRK> BEGIN J EXECUTE (NEXT <RLS RLS> RDROP ;

COLON ';DROP',_XDROP
  DW _EX,_DROP,_RET

COLON 'EXECUTE',_EXECUTE
  DW _PUSH,_RET

PRIM '(FOR',_FOR,DOFOR

COLON '..TIMES',_DDTIMES
  DW _XDROP
COLON '.TIMES',_DTIMES
  DW _XDROP
COLON 'TIMES',_TIMES
  DW _SWAP
COLON '>TIMES',_TOTIMES
  DW _PUSH
COLON 'LOOPS',_LOOPS
  DW _FOR,@@2
@@1:
    DW _J,_EXECUTE
@@2:
  DW _NEXT,@@1,_POP,_DROP,_RDROPX
  
  
   
; -----------------------
; MEMORY FUNCTIONS
; -----------------------

PRIM 'REVERT',_REVERT,@jPNIP
	XCHG	W,WA
		JJ		@@REV
@@REV2:	
	XCHG		[top],WL
	STOSB
@@REV:
	DEC		TOP
	MOV		WL,[WA]
	CMP		WA,TOP
		JC 		@@REV2
	JMP		DODROP
	

;: REVERT   ;2DROP  BEGIN 1-  2DUP U< 0;
;     PUSH PUSH  J C@  I C@  J C!    POP  C!+ POP  AGAIN ,<

prim 'MPUSH',_MPUSH,@PAR
  POP   CX SI
  SUB   TOP,CX
  ADD   SI,CX   ; AFTER NAME ADDRESS
  STD           ; BACKWARDS
  CMPSB         ; PREPARE FOR DIRECTION
  REP   MOVSB   ; NAME  MOVE
  CLD
  JMP   _@RETPARZ
  
prim 'MOVTO',_TOADR,@PAR
  ;POP   DI  = BX
  POP   CX SI
    REP   MOVSB
  mov   nxt+2,di    ; addres of nextbyte to dx
  JMP   _@RETPARZ

prim 'S!',_MAKESTR,@PAR
  POP   AX SI
  MOV   CL,AL   ; CH = 0
  STOSB
    REP   MOVSB
  MOV   PB [DI],'`'
  JMP   _@RETPARZ

PRIM 'PAX!',_PAX,@PAR
  POP   CX SI
  JJ    @@UN4  
@@UN1:
  LODSB
  AND   AL,31
  SKIPB
@@UN2:
  LODSB
  JCXZ  @@UN6
  DEC   CX
  SKIPA
@@UN3:
  MOV   AL,' '
@@UN4:
  STOSB
@@UN5:  
  JCXZ  @@UN6
  LODSB
  DEC   CX
  CMP   AL,'_'
  JE    @@UN3
  CMP   AL,'"'
  JE    @@UN2
  CMP   AL,'^'
  JE    @@UN1
  CMP   AL,'~'
  JNE   @@UN4
  MOV   AL,128
  XOR   PB [DI-1],AL
  JJ    @@UN5
@@UN6:
  DEC   DI
  SUB   DI,BX
  XCHG  AX,DI
  MOV   [BX],AL
  JMP   _@RETPARZ

; -----------------------
; Dictionary Search
; -----------------------

prim 'CFND',_CFND,@CALL
  MOV   DI,NXT
  INC   PB [DI]
  PUSH  BX DI
  CALL  @FNDC
  POP   DI AX
  DEC   PB [DI]
  JCXZ  @AFND
  RET

@AFND:
  XCHG  AX,BX
  CALL  @FNDC
  INC   BX
  INC   BX
  RET
  
@FNDC:
  MOV   CL,[BX+4]
  LEA   DI,[BX+5]
  JMP  @FND
  
prim 'FND',_FND,@CALL
  MOV   DI,BX     ;KADE
  XOR   CL,CL
@FND:
  XOR   CH,CH
  PUSH  SI
  MOV   AX,NXT    ;KAKWO
@Nfnd:
  add   di,cx
  mov   Bx,di
  LEA   DI,[DI+4]
  mov   cl,[di]
    jcxz  xfnd?
  INC   CX
  MOV   SI,AX
  REP   CMPSB
    jNZ   @NFnD
  INC   CX
  STC
  ADC   [BX+2],CX
  MOV   NXT,BX 
xFND?:
  POP   SI 
  MOV   BX,CX 
  RET

; -----------------------
; Colon Definition
; -----------------------

COLON 'COMPILE',_COMPILE
  DW _RLDP,_comma,_RET

COLON '(@,',_@COMMA
  DW _@,_comma,_RET


COLON ':',_COLON  
  DW _HEADER,_COMPILE,DOCOLON  
COLON '>,',_RPAR  
  DW TO_+_LOCATE,_DICT,_CFND,_RET
;  _DUP,_IF,@NOTFOUND,_RET
;@NOTFOUND:  
;  DW _DROP,_DICT,_FND,_2P,_RET
  
COLON ';`',_semicolon
  DW _COMPILE,_RET
COLON ',<`',_LPAR
  DW TO_+_LOCATE
@LOCINI: DW _DICT,_FND,_RET 
  
; -----------------------
; Headers
; -----------------------

COLON 'TOKEN?',_TOKEN?
  DW _TOKEN,_0ABRT
  MAKESTR 'EMPTY LINE'
  DW _RET
 
COLONM 'HEADER',_HEADER
  DW _HERE
colon '=:',_ENTRY
    dw _TOKEN?,_0SWAP,_?C@,_1P,_DICT,_MPUSH
    DW _STM,_STM,TO_+_DICT,_RET


@TICK:
  CALL _@DOES-2
COLON '`TICK',_TK
  DW _@,_TOKEN?,_DICT,_FND,_0ABRT
  MAKESTR 'NFND'
  DW _@,_PLUS,_RET

PRIM '''',_TICK,@TICK
PRIM '''TO',_?TO,@TICK
PRIM '''AT',_?AT,@TICK
  DW 0,-2,-4

@TICKX:
  CALL  _@DOES-1
  DW _TK,_EXEC,_RET
  
PRIM 'TO',_DOTO,@TICKX
PRIM 'AT',_DOAT,@TICKX
  DW -2,-4

@TICKZ:
  CALL  _@DOES-2
  DW _TK,_COMMA,_RET
  
PRIM ''',`',_TICOM,@TICKZ
PRIM 'TO`',_TOCOM,@TICKZ
PRIM 'AT`',_ATCOM,@TICKZ
  DW 0,-2,-4


COLON 'TO',_to
  DW _TICK,_2M,_EXEC,_RET
  
COLON 'AT',_At
  DW _TICK,_2M,_2M,_EXEC,_RET
  
;COLON ';CODE`',_SMCOD
;  DW _POP,_DICT,_@,_ST,_RET
 
 
; -----------------------
; Constants
; -----------------------

;PRIM 'CONST',_constant,@DEFS
;  DW doconst,_COMMA
  
; -----------------------
; Outer Interpreter
; -----------------------

COLONM 'VIN',_VIN
;COLON 'VIN',_VIN
  DW _CR,_LIT,']',_EMIT,_TIB,_LIT,64,_ACCEPT,_RET
  
; -----------------------
; PRIMITIVES
; -----------------------

prim 'PERFORM',_PERFORM,@JPldPC
  SKIPA
prim 'EXEC',_exec,@JPDROP
  XCHG    W,WA
  SKIPA
doDEFER:
  mov     WA,[WA]
  SCASW
  JMP   [WA-2]

; -------------------
; Flow Control
; -------------------

prim '(;',_RET,doRET

@RESET:
  mov   bx,1000h     ; only 64k allocate
  mov   ah,4ah
  int   21h
  
@ABORT:
  MOV ax,0
  ORG $-2
PRIM 'BYE',_BYE,0
  mov PW [val_+_LTIB],ax
  mov DSp,@D_TOP
@QUIT:  
  mov Rsp,@R_TOP
  call doRET

  DW _LPAR
_interpret:
  DW _TEXT_IN,_SPC,_EVAL,_JUMP,_interpreT  


primITIVE '("?',_STRSKIP?,@CLRC
  MOV   CL,[DI]   ; DI = BX
  ADD   DI,CX
  CMP   PB [DI],'"'
  JNE   DOSKIP
  SKIPA
@RDROPX:
  POP   WA IP
    JJ NEXT

@J:
  POP CX AX
  PUSH AX CX 
  JJ DOPUSHW
  
doRDROP:
  POP   WA
  SKIPB
@suspend:   ; OTLOGEN PREXOD
  lodsw
  PUSH  AX
  JJ NEXT
  
@NEXT:
  POP   W 
  DEC   W 
  PUSH  W 
  SKIPR W
DOmIF:
  INC   TOP
doIFm:
  DEC   TOP
  JS    DOSKIP
DOJUMP:        
  mov IP,PW [IP]
  jJ next

prim '(?BR',_IF,@JPDROP
  je DOJUMP
DOSKIP:  
  lodsw
  jJ next

DOSETV:
  SCASW
_@SET:
  MOV [WA],TOP
DODROP:
  MOV   TOP,[DSP]
DONIP:
  INC   DSP
  INC   DSP
  JJ NEXT

doTUCK:
  XCHG TOP,NXT
doOVER:
  MOV W,NXT
  jJ DOPUSHW

  SCASW
  SCASW
_@DOES:
  POP   W
  PUSH  IP
  XCHG  IP,W
  SKIPA
  
  SCASW
  SCASW
DOvar:
  XCHG   W,WA
  jJ DOPUSHW

  SCASW
  SCASW
doconst: 
  mov W,[WA]
  jJ DOPUSHW
  
doPOPret:
  POP   W IP
  SKIPA
  
DODUP:
  PUSH  TOP
DOPOP:
  POP   W
  jJ DOPUSHW

@CALLDPH:
  MOV   WL,[TOP]
@CALLZPH:
  XOR   WH,WH
@CALLPH:
  CALL  WA
  
DOPUSHW:
  XCHG  W,TOP
@PUSHW:
  X 
  PUSH  W
@SWAPSTK:  
  X
  
; -------------------
; Inner Interpreter
; -------------------

next:   
  MOV    WA,[IP]
@INDIR:
  CMPSW
  jmp PW [WA-2]
  
IF DBG_FLAG
  IF DBG_ON
    ORG $-4
    NOP
    DB 0B8H
    ORG $+2
  ENDIF
ENDIF
  
  CALL  @DBG
  CMPSW
  jmp PW [WA-2]

; ^^^^^^^^^^^^^^^^^^^^^^^
; Inner Interpreter
; -------------------

@LARY:
  SHL   TOP,1
@WARY:  
  SHL   TOP,1
@BARY:
  ADD   TOP,WA
  J NEXT

  
PRIMITIVE 'EX',_EX
  POP   WA
DIVE 'NOP',_NOP 
DIVE '(NEST',docolon
  DW 13CH
@DOCOL:
  PUSH  IP
doLbl:  
  MOV   IP,WA
  j   NEXT
  
 DIVE '(NEST-',@NESTRM
    CALL  @TRM
      JE @DOCOL
    PUSH  IP W
    MOV   IP,WA
    CALL  NEXT
  DW _4TH
    POP   W
    CALL  @TRZ
      J  DORET
    
; -------------------
; Peek and Poke
; -------------------

prim 'C@',_c@,@C@

prim 'CSTR',_count,@CALLDPH
  INC   BX
  RET
  
prim 'STR',_STR,@CALLPH
  MOV   AX,[BX]
  INC   BX
  INC   BX
  RET
  
prim '!+',_STP,@JPNIP
  MOV   [TOP],AX
  JJ    @2P

prim 'C!+',_CSTP,@JPNIP
  MOV   [TOP],AL
  JJ    @1P

primITIVE '@+',_LDP
  X
  PUSH   [TOP]
@XINC:  
  X
@2P:  
  INC   TOP
@1P:  
  INC   TOP
  J   next  

primITIVE '@+',_LDM
  X
  PUSH   [TOP]
  X
  JJ @2M
  
prim '!-',_STM,@JPNIP
  MOV   [TOP-2],AX
@2M:  
  DEC   TOP
@1M:  
  DEC   TOP
  J   next  

primitive '@',_@
  mov bx,PW [bx]
  j next

prim '!',_ST ,@JPNIP
  MOV   [BX],AX
  j doDROP

prim 'C!',_CST ,@JPNIP
  MOV   [BX],AL
  j doDROP

PRIM '0SWAP',_0SWAP,@CLRCX
  PUSH  CX
  J @SWAPSTK
  
prim '?C@',_?C@,@JPDUP
@C@:  
  mov   bH, PB[bx]
@HWtoB:  
  XCHG  BH,BL
@WtoB:  
  mov   bh,0
  j next

@JPldPC:  ; LOAD DROP CALL
  mov top,[top]
@JPDROP:
  PUSH  WA
@ADROP:
  DPOP  W
  XCHG  W,TOP
  TEST  W,W
  RET
  
@JPniP:
  PUSH  WA
@NIP:
  DPOP  W
  RET
  
@SSWPCALL:
  XCHG  W,TOP
@SWPCALL:
  CALL  WA
  XCHG  W,TOP
    j next
    
@DRCALL:
  CALL  @ADROP
@CALL:
  CALL  WA
    j next

; -------------------
; Compilation
; -------------------

PRIM 'J',_J,@J
PRIM 'RDROP;',_RDROPX,@RDROPX
prim '(|',_suspend,@suspend   ; OTLOGEN PREXOD
prim '(BR',_JUMP,DOJUMP
prim '(NXT',_NEXT,@NEXT


@JPDUP:
  PUSH  WA
@DUP:
  Dpush TOP
  RET
  
@PAR:
  PUSH  DX IP
@CLRCX:
  X
@CLRC:
  PUSH  WA
  MOV   WA,TOP
  XOR   CX,CX
  RET
  
priM 'ACCEPT',_ACCEPT,@CALL
  MOV   DI,NXT
  xor  cx,cx
acceptl:
  call acc 
  cmp  Bx,Cx
  jne  acceptl
  RET

COLONM '(I',_INI
  DW _LIT,_VIN,TO_+_TEXT_IN,_LIT
DICTPTR:  
  DW ENDADR,_STR,_LIT,_@VOCTOP,_MPUSH,TO_+_DICT
  DW _LIT,80H,_COUNT,_RET

 COLONM 'ALEL',_ALEL
  DW _TOEL,TO_+_LTIB,TO_+_ETIB,_RET

final:
COLON 'EVAL',_EVAL    ; ADR LEN -> INTERPRET
  DW _ALEL
@EVAL:        
  DW _TOKEN,_IF,@EXIT1
  DW _LOCATE,_OPER,_PERFORM,_JUMP,@EVAL
  
; 941
; 939 940 942  958 965 954 949 932 938

IF DBG_FLAG
INCLUDE ITSY.IDB
ENDIF

ENDADR = $ - START + 0100H

IF LISTGEN
  ORG DTOP
ELSE
DW 0    ; FILLER
DPTR = $
;DW FREEMEM-ENDADR-2
  ENTRY '=:',_ENTRY 
  ENTRY '',0 
DTOP = $
ENDIF

DTOP = DTOP - DPTR
    DOKE _DICT+VAL_,DPTR
DPTR = DPTR - 2  
    DOKE DICTPTR,DPTR
    DOKE  DPTR,DTOP
    
Zfreemem = DPTR - ENDADR

IF Zfreemem LT 0
    JMP MEMORY_ERROR
ENDIF

    
MyCseg  ends
        end  Start

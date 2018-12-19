; PRIMITIVE COMMANDS OF VIRTUAL FORTH MASHINE
;---------------------------------------------
; JUMP EXIT IF IF-		      / CONTROL	\
; push pop J DUP		        / STACK		 \
; !R+ @R+ XCHG XA		        / TRANSFER /  STANDART
; +2/ +* NAND -/		        / MATH		/

; EXTENSIONS
; ((M-  				            / MEMORY COMPARE
; C!R+ C@R+				          / BYTE TRANSFER  { R ADRS }
;  !+  @+  !  @			        / WORD TRANSFER
; C!+ C@+ C! C@			        / BYTE TRANSFER
; NOT XOR 2/ 			          / MATH
; (DOSI (VIDI (KBDI (DEMT   / IO
; (FKEY (FEMT (BKEY (BEMT   / IO
; (SKIP EX				          / CONTROL
; OVER SWAP NIP (DROP RDROP / STACK


locals  @@

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

TO_     =  -2
AT_     =  -4
VL_     =   2

JMPS    MACRO LBL
  jmp   SHORT LBL
        ENDM

SKIPA   MACRO
  DB    03DH
        ENDM

SKIPB   MACRO
  DB    03CH
        ENDM

SKIPr   MACRO reg
  mov   reg,0
  org   $-2
        ENDM

X       MACRO
  xchg  Rsp,DSP
        ENDM

TO_R    MACRO  REG
  PUSH  REG
        ENDM

R_TO    MACRO  REG
  POP   REG
        ENDM

WA2P     macro
  scasw
        endm
		
WA1P     macro
  INC DI
        endm

I2P     macro
  INC   I
  INC   I
        endm

@I2P   macro  
  MOV  WR,[I]
  I2P
  TEST WL,1
        endm

DROP    macro
  LODSW
        endm

SWAP    macro
  XCHG	T,[DSP]
        endm

CLR   macro	REG
  XOR	REG,REG
        endm

?ZERO	MACRO	REG
		OR REG,REG
		ENDM
		
rchg    macro   reg
  xchg  ax,reg
        endm

NIP     MACRO   REG
		RCHG  REG
        DROP
        ENDM

ALGN  MACRO  FLAG
        IF ($-START+FLAG) AND 1
        NOP
        ENDIF
        ENDM

L       MACRO LBL
		ALGN  0
LBL:
        ENDM

; REGISTERS     for interpretter
I   = BX  ; INSTUCTION POINTER
RSP = SP  ; RETURN STACK POINTER
WA  = DI  ; WORK ADDRESS REGISTER
DSP = SI  ; DATA STACK POINTER
FPP = BP  ; FRAME PARAMS POINTER
T   = AX  ; DATA STACK TOP REGISTER
TL	= AL
TH	= AH
AR  = DX  ; ADDRESS/ARITHMETIC REGISTER
WR  = CX  ; WORK REGISTER
WL  = CL
WH  = CH

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
@_START:
  jmpS   _start
;--------------------------------------------------------
; VARIABLES
;--------------------------------------------------------
@_OPER:
  DW	0,0,0,0,0
  
@_FL DW 0
     DW 0  
@_AX DW 0
     DW 0  
@_BX DW 0
     DW 0  
@_CX DW 0
     DW 0  
@_DX DW 0
     DW 0  
@_SI DW 0 
     DW 0  
@_DI DW 0
     DW 0  
@_BP DW 0
     DW 0  
@_ES DW 0
     DW 0  
@_DS DW 0
     DW 0  
	
_start:  
        mov   	bX,1000h     ; only 64k allocate
        mov   	ah,4ah
        int   	21h
		MOV		AX,0500H
		INT 	10H
  
 L @_ABORT
		MOV   	RSP,@R_TOP-2
		MOV   	DSP,@S_TOP-2
		CALL	@_TROFF
		CALL  	@_RET
@_INIT:    
  DW	0  

;vvvvvv--------------   IO  ---------------
 L @_MEMCMP							; MEM-,
		NIP		CX
		NIP  	DI
		PUSH  	DSP
		RCHG	SI
		XOR   	T,T
		REP 	CMPSB
		JE		_CMP
		CLR   	CH
		DEC		SI
		LODSB
		MOV   	CL,[DI-1]
		SUB   	AX,CX
_CMP:
		POP   	DSP
		RET

 L @_DOS          					; @_DOS
		CALL	_INITREG
		INT		21H
		RET
		
 L @_VID          					; @_VID
		CALL	_INITREG
		INT		10H
		RET
		
 L @_KBD        					; @_KBD
		CALL	_INITREG
		INT		16H
		RET		
		
_INITREG:
		POP		DI
		PUSH	AX
        DROP
		NIP  	BX
		NIP  	CX
		RCHG  	DX
		POP		AX
		PUSH	DSP
		CALL	DI
		PUSH	DS ES BP DI SI DX CX BX AX
		PUSHF
		CLD
		PUSH	CS CS
		POP		ES DS
		MOV		DI,OFFSET @_FL
		MOV		CX,10
_INITR:
		POP		AX
		SCASW
		STOSW
		LOOP	_INITR
		POP		DSP
		DROP
		RET
		
_DOSIN:	RCHG  	BX
_DOSCH:	MOV		CX,1
		MOV		DX,SP
_DOSFN:	POP		DI
		PUSH	AX
		MOV		AX,[DI]
		SCASW
		INT		21H
		RCHG  	CX
		POP		AX
		JMP		DI
		
 L @_DEMIT          			; @_DEMIT
		RCHG 	DX
		CALL	_DOSFN
		DW		0200H
		DROP
		RET
		
 L @_FKEY						; @_FKEY
		CLR		BX
		CALL	_DOSIN
		DW		04000H
		JCXZ	_FKEY
		SKIPA
_FKEY:	MOV		AL,26
		RET		
		
 L @_FEMIT						; @_FEMIT ?
		NIP  	BX
		CALL	_DOSCH
		DW		03F00H
		DROP
		RET
		
 L @_BKEY          				; @_BKEY
		CLR		AX
		INT 	16H
		?ZERO	AL
		JE		_BKEY
		CLR		AH
_BKEY:		
		RET
		
; Set cursor position 	
; AH=02h BH = Page Number, DH = Row, DL = Column

; Select active display page 	AH=05h 	AL = Page Number
 L @_BEMIT          			; @_BEMIT
		MOV		AH,0EH
		INT 	10H
		DROP
		RET

								;-------TR----------vvvvvvvvv
 L @_HTROF
		JMP		I
 L @_TROFF						; ((TROFF
        SKIPr 	CX
		MOV		WR,[I]
_TR:	MOV		PW @__MAIN,CX
		RET
 L @_TRON						; ((TRON
        SKIPr 	CX
		DB 0EBH,_DOTR2+2-@__MAIN
		JMP		_TR
		
_DOTR:  CALL	@_TROFF
		MOV     PW __TR,I
		CALL	@_RET
@__TR	DW 		0,@_HTROF
		CALL	@_TRON
		SKIPr   I
__TR 	DW 		0  
		MOV		WR,[I]
		JMPS 	@__MAIN+2
		
_DOTR2:	JMPS	_DOTR		
	
;-------TR----------^^^^^^^^^


;^^^^^^--------------   IO  ---------------
	
_IO:              				; (IO
		DEC		WR
        PUSH    AR BP
        CALL    WR
        POP     BP AR
 L @_RET          				; (;
        R_TO    I
        JMPS    @__MAIN
_DRJMP: DROP		
 L @_JMP             			; (JUMP
        MOV     I,[I]
        JMPS    @__MAIN
 L @_IFM         				; (IFM
        DEC     T
		JS     	@_SKIP
        JMPS    @_JMP
 L @_IF              			; (IF
		MOV  	WR,[I]
		TEST 	WL,1
        JNE     _IO
		?ZERO  	T
        JE     _DRJMP
		DROP		
 L @_SKIP          				; (SKIP
        i2P
        JMPS    @__MAIN		
		
 L @_PUSH          				; PUSH
        TO_R    T
_DROP:	DROP
        JMPS    @__MAIN
 L @_NIP						; NIP
		SWAP
 L @_DROP						; DROP
		JMPS	_DROP
		
 L @_XOR            			; XOR
        NIP     WR                
        XOR     T,WR              
        JMPS    @__MAIN           
 L @_NAND          				; AND
        NIP     WR
        AND     T,WR
 L @_NOT          				; NOT
        NOT     T
        JMPS    @__MAIN
		
 L @_XCHG           			; XCHG
        R_TO    WA
        XCHG    T,WA
        JMPS    _XA
 L @_XA              			; XA
        R_TO    WA
        XCHG    WA,AR
		SKIPB
_RSTP:  DROP
_XA:    TO_R    WA
        JMPS    @__MAIN
 L @_RSTP         				; !R+
        R_TO    WA
        STOSW
        JMP     _RSTP
 L @_CSTP         				; C!R+
        R_TO    WA
        STOSB
        JMP     _RSTP
 L @_CLDP          				; C@R+
        R_TO    WA
		CLR		WR
        MOV     WL,[WA]
        WA1P
        JMPS    _J
 L @_RLDP          				; @R+
        R_TO    WA
        MOV     WR,[WA]
        WA2P
        JMPS    _J
 L @_J                			; J
        R_TO    WA
        R_TO    WR
        TO_R    WR
_J:
        TO_R    WA
        JMPS    @__WPUSH
_POP:		
		RCHG	WA
		TO_R	WA
 L @_POP            			; ( POP
        R_TO    WR
        SKIPA
 L @_DUP            			; ( DUP
        MOV     WR,T
@__WPUSH:
		LEA   	DSP,[DSP-2]
		MOV   	[DSP],T
        XCHG    WR,T
@__MAIN:		           		; ( NOP
		;JMPS    _DOTR2
        @I2P    
        JE      @NEST@
		DEC		WR
        JMP     WR
 L @_EX             			; ( EX
        R_TO    WR
@NEST@:
        TO_R    I
        MOV     I,WR
        JMPS    @__MAIN
		
 L @_STORE						; !
		NIP		WA
		STOSW
		DROP
		JMPS	@__MAIN		
 L @_CSTORE						; C!
		NIP		WA
		STOSB
		DROP
		JMPS	@__MAIN				
 L @_STOREP						; !+
		NIP		WA
		STOSW
		RCHG	WA
		JMPS	@__MAIN		
 L @_CSTOREP					; C!+
		NIP		WA
		STOSB
		RCHG	WA
		JMPS	@__MAIN		
 L @_FETCH						; ((@
		RCHG	WA
		MOV		T,[WA]
		RET
 L @_CFETCH						; ((C@
		CLR		WA
		RCHG	WA
		MOV		TL,[WA]
		RET				
 L @_STR						; STR
		CALL	@_FETCH
		WA2P
		JMPS	_POP
 L @_CSTR						; CSTR
		CALL	@_CFETCH
		WA1P
		JMPS	_POP
		
 L @_OVER						; OVER
		MOV		WR,[DSP+2]
		JMPS	@__WPUSH
 L @_RDROP						; RDROP
		R_TO	WR
		JMPS	@__MAIN
 L @_SWAP						; SWAP
		SWAP
		JMPS	@__MAIN
		
 L @_SDIV          				; -/
        SHL     PW [DSP],1
        RCL     T,1
        CMP     T,AR
        JB      NO_DIV
        SUB     T,AR
 L @_U1P						; U1+
        INC     PW [DSP]
NO_DIV:
        JMPS    @__MAIN
 L @_PMUL          				; +*
        MOV     WR,[DSP]
        SHR     WR,1
        JNC     @_D2DIV
        ADD     T,AR
 L @_D2DIV						; D2/
        RCR     T,1
        RCR     PW [DSP],1
        JMPS    @__MAIN
 L @_PLAVG        				; +2/
        ADD     T,[DSP]           
        MOV     [DSP],T           
 L @_2DIV          				; 2/
        RCR     T,1               
        JMPS    @__MAIN           

 L @_END		

MyCseg  ends
        end  Start

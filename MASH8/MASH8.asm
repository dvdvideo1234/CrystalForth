;C:\Documents and Settings\Gergana\Desktop\CrystalForth\TEMPFO\mash8.asm
; -----------------------------------------------
; _DUP	\  STACK
; _J	 \
; _PUSH	 /
; _POP	/
; 
; _@R+	\  TRANSFER
; _!R+	 \
; _RX	 /	RA XA
; _TX	/	RT XCHG
; 
; _EXIT	\  CONTROL
; _JUMP	 \
; _NEXT	 /
; _IF	/
; 
; _+*	\  MATH AND LOGIC 
; _+2/	 \
; _-/	 /
; _NAND	/
; 

locals  @@

	     pd	 equ dword ptr
	     pw	 equ word  ptr
	     pb	 equ byte  ptr

TO_ =	-2
AT_ =	-4
VL_ =	 2
qqq_= 0

JMP_    MACRO LBL
	jmp   SHORT LBL
    ENDM

SKIPA_   MACRO
	DB    03DH
    ENDM

SKIPB_   MACRO
	DB    03CH
    ENDM

SKIPR_   MACRO reg
	mov   reg,0
	org   $-2
    ENDM

X_  MACRO
	xchg  Rsp,DSP
  ENDM

TOD_    MACRO  REG
	PUSH  REG
    ENDM

DTO_    MACRO  REG
	POP   REG
    ENDM

TWICE_    macro
	DW	$+2
    endm

RDEC_    macro
	DW	@_NEXT_
	TWICE_
    endm

;@I2P   macro
;	MOV WR,[I]
;	I2P
;	TEST	AL,1
;    endm

DROP_    macro
  XCHG  T,W
	DTO_	T
  endm

DUPW_    macro
	TOD_	T
  XCHG  T,W
  endm

CLR_   macro     REG
	XOR   REG,REG
  endm

?ZERO_   MACRO   REG
	OR	REG,REG
	ENDM

RTO_     MACRO   REG
	X_
	POP	REG
	X_
    ENDM

TOR_     MACRO   REG
	X_
	PUSH	REG
	X_
  ENDM

LDWP_ MACRO  
	LODSW
  ENDM

STWP_ MACRO   
	STOSW
  ENDM

ALIGN_  MACRO  FLAG
	IF ($-START+FLAG) AND 1
    NOP
qqq_ = qqq_+1    
	ENDIF
	ENDM

N_	MACRO LBL	
LBL:
    ENDM

L_	MACRO LBL
	ALIGN_  0
LBL:
ENDM

P_  MACRO LBL
	ALIGN_  0
	NOP
LBL:
	org   $-1
  ENDM

@nam    macro   msg
	local	endstr
	db   	endstr-$-1
	db   	msg
endstr	label   byte
	endm

@ln     macro   token
ppppp = $
	@nam  token
	dw    qqqqq
qqqqq = ppppp
	endm

XT_     macro   LBL,ADR
  L_    LBL
  DW    ADR
  ENDM

VAR_    macro   LBL,DAT
  XT_   LBL,@_VAR
  DW    DAT
  ENDM

const_  macro   lbl,dat
  XT_   LBL,@_CONS@
  DW    DAT
  endm

DEFER_  macro   lbl,dat
  XT_   LBL,@_JUMP
  DW    DAT
  endm

value_  macro   lbl,dat
	ALIGN_  0
  DW    @_SETVA
  const_    LBL,dat
  endm

vector_ macro   lbl,dat
	ALIGN_  0
  DW    @_SETVA
  DEFER_    LBL,DAT
  endm

point_  macro   lbl1,LBL2,dat
	L_  LBL1
  DW  @_POP
  vector_ LBL2,dat
  endm

QUAN_   MACRO   LBL,DAT
	ALIGN_  0
  DW    VAR3@
  vector_    lbl,DAT
  ENDM

entry_  macro ADR,DAT,nam
  DW    ADR,DAT
  @nam  nam
  endm

        
        
        
        
        
; REGISTERS     for interpretter
  I	  = SI	; INSTUCTION POINTER
  RSP = BP	; RETURN	STACK POINTER
  DSP = SP	; DATA STACK POINTER 
	RT  = DI	; RETURN	STACK TOP REGISTER

  T   = CX  ; DATA STACK TOP REGISTER
  TL  = CL
  TH  = CH
  W   = AX  ; WORK REGISTER
  WL	= AL
  WH	= AH
  AR  = BX  ; ADDRESS & ARITHMETHIC REGISTER
	
	; AX CX DX BX SCRATCH
	; KEEP I DSP RSP RT

  NACC 	=	DI
	NBASE	=	BP

MyCseg  segment para  use16

    assume cs:	MyCseg,	 ds: MyCseg, ss: MyCseg, es: MyCseg

    org 100h

	@TBUF   = -256	     ;	256
	@TIB    = @TBUF  *	2    ;	256 ;	512 B FSTACK
	@R_TOP  = @TIB   *	2    ; 1024 B RSTACK
	@S_TOP  = @R_TOP *	2    ; 2048 B DSTACK
	@VOCTOP = @S_TOP *	2    ; 4096 B =	4 BUFFERS * 1024 B

    Start   Label byte
@_@START:
	mov     bX,1000h	  ; only 64k allocate
	mov     ah,4ah
	int     21h
 P_	@_ABORT
	CLD
	MOV     DSP,@S_TOP
	MOV     RSP,@R_TOP
	CALL    _EXECU
@_@INITA:	; INIT TIB CSTR
  DW    0
  
;--------------- RETURN STACK --------------------
	
 P_ @_POP         ; POP
  TOD_  T
  MOV   T,RT
  JMP_  @RDROP

 P_ @_IOZ
  TOD_  T
 P_ @_IO1
  TOD_  T
 P_ @_IO2
  TOD_  T
 P_ @_IO3
  TOD_  T
 P_ @_IO4
  X_
  PUSH  AR RT
  X_
  XCHG  AX,T
  POP   DI CX DX
  PUSH  SI 
  MOV   BX,DI
  MOV   SI,DX
  RET
  
; Return input character and true, 
; or a false if no input. 

 L_ @_?CRX      ; (  -- c T | F )  
  DW @_IOZ
  MOV   DX,0FFFFH ; input command & setup for TRUE flag
  MOV   AH,6    ; MS - DOS Direct Console I/O
  INT   021H    ;
  JZ    QRX3    ; ?key ready
  OR    AL,AL   ; AL=0 if extended char
  JNZ   QRX1    ; ?extended character code
  INT   021H    ;
  STC
QRX1:
  MOV   AH,0
  JNC   QRX2
  XCHG  AH,AL   ; extended code in msb
QRX2:
  PUSH  AX      ; save character 
  SKIPB_
QRX3:
  DEC   DX      
  PUSH  DX      ; flag
  JMP_  @_@IORET
  
 L_ @_CTX      ; ( c -- ) \ Send character c to output device.
  DW  @_IO1     ; char in DL
  CMP   DL,0FFH ; 0FFH is interpreted as input
  JNZ   @TX1    ; do NOT allow input
  MOV   DL,32   ; change to blank
@TX1:
  MOV   AH,6    ; MS - DOS Direct Console I/O
  INT   021H    ; display character
  
@_@IORET:  
  X_
  POP   RT AR 
  X_
 
 P_ @_DROPX
@DROPX:
  DTO_  T
  
 P_ @_RET           ; RET
  MOV   I,RT
  
 P_ @_RDROP         ; RDROP
@RDROP: 
  RTO_  RT
@MAI0:  
  JMP 	_MAIN
  
 P_ @__DROP
  DTO_  T
  SKIPA_
  
 P_ @_0?X           ; RDROP
  JCXZ  @DROPX
  JMP_	@MAI0
  
; --------------------  CONTROL  -------------------
	
 P_ @_MIF             ; (-IF
  INC   T
  SKIPA_
  
 P_ @_NEXT            ; (NEXT
  DEC   RT
  MOV   AL,0
  ORG   $-1
  
 P_	@_1MIF 					  ; (IF-
  DEC   T
  JS	  _SKIP

 P_	@_JUMP				    ; (JUMP
_JMP:
  MOV   I,[I]
  JMP_	_MAIN
	
 P_ @_?SKIP           ; (?SKIP
  JCXZ  @IFM1?
  JMP_	_MAIN
  
 P_	@_IF  				    ; (IF
  INC   T
  
 P_ @_IFM1            ; (IFM1 
@IFM1?:  
  DEC   T
  DTO_  T
  JZ  _JMP
 P_ @_SKIP            ; (SKIP
_SKIP:
	INC		I
	INC		I
  JMP_	_MAIN
	
; -------------------- MATH ------------------- 

 P_	@_PLAVG					; +2/
  DTO_  W
	ADD   T,W
	MOV   W,T
	RCR   T,1
	TOD_	W 
  JMP_	_MAIN

 P_	@_PMUL					; +*
  DTO_  W
	TEST  WL,1
	JZ    @D2DIV
	ADD   T,AR
@D2DIV:				     
	RCR   W,1
	RCR   T,1
	TOD_	W 
  JMP_	_MAIN

 P_	@_SDIV					; -/
  DTO_  W
	SHL   W,1
	RCL   T,1
	CMP   W,AR
	JB	  NO_DIV
	SUB   T,AR
	INC   W
NO_DIV:
	TOD_	W 
  JMP_	_MAIN
  
; -------------------------  LOGIC  --------------------	

 P_	@_NAND					; NAND
  DTO_  W
  AND   T,W
 P_ @_NOT           ; NOT
  INC	  T
 P_ @_NEG           ; NEG
  NEG	  T
  JMP_	_MAIN

 P_	@_XOR 					; XOR
  DTO_  W
  XOR   T,W
  JMP_	_MAIN
  
 P_ @_ULESS         ; U<
  DTO_  W
  SUB   W,T
  JMP_  @FLAG

 P_ @_ZEQ           ; 0=
  SUB   T,1
@FLAG:
  SBB   T,T
  JMP_	_MAIN

; ---- MAIN LOOP  & STACK  ----------------

 P_ @_DUP           ; DUP
  TOD_  T
  JMP_	_MAIN
  
 P_ @_XA            ; XA
  XCHG  RT,AR
  JMP_	_MAIN
  
 P_ @_XI            ; EX
  XCHG  RT,I
  JMP_	_MAIN
  
 P_	@_XT				    ; XCHG
  XCHG  T,RT
  JMP_	_MAIN
	
 P_ @_FOR           ; (FOR
  MOV   I,[I]
  
 P_ @_PUSH 					; PUSH
  DROP_
  JMP_	_RPUSH
	
_EXECU: 
  DTO_	I
  JMP_	_MAIN
  
_NEST:
  XCHG	I,W
_RPUSH:
  XCHG	RT,W
  TOR_  W
_MAIN:					    ; (NOP
	LDWP_	
  TEST  WL,1
  JE	  _NEST
  DEC   W
  JMP		W   
	
;-----------------------  TRANSFER ----------------

 P_	@_J			     	  ; J
  TOD_  T
  MOV   T,[RSP]
  JMP_	_MAIN

 P_	@_RLDP				  ; @R+
  TOD_  T
  MOV   T,[RT]
@RT2P:  
  INC   RT
@RT1P:  
  INC   RT
  JMP_	_MAIN
  
 P_	@_RSTP				  ; !R+
  DROP_
  MOV   [RT],W
  JMP_  @RT2P
  
 P_ @_RSTBP         ; C!R+
  DROP_
  MOV   [RT],WL
  JMP_  @RT1P
  
;-----------------------------------------------

freemem:
;  DW ENDMEM-FREEMEM-2
 ; entry_  @_ENTRY,0,'=:'
  ;DB 0
EndMem:

; --------------  END  ---------------

 L_	@_END__

    MyCseg  ends
    end  Start

;----------------  PARSE   -----------------

;  CHAR etib ltib   /  START LEN >IN  / >IN 				           
;  DX   CX   DI    		dX    AX  Cx

 L_ @_PARS
  DW  @_IO2
  XCHG  CX,DI
  XCHG  SI,AX     ; SI = DX
	JCXZ 	@@SKIPX
	SUB  	DI,CX	   
	CMP  	AL,' '
	JNE  	@@SKIPX
	REPE 	SCASB
	JE   	@@SKIPX
	DEC  	DI
	INC  	CX
@@SKIPX:
	push  	di      ;  START OF THE SOURCE
	push  	di      ;  START OF THE SOURCE
	JCXZ  	@@WEX
	REPNE 	SCASB
	JNE   	@@WEX
	DEC   	DI
@@WEX:          ; END OF THE SOURCE  IN DI
	POP		W 	    ; DX START OF THE WORD
	SUB   DI,W    ; LENGTH OF THE WORD
@RETVAL:  
	PUSH	DI 
@RETLEN:  
  PUSH  CX	; CX REMAIN LENGTH OF THE BUFFER
	JMP 	@_@IORET
	
; -----------------------
; searching
; -----------------------
  
 L_ @_FIND
  DW  @_IO2
  CLR_  CX   
@FND: 
  ADD   DI,CX
  LEA 	DI,[DI+4]
  mov 	cl,byte[Di]
  jcxz	@DCX ;not_fnd
  inc 	cx
  PUSH  SI
  repe	cmpsb
  POP   SI
  jNZ 	@FND
	MOV		CL,2
	ADD		[DI+2],CX
  SKIPA_
@DCX:
  MOV   DI,SI
  JMP_ 	@RETVAL

;----------------   NUMBERS	 ---------------------

@ATOI:
	CALL  	@@numini
	CALL  	@@SGN
@@GETC:	
  JCXZ    @@EXNUM2
	LODSB	
	deC   	CX
	CALL  	DX
	JMP_	  @@GETC
  
COMOPT  DW @@B16,@@B8,@@B2,@@KOLI,@@ACCUM,@@DIEZ
OPTAB   DB "$&%'^#"

@@SGN:	
	JCXZ  	@@ERNUM
  CALL    @@STATE
	CMP   	AL,'-'     ; SGN
	JNE   	@@N16
	POP   	BX
	CALL  	BX         ; return to caller
	not   	nacc
	not   	ar
	inc   	nacc
  jne     @@EXNUM2
	inc   	ar
@@EXNUM2: 
  RET

@@DIEZ:	
	XCHG  	nacc,AX
  
@@numini:	
	CLR_   	nacc      ; ZEROING ACCUMULATOR
  CLR_    AR        ; HI PART ACCUMULATOR
  SKIPA_
  
@@B2:
	MOV		AL,2        ; BIN
  SKIPA_
  
@@B8:
	MOV		AL,8        ; OCT
  SKIPA_
  
@@B16:              ; HEX
	MOV		AL,16
  
@@setbas:	
	DEC   	AX
	DEC   	AX
	xor   	ah,ah
	mov   	nbase,ax
	INC   	nbase
	INC   	nbase
@@NORMAL?:
  CALL    @@STATE
  
@@N16:	
  PUSH    AR
	MOV		  AR,6-1
@@SCANB1:	
	CMP		  AL,OPTAB[AR]
	JE		  @@SCANB2	
	DEC		  AR
	JNS		  @@SCANB1	
@@SCANB2:	
	SHL		  AR,1
	MOV		  DX,COMOPT[AR]
  POP     AR
  JS      @@N5
	JCXZ    @@ERNUM
  RET
  
@@ERNUM:	
	MOV   	CX,SI
@@STATE:	
	pop   	Dx    ; rdrop
	RET
  
@@N5:	
	cmp   	al,'9'+1
	jc    	@@ton2
	cmp   	al,'A'      ; no case sensivity
	jc    	@@ERNUM
	sub   	al,7
@@ton2:	
	sub   	al,'0'
	cmp   	ax,nbase
	jnc   	@@ERNUM
@@ACCUM:	
	Xchg  	AR,AX
	mul   	nbase
	Xchg  	AR,AX
	Xchg  	nacc,AX
	mul   	nbase
	Xchg  	nacc,AX
	add   	nacc,ax
  ADC     AR,DX
	JMP_    @@NORMAL?
  
@@KOLI:	
	AND	  	AL,31
	JMP_  	@@ACCUM
  
 L_ @_ATOI
  DW  @_IO2
  PUSH  NBASE
	MOV   AL,10   	; BASE 10 INITIALLY
	CALL	@ATOI
  POP   NBASE
	JMP_ 	@RETVAL

;======================================================

;-----------------------------------------------

freemem:
  ;DW ENDMEM-FREEMEM-2
  ;entry_  @_ENTRY,0,'=:'
  ;DB 0
EndMem:

 L_	@_END__

    MyCseg  ends
    end  Start

; --------------  END  ---------------

;======================================================

 L_ @_ODD?
    DW @_DUP
 L_ @_ODD
    DW @_AT_AND,1

 L_ @_AT_PLUS
    DW @_RLDP,@_RDROP,@_PLAVG,@_DROPX
    


 L_ @_AT_AND
    DW @_RLDP,@_RDROP
 L_ @_AND
    DW @_NAND,@_NOT,@_RET
    
 L_ @_IPLUS
    DW @_J,@_SKIP
 L_ @_ALIGN
    DW @_ODD?,@_PLAVG,@_DROPX
    
 L_ @_IMINUS
    DW @_J
 L_ @_MINUS
    DW @_NEG
 L_ @_PLUS_
  DW @_PLAVG,@_DROPX
 
 L_ @_XTM2D
        DW @_2DIV
 L_ @_XTIMS
        DW @_FOR,@@LPS
@@LPS0  DW @_J,@_EXECUTE
@@LPS   DW @_NEXT,@@LPS0
 L_ @_2EXIT
	DW @_RDROP
 L_ @_EXIT
	DW @_RDROP
 L_ @_NOP
	DW @_RET
	
 L_ @_PREMV
    DW @_ODD?
 L_ @_XDROP	
	DW @_XI
 L_ @_DROP
	DW @_DROPX

 L_ @_CONS@
  DW @_RLDP,@_RDROP,@_RET
  
  CONST_  @_TBL,80H
  CONST_  @_TIB,-512
  CONST_  @_TBUF,-256
  CONST_  @_BL,32
  CONST_  @_M1,-1
  L_ @_ZEQ 
    DW @_IF,@_M1 
  CONST_  @_0,0
         
 L_ @_DOES 
  DW @_POP,@_XT,@_RET 

 L_ @_SETVA
  DW @_R2P,@_JUMP,@_RSET
 L_ @_ILD
  DW @_J
 L_ @_LD
  DW @_PUSH
 L_ @_RSET
  DW @_RSTP,@_RDROP,@_RET 
  
 L_ @_XHERE
	DW @_HERE,@_XI
  VALUE_  @_HERE,FREEMEM
  VALUE_  @_ETIB,0
  VALUE_  @_LTIB,0
 L_ @_XDICT
	DW @_DICT,@_XI
  VALUE_  @_DICT,@VOCTOP
  VAR_    @_CNTC,0

  DEFER_  @_OK,@_nop 
  DEFER_  @_AXEPT,@_nop  ;_ACC
  DEFER_  @_NUM,@_nop 
  DEFER_  @_ERROR,@_drop ; _IDTYP
         
  POINT_  @_REINI,@_INITV,@_@_INI
  POINT_  @_SETPT,@_DOIT?,0

 L_ @_MAKER
  dw @_HNTRY
 L_ @_comar
  DW @_POP,@_LD,@_JUMP,@_comma

	
	
 L_ @_EVAL 
	DW @_NOP  
 L_ @_@EVAL   
	DW @_TOKEN,@_DLDB,@_IF,@_DROP,@_DOIT?,@_JUMP,@_@EVAL
	
 L_ @_SEMIC 
	DW @_comar,@_RET   		; (;,

 L_ @_clit    
	dw @_comar,@_lit        ; (LIT,

 L_ @_NUMBR
	DW @_CSTR,@_NUM,@_NZ??,@_RET 
	
 L_ @_XZ?? 
	DW @_XI 
 L_ @_Z?? 
	DW @_ZEQ 
 L_ @_NZ?? 
	DW	@_ABRT?
	@NAM  " ?"
	DW	@_RET 

 L_ @_DXEP 
	DW @_DUP 
 L_ @_XEP 
	DW @_XT,@_EXECUTE
 L_ @_VAR
  DW @_POP,@_RET 
	
 L_ @_TOKN?
	DW @_TOKEN,@_XZ?? 
 L_ @_DLDB 				; DUP C@
	DW @_DUP 
 L_ @_LDB 
  DW @_PUSH,@_RLDBP,@_RDROP,@_RET
  
 L_ @_TOKEN
	DW @_BL 
 L_ @_WORD_
	DW @_PARSE,@_TBUF 
 L_ @_TOSTR	
	DW @_DXEP,@_MKSTR,@_LIT,'`',@_ASTBP,@_RET 
 L_ @_PARSE
	DW @_NOP,@_ETIB,@_LTIB,@_PARS,TO_+@_LTIB,@_RET 

 L_ @_HDICT
    DW  @_HERE,@_STR 
 L_ @_TODIC
	DW @_XDICT,@_MPUSH,@_RET 

 L_ @_@_INI
    DW  @_HDICT,@_REINI,@_EVAL,@_REINI
    DW  @_LPAR,@_0,TO_+@_LTIB,@_RET 

 L_ @_ABRT?
	DW @_@STR,@_SWAP,@_IF,@_DROP,@_ERROR,@_ABORT

 L_ @_COLON  
	DW @_ALIGN,@_RPAR          ; :
 L_ @_HNTRY
	DW @_HERE 
 L_ @_ENTRY
	DW @_0SWAP,@_TOKN?
	DW @_XDICT,@_STRPU,@_ASTM,@_ASTM,@_LDAR,@_RET 
  
; L_ @_ST  
;  DW @_PUSH,@_RSTP,@_RDROP,@_RET 
;  
; L_ @_0?X__
;  DW @_IF,@_EXIT,@_RET 

 L_ @_SEMI 
	DW @_SEMIC
 L_ @_LPAR 				; INTERPRETTER
	DW @_SETPT,@_?FIND,@_IF,@_NUMBR,@_@EXEC,@_RET 

 L_ @_RPAR 		; COMPILER
	DW @_SETPT,@_?FNDC,@_DEC,@_IF,@RPAR2
 L_ @_@EXEC
  DW @_LD
 L_ @_EXECUTE
  DW @_PUSH,@_RET 
@RPAR2 DW @_?FIND,@_IF,@@COMP_NUM,@_JUMP,@_comar
@@COMP_NUM:
	DW @_NUMBR
 L_ @_CMLIT	
	DW @_cLIT 
 L_ @_COMMA
	DW @_XHERE
 L_ @_STP 
  DW @_PUSH 
 L_ @_STPRX
  DW @_RSTP,@_POP,@_RET 
	
 L_ @_TICK ;_LOCATE  '
	DW @_XZ??,@_TOKN?,@_JUMP,@_?FIND
  
 L_ @_LIT
  DW @_RLDP,@_RET
  
 L_ @_CSTR
  DW @_PUSH,@_RLDBP,@_XT,@_POP,@_RET
  
 L_ @_PLUS
  DW @_PLAVG,@_DROPX
	
 L_ @_?FNDC
	DW @_DXEP,@_J,@_INC 
 L_ @_?FIND	
	DW @_DICT,@_FIND,@_RET 

 L_ @_0SWAP
  DW @_0 
 L_ @_SWAP 
  DW @_PUSH,@_XT,@_POP,@_RET 
  
 L_ @_2DIV 
  DW @_0 
 L_ @_AVERG 
  DW @_PLAVG
 L_ @_NIP 
  DW @_PUSH,@_DROP,@_POP,@_RET   
  
 L_ @_STRM 
  DW @_2M,@_STR
 L_ @_2M
  TWICE_
 L_ @_1M
  DW @_IFM
  TWICE_
  DW @_RET 

 L_ @_STRPU
    DW @_DLDB,@_1P 
    
 L_ @_MPUSH
    DW @_STAR,@_PREMV,@_IF,@MPUSH,@_1M,@_PUSH 
    DW @_1M,@_DUP,@_LDB,@_ASTBM,@_POP 
@MPUSH  DW @_XTM2D,@_STRM
 L_ @_ASTM
    DW @_XA,@_RBACK,@_RSTP,@_RBACK,@_XA,@_RET   

 L_ @_@STR 
  DW @_J,@_POP,@_POP,@_CSTR,@_PLUS,@_PUSH,@_PUSH,@_RET 
  
 L_ @_STAR
  DW @_PUSH,@_XA,@_RDROP,@_RET
  
 L_ @_LDAR
  DW @_XA,@_I,@_XA,@_RET
  
 L_ @_I
  DW @_J,@_RET
  
 L_ @_STR
  DW @_PUSH,@_RLDP,@_XT,@_POP,@_RET
  
 L_ @_INC
  DW @_RW@
 L_ @_1P
  DW @_AT_PLUS,1
  
 L_ @_DEC
  DW @_RW@,@_1M,@_RET
  
 L_ @_RW@
  DW @_XT,@_PUSH,@_J,@_LD,@_XI,@_RSTP,@_RDROP,@_RET


@WMOVD  DW @_RLDP,@_XA,@_RSTP,@_XA
 L_ @_WMOVDN
      DW @_IFM,@WMOVE
 L_ @_MOVX     
      DW @_POP,@_NAND,@_DROPX
      
 L_ @_MKSTR   ; SRC LEN DST / DST
    DW @_DXEP,@_PUSH,@_DUP,@_RSTBP,@_XT,@_POP    
    
 L_ @_CMOVE   ; SRC DST LEN
      DW @_PUSH,@_STAR,@_XT,@_ODD?,@_IF,@@1
      DW @_RLDBP,@_XA,@_RSTBP,@_XA
@@1   DW @_2DIV,@_JUMP,@WMOVD      
      
@WMOVU  DW @_R2M,@_RLDP,@_R2M,@_XA,@_R2M,@_RSTP,@_R2M,@_XA
 L_ @_WMOVU
      DW @_IFM,@WMOVU,@_JUMP,@_MOVX
 L_ @_CMOVU
      DW @_PUSH,@_IPLUS
 L_ @_CMOVU1
      DW @_STAR,@_IPLUS,@_XT,@_ODD?,@_IF,@@1
      DW @_R1M,@_RLDBP,@_R1M,@_XA,@_R1M,@_RSTBP,@_R1M,@_XA
@@1   DW @_2DIV,@_JUMP,@WMOVD      
      
      
 L_ @_MKSTR   ; SRC LEN DST / DST
    DW @_DXEP,@_STAR,@_DUP,@_ASTBP
 L_ @_AMOVE    
    DW @_PREMV,@_IF,@CMOVE,@_CSTR,@_ASTBP
@CMOVE  DW @_XTM2D,@_STR
 L_ @_ASTP
    DW @_XA,@_RSTP,@_XA,@_RET 
 L_ @_ASTBP
    DW @_XA,@_RSTBP,@_XA,@_RET
  
;-----------------------------------------------

freemem:
  DW ENDMEM-FREEMEM-2
  entry_  @_ENTRY,0,'=:'
  DB 0
EndMem:

; --------------  END  ---------------

 L_	@_END__

    MyCseg  ends
    end  Start


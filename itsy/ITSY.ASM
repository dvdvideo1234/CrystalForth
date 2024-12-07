 link =  0
 TEMP = 0
immediate  = 080h
locals  @@
VAL_ = 2

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr

SKIPA  MACRO
  DB    03DH
  ENDM

SKIPB  MACRO
  DB    03CH
  ENDM

SKIPr  MACRO reg
MADR = $
  mov   reg,0
  IF $-MADR-2
  org   $-1
  ENDIF
  org   $-1
  ENDM

nam_    macro   msg,FLAG
  local endstr
  db    endstr-$-1+FLAG
  db    msg
endstr  label   byte
        endm

HEAD MACRO  NAM,LBL,FLAG
TEMP = $
  DW LINK
LINK = TEMP
  NAM_ NAM,FLAG
LBL:
ENDM  

prim MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW FLAG
  ENDM

primitive MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,FLAG
  DW $+2
  ENDM

colon MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,FLAG
  DW docolon
  ENDM

constant MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW doconst,FLAG
  ENDM

variable MACRO NAM,LBL,FLAG
  HEAD NAM,LBL,0
  DW dovar,FLAG
  ENDM

MyCseg  segment para  use16

        assume cs: MyCseg,  ds: MyCseg, ss: MyCseg, es: MyCseg

        org 0100h

Start   Label byte

; -------------------
; Initialisation
; -------------------

@abort:        
        xor bp,bp
        mov sp,-256
        CALL  @SET_IP
        DW _TOint
NEWLINE: 
        DW _LIT,13,_EMIT,_lit,10,_EMIT,_lit,'>',_EMIT
        DW _lit,64,_accept,_to_in,_store,_spc
        dw _EVAL
        DW _spc,_lit,'O',_EMIT,_lit,'K',_EMIT
        DW _branch,NEWLINE

_STATES DW @WARY,_TO_NUM,_EXEC,_TO_NUMC,_COMMA

_spc dw docolon,_bl,_emit,_ret
 
@word:
  PUSH  SI
  mov SI,PW [VAL_+_number_tib]
  MOV CX,PW [VAL_+_to_in]
      ;  JCXz @abort
	mov Dh,bl	;save parametter
  SUB SI,CX
  mov bx,PW [VAL_+_dp]
	xor aX,aX	; prepare for endline
	mov DI,bx
  STOSB 
wordf:
        JCXz wordz
  lodsb
  DEC cx
  cmp al,Dh
        je wordf
wordc:  
  inc  Pb [bx]
  STOSB
        jCXz wordz
  lodsb
  DEC cx
  cmp al,Dh
        jne wordc
wordz:   
  mov PW [VAL_+_to_in],cx
  MOV PB [DI],'`'
@SET_IP:
	pop si
  jmp next

_TOFINDEX DW docolon,_POP,_state,_store,_RET

_FINDEX DW docolon,_state,_fetch,_PUSH,_RET

_error dw docolon,_zero_branch,intskip,_LIT,'?',_EMIT,_ABORT

_TO_NUM DW docolon,_0,_0,_ROT,_count,_to_number,_error,_drop
DROPX   DW _drop
intskip dw  _RET

_TO_NUMC  DW docolon,_TO_NUM,_lit,_lit,_comma,_comma,_RET

_EVAL   DW docolon
        dw _Bl,_word,_DUP,_PEEKB
        DW _zero_branch,DROPX,_FINDEX,_STATES,_@exec
        dw _branch,_EVAL+2
        
; -------------------
; Peek and Poke
; -------------------

@fetch:        
        mov bx,PW [bx]
        jmp SHORT next

@store:        
        pop PW [bx]

; -------------------
; Stack
; -------------------

@DROP:        
  pop bx
  jmp SHORT next

@POP:
  MOV   AX,[BP]
  INC   BP
  INC   BP
  jmp SHORT @PUSHW
  
@PUSH:
  POP   AX
  XCHG  AX,BX
  DEC   BP
  DEC   BP
  MOV   [BP],AX
  jmp SHORT next
  
@dup:
  push bx
  jmp SHORT next

@swap:
  pop ax
  jmp SHORT @PUSHW

@rot:
  pop  dx ax
  push dx
@PUSHW:
  push bx
  xchg ax,bx

; -------------------
; Inner Interpreter
; -------------------

next:
  MOV    DI,[SI]
  CMPSW
next2:
  jmp PW [di-2]

; -------------------
; Compilation
; -------------------

;_BRK: DW $+2
;    INT 3
;    JMP NEXT
    
@comma:        
        mov di,PW [VAL_+_dp]
        xchg ax,bx
        stosw
        mov PW [VAL_+_dp],di
        jmp @DROP

@lit:
        lodsw
        jmp @PUSHW

; -------------------
; Maths / Logic / ARRAY
; -------------------

@WARY:
  SHL   BX,1
  JMP   SHORT @BARY
@MINUS:        
  NEG BX
@plus:        
  pop DI
@BARY:  
  add bx,DI
  jmp next

@ZEQ:
  sub bx,1
  sbb bx,bx
  jmp next

; -------------------
; Flow Control
; -------------------

@0branch:        
  test bx,bx
  pop bx
  je @JUMP
  lodsw
  jmp next

@JUMP:        
  mov si,PW [si]
  jmp next

@TOEXEC:
  MOV BX,[BX]
@exec:
  LEA di,[bx+2]
  pop bx
  jmp next2
  ;jmp PW [di-2]

@RET:        
  mov si,PW [bp]
@rdrop:
  inc bp
  inc bp
  jmp next

; -------------------
; String
; -------------------

@count:  
  inc bx
  push bx
  DEC BX
@PEEKB:        
  mov bl, PB[bx]
  mov bh,0
  jmp next

@_to_number:
  MOV  CX,BX
	pop  AX DI BX     ; ADDRESS AND ZEROS
  PUSH SI BP
	xchg ax,si
  MOV  BP,PW [VAL_+_BASE]
	mov  ah,0
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
  xchg ax,di
  mul  bp
	xchg ax,di
  xchg ax,BX
  mul  bp
	xchg ax,BX
  add  BX,AX
  adC  di,DX
        jmp  to_numl
to_numERR:
  INC   CX
  DEC   SI
to_numz:
	xchg ax,si
  pop  bp si
  push BX di ax
	xchg cx,bx
        jmp next


; -----------------------
; Terminal Input / Output
; -----------------------

@accept:  
  xor  cx,cx ; BX COUNTER - CX LIMIT
  MOV  DI , PW [VAL_+_tib]  ; BUFFER
  XCHG  CX,BX
acceptl:
  call acc 
	cmp  cx,BX
        jne  acceptl
  LEA CX,[BX+DI]
  mov PW [VAL_+_number_tib], CX
  jmp next
 
acc:
  call getchar   
	cmp  al,8
        jne  acc2
  OR   BX,BX
        jz   acc1
  dec  bx
	push ax
  call outchar
  mov  al,' '
outc2:
  call outchar
  pop  ax
outchar:
  xchg ax,dx
  mov  ah,2
  int  021h
acc1:	
  ret
acc2:	
  cmp  al,13
        jne  acc3
  mov  Cx,Bx
	ret  
acc3:	
  cmp  al,' '
        jc   acc1
  MOV  [DI+BX],AL
  inc  Bx
  jmp outchar

@emit:
  xchg ax,bx
  call outchar
  jmp @DROP

getchar:
  mov ah,7
  int 021h
  mov ah,0
  RET

; -----------------------
; Dictionary Search
; -----------------------

@FND:
  PUSH SI 	;mov  AX,PW [VAL_+_last]
	xor  cx,cx
  MOV  DI,BX
findl:
  XCHG  SI,AX
  LODSW
  mov  cl,PB [si]
        jcxz findnf
	INC  cX
  rep  cmpsb
  MOV  DI,BX
        jNe   findL
findm: 
	INC  cX
  mov  BX,si
findnf:
  POP  sI
  RET

@find:
  POP   AX
  XCHG  AX,BX
	CALL  @FND
@XFND:  
  push bx
	mov  Bx,cx
        jmp next

@findc:
  POP   AX
  XCHG  AX,BX
  INC   PB [BX]
	CALL  @FND
  DEC   PB [DI]
        jmp SHORT @XFND

; -----------------------
; Colon Definition
; -----------------------

  colon ';`',_semicolon,0
  dw _lit,_RET,_comma,_TOint,_RET

_TOint:
  DW docolon,_TOFINDEX,_last,_FETCH,_find,_RET
  
_TOCOMP:
  DW docolon,_TOFINDEX,_last,_FETCH,_FETCH
;  dw _brk
  dw _findc
  DW _DUP,_zero_branch,@TOCOMPX,_ret
@TOCOMPX  DW _DROP,_last,_FETCH,_FETCH,_FIND,_LIT,2,_PLUS
  DW _RET
  
  colon ':',_colon,0
  dw _TOCOMP,_create,_do_semi_code
docolon:
  dec bp
  dec bp
  mov PW [bp],si
  mov si,di
  jmp next
  
; -----------------------
; Headers
; -----------------------

  colon 'create',_create,0
  dw _dp,_fetch,_last,_fetch,_comma
  dw _last,_store,_Bl,_word,_count
  dw _plus,_dp,_store,_0,_comma
  dw _do_semi_code
dovar:
  XCHG  AX,DI
  jmp @PUSHW

  primitive '(;code)',_do_semi_code,0
  mov di,PW [val_+_last]
  mov al,PB [di+2]
  and ax,31
  add di,ax
  mov PW [di+3],si
  jmp @RET

; -----------------------
; Constants
; -----------------------

  colon 'constant',_constant,0
  dw _create,_comma,_do_semi_code
doconst: 
  mov Ax,PW [di]
  jmp @PUSHW


; -----------------------
; NAMES
; -----------------------

  prim 'rot',_ROT,@rot
  prim 'dup',_dup,@dup
  prim 'drop',_drop,@drop
  prim 'pop',_POP,@POP
  prim 'push',_PUSH,@PUSH
  prim 'swap',_swap,@swap
  prim 'c@',_PEEKB,@PEEKB
  prim '@',_fetch,@fetch
  prim '!',_store ,@store
  prim '-',_MINUS,@MINUS
  prim '+',_plus,@plus
  prim '0=',_Zeq,@ZEQ  
  prim 'abort',_abort,@abort
  prim 'cstr',_count,@count
  prim '0br',_zero_branch,@0branch
  prim 'br',_branch,@JUMP
  prim '@exec',_@exec,@TOEXEC
  prim 'exec',_exec,@exec
  prim 'exit',_RET,@RET
  prim ',',_comma,@comma
  prim 'lit',_lit,@lit
  prim 'find',_find,@find
  prim 'findc',_findc,@findc
  prim 'bye',_bye,0
  prim 'word',_word,@word
  prim '>number',_to_number,@_to_number
  prim 'accept',_accept,@accept
  prim 'emit',_emit,@emit

; -------------------
; Variables
; -------------------

  variable 'state',_state,0
  variable '>in',_to_in,0
  variable '#tib',_number_tib,0
  variable 'dp',_dp,freemem
  variable 'base',_base,10
  variable 'last',_last,final
  constant '0',_0,0
  constant 'BL',_BL,32

final:
  
  constant 'tib',_tib,32768

; -----------------------
; Outer Interpreter
; -----------------------


freemem:

MyCseg  ends
        end  Start

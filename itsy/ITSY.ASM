 link =  0
 TEMP = 0
immediate  = 080h
locals  @@
VAL_ = 2

pd  equ dword ptr
pw  equ word  ptr
pb  equ byte  ptr


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

        jmp _abort+2

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

        constant 'tib',_tib,32768

; -------------------
; Initialisation
; -------------------

        primitive 'abort',_abort,0
        mov ax,PW [val_+_number_tib]
        mov PW [VAL_+_to_in],ax
        xor bp,bp
        mov PW [VAL_+_state],bp
        mov sp,-256
        mov si,OFFSET _interpret+2
        jmp next

; -------------------
; Compilation
; -------------------

        primitive ',',_comma,0
        mov di,PW [VAL_+_dp]
        xchg ax,bx
        stosw
        mov PW [VAL_+_dp],di
        jmp @DROPW

        primitive 'lit',_lit,0
        lodsw
        jmp @PUSHW

; -------------------
; Stack
; -------------------

        primitive 'rot',_ROT,0
        pop  dx ax
        push dx
@PUSHW:
        push bx
        xchg ax,bx
        jmp next

        primitive 'drop',_drop,0
@DROPW:        
        pop bx
        jmp next

        primitive 'dup',_dup,0
        push bx
        jmp next

;        primitive 'swap',_swap,0
;        pop ax
;        jmp @PUSHW

; -------------------
; Maths / Logic
; -------------------

;        primitive '-',_MINUS,0
;        NEG BX
;@plus:        
        primitive '+',_plus,0
  pop ax
  add bx,ax
        jmp next

 ;       jmp @plus

;        primitive '0=',_Zeq,0
;        sub bx,1
;        sbb bx,bx
;        jmp next
  primitive '=',_equals,0
  pop ax
  SUB bx,ax        
  sub bx,1
  sbb bx,bx
  jmp next

;        colon '=',_equals,0
;        DW _MINUS,_ZEQ,_RET

; -------------------
; Peek and Poke
; -------------------

        primitive '@',_fetch,0
        mov bx,PW [bx]
        jmp next

        primitive '!',_store ,0
        pop PW [bx]
        jmp @DROPW

; -------------------
; Inner Interpreter
; -------------------

next:   MOV    DI,[SI]
        CMPSW
        jmp PW [di-2]

; -------------------
; Flow Control
; -------------------

        primitive '0branch',_zero_branch,0
        test bx,bx
        pop bx
        je @JUMP
        lodsw
        jmp next

        primitive 'branch',_branch,0
@JUMP:        
        mov si,PW [si]
        jmp next

        primitive 'execute',_execute,0
        LEA di,[bx+2]
        pop bx
        jmp PW [di-2]

        primitive 'exit',_RET,0
@RET:        
        mov si,PW [bp]
        inc bp
        inc bp
        jmp next

; -------------------
; String
; -------------------

  primitive 'count',_count,0
  inc bx
  push bx
  DEC BX
@PEEKB:        
  mov bl, PB[bx]
  mov bh,0
  jmp next

;  primitive 'c@',_PEEKB,0
;  jmp @PEEKB


  primitive '>number',_to_number,0
	xchg ax,si
  MOV  CX,BX
	pop  SI DI BX     ; ADDRESS AND ZEROS
  PUSH SI BP
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

  primitive 'accept',_accept,0
  MOV  DI , PW [VAL_+_tib]
  xor  cx,cx
	xchg cx,Bx
acceptl:
  call acc 
	cmp  cx,BX
        jne  acceptl
  jmp next
 
acc:
  call getchar   
	cmp  al,8
        jne  acc2
  or   bx,bx
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
  mov  cx,bx
	ret  
acc3:	
  cmp  al,' '
        jc   acc1
  mov  [bx+di],al
  inc  bx
  jmp outchar

  primitive 'word',_word,0
  PUSH  SI
	mov ah,bl	;save parametter
  MOV SI,PW [VAL_+_tIB]
  ADD SI,PW [VAL_+_number_tib]
  mov cx,PW [VAL_+_to_in]
  SUB SI,CX
  mov bx,PW [VAL_+_dp]
	xor al,al	; prepare for endline
	mov DI,bx
  STOSB 
wordf:
        jcxz wordz
  lodsb
  dec cx
  cmp al,ah
        je wordf
wordc:  
  inc  Pb [bx]
  STOSB
        jcxz wordz
  lodsb
  dec cx
  cmp al,ah
        jne wordc
wordz:   
  mov PW [VAL_+_to_in],cx
	pop si
  jmp next

  primitive 'emit',_emit,0
  xchg ax,bx
  call outchar
  jmp @DROPW

getchar:
  mov ah,7
  int 021h
  mov ah,0
  RET

; -----------------------
; Dictionary Search
; -----------------------

  primitive 'find',_find,0
  PUSH SI
	mov  AX,PW [VAL_+_last]
	xor  cx,cx
findl:
  XCHG  SI,AX
  LODSW
  mov  cl,PB [si]
        jcxz findnf
	AND  cL,31
  CMP  CL,[BX]
        JNE   findl
  LEA  DI,[BX+1]
  rep  cmpsb
        jNe   findL
findm: 
	mov  cL,32
  mov  BX,si
findnf:
  POP  sp
	push bx
	mov  Bx,cx
        jmp next

; -----------------------
; Colon Definition
; -----------------------

  colon ':',_colon,0
  dw _Bl,_state,_store,_create
  dw _do_semi_code
docolon:
  dec bp
  dec bp
  mov PW [bp],si
  mov si,di
  jmp next
  
  colon ';',_semicolon,immediate
  dw _lit,_RET,_comma,_0,_state
  dw _store,_RET

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
; Outer Interpreter
; -----------------------

final:
        colon 'interpret',_interpret,0
interpt dw _number_tib,_fetch,_to_in,_fetch,_equals
        DW _zero_branch,intpar
        
        DW _lit,50,_accept
        dw _number_tib,_store
        dw _0,_to_in,_store
        
intpar  dw _Bl,_word,_find,_dup
        dw _zero_branch,intnf
        DW _state,_fetch,_equals
        dw _zero_branch,intexc
        DW _comma
        dw _branch,intdone
        
intexc  dw _execute
        DW _branch,intdone
        
intnf   dw _dup,_ROT,_count,_to_number
        dw _zero_branch,intskip
        DW _state,_fetch
        dw _zero_branch,intnc
        
        DW _last,_fetch,_dup
        dw _fetch,_last,_store,_dp,_store
intnc   dw _abort

intskip dw _drop, _drop, _state, _fetch
        dw _zero_branch,intdone
        DW _lit,_lit,_comma,_comma
intdone dw _branch,interpt

freemem:

MyCseg  ends
        end  Start

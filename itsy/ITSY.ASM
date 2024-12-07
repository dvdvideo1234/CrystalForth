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

prim MACRO NAM,LBL,FLAG,ADR
  HEAD NAM,LBL,FLAG
  DW ADR
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

        variable '#tib',_number_t_i_b,0

        variable 'dp',_dp,freemem

        variable 'base',_base,10

        variable 'ETB',_ETB,10

        variable 'last',_last,final

        constant 'tib',_t_i_b,32768

; -------------------
; Initialisation
; -------------------

        primitive 'abort',_abort,0
        mov ax,PW [val_+_number_t_i_b]
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
@DROP:        
        pop bx
        jmp next

        primitive 'lit',_lit,0
        lodsw
@DUPW:
        push bx
        xchg ax,bx
        jmp next

; -------------------
; Stack
; -------------------

        primitive 'rot',_ROT,0
        pop dx
        pop ax
        push dx
        jmp @DUPW

        prim 'drop',_drop,0,@DROP

        primitive 'dup',_dup,0
        push bx
        jmp next

        primitive 'swap',_swap,0
        pop ax
        jmp @DUPW

; -------------------
; Maths / Logic
; -------------------

        primitive '+',_plus,0
        pop ax
        add bx,ax
        jmp next

        primitive '=',_equals,0
        pop ax
        sub bx,ax
        sub bx,1
        sbb bx,bx
        jmp next

; -------------------
; Peek and Poke
; -------------------

        primitive '@',_fetch,0
        mov bx,PW [bx]
        jmp next

        primitive '!',_store ,0
        pop PW [bx]
        pop bx
        jmp next

; -------------------
; Inner Interpreter
; -------------------

next:    lodsw
        xchg di,ax
        jmp PW [di]

; -------------------
; Flow Control
; -------------------

        primitive '0branch',_zero_branch,0
        test bx,bx
        pop bx
        je @branch
        lodsw
        jmp next

        primitive 'branch',_branch,0
@branch:
        mov si,PW [si]
        jmp next

        primitive 'execute',_execute,0
        mov di,bx
        pop bx
        jmp PW [di]

        primitive 'exit',_exit,0
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
        mov bl,byte[bx-1]
        mov bh,0
        jmp next

        primitive '>number',_to_number,0
	pop  ax
        pop  di
	mov  cx,bx
	push si
	xchg ax,si
        push bp
	mov  bp,10
	mov  ah,0
to_numl: jcxz to_numz
	call to_nums
	jmp  to_numl
to_numz: pop  bp
	xchg ax,si
	pop  si
        push di
	push ax
	xchg cx,bx
        jmp next

to_nums: lodsb
	dec  cx
to_n2:   cmp  al,'#'
	jne  to_n4
	mov  al,16
to_n3:	mov  bp,ax
	ret
to_n4:   cmp  dl,'%'
	jne  to_n6
	mov  al,2
	jmp  to_n3
to_n5:   dec  si
	inc  cx
	ret
to_n6:	cmp  al,'9'+1
        jc   to_n7
        cmp  al,'A'
        jc   to_n7
        sub  al,7
to_n7:   sub  al,48
        cmp  aX,bp
        jnc  to_n5
        xchg ax,di
        mul  bp
	xchg ax,di
        add  di,ax
	ret

; -----------------------
; Terminal Input / Output
; -----------------------

        primitive 'accept',_accept,0
        xor  cx,cx
	xchg cx,ax
	xchg di,ax
acceptl: call acc 
	cmp  cx,di
	jne  acceptl
	xchg di,ax
	ret
 
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
acc1:	ret

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

crlf:	mov  al,10
	push ax
  mov  al,13
  jmp  outc2


  primitive 'word',_word,0
  push si
	mov ah,bl	;save parametter
  mov si,PW [VAL_+_etb]
  mov cx,PW [VAL_+_to_in]
  mov bx,PW [VAL_+_dp]
  sub si,cx
	mov PW [bx],0
wordf:
	xor al,al	; prepare for endline
        jcxz wordc
  lodsb
  dec cx
  cmp al,ah
        je wordf
wordc:  
  call _spcs
        jcxz wordz
  lodsb
  dec cx
  cmp al,ah
        jne wordc
wordz:   
  mov PW [VAL_+_to_in],cx
	pop si
        jmp next

  primitive 'emit',emit,0
  xchg ax,bx
  call outchar
  pop bx
  jmp next

  primitive 's+c!',_emit,0
_spcs:
	inc  Pb [bx]
	mov  di,255
	and  di,[bx]
	mov  [di+bx],cl	
        ret

getchar:
  xchg ax,cx
  mov ah,7
  int 021h
  mov ah,0
	xchg ax,cx
        jmp  findnf



; -----------------------
; Dictionary Search
; -----------------------

  primitive 'find',_find,0
	mov  si,PW [VAL_+_last]
	xor  cx,cx
findl:
  mov  cl,PB [si]
        jcxz findnf
	inc  cx
  mov  di,bx
  rep  cmpsb
        je   findm
	add  si,cx
	lea  si,[si+3]
	jmp  findl
findm: 
  mov  dx,si
	mov  cx,si
findnf:
  xchg ax,sp
	push bx
	xchg ax,sp
	mov  dx,cx
        ret

; -----------------------
; Colon Definition
; -----------------------

        colon ':',_colon,0
        dw _lit,-1,_state,_store,_create
        dw _do_semi_code
docolon: dec bp
        dec bp
        mov PW [bp],si
        lea si,[di+2]
        jmp next

        colon ';',_semicolon,immediate
        dw _lit,_exit,_comma,_lit,0,_state
        dw _store,_exit

; -----------------------
; Headers
; -----------------------

        colon 'create',_create,0
        dw _dp,_fetch,_last,_fetch,_comma
        dw _last,_store,_lit,32,_word,_count
        dw _plus,_dp,_store,_lit,0,_comma
        dw _do_semi_code
dovar:
        push bx
        lea bx,[di+2]
        jmp next

        primitive '(;code)',_do_semi_code,0
        mov di,PW [val_+_last]
        mov al,PB [di+2]
        and ax,31
        add di,ax
        mov PW [di+3],si
        mov si,PW [bp]
        inc bp
        inc bp
        jmp next

; -----------------------
; Constants
; -----------------------

        colon 'constant',_constant,0
        dw _create,_comma,_do_semi_code
doconst: push bx
        mov bx,PW [di+2]
        jmp next

; -----------------------
; Outer Interpreter
; -----------------------

final:
        colon 'interpret',_interpret,0
interpt dw _number_t_i_b,_fetch,_to_in,_fetch,_equals
        DW _zero_branch,intpar
        
        DW _t_i_b,_lit,50,_accept
        dw _number_t_i_b,_store
        dw _lit,0,_to_in,_store
        
intpar  dw _lit,32,_word,_find,_dup
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

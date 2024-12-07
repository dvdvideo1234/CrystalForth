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

        variable 'STATE',_state,0

        variable '>IN',_to_in,0

        variable '#tib',_number_tib,0

        variable 'DP',_dp,freemem

        variable 'BASE',_base,10

        variable 'LAST',_last,final

        constant '0',_0,0

        constant 'BL',_BL,32

        constant 'TIB',_tib,32768

; -------------------
; Initialisation
; -------------------

        primitive 'ABORT',_abort,0
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

        primitive 'LIT',_lit,0
        lodsw
        jmp @PUSHW

; -------------------
; Stack
; -------------------

        primitive 'ROT',_ROT,0
        pop  dx ax
        push dx
@PUSHW:
        push bx
        xchg ax,bx
        jmp next

        primitive 'DROP',_drop,0
@DROPW:        
        pop bx
        jmp next

        primitive 'DUP',_dup,0
        push bx
        jmp next

        primitive 'PUSH',_pUSH,0
        XCHG  AX,BX
        CALL  @PUSH
        ;XCHG  SP,BP
        ;push  bx
        ;XCHG  SP,BP
        POP   BX
        jmp next

        primitive 'POP',_POP,0
        push  BX
        ;XCHG  SP,BP
        ;POP   bx
        ;XCHG  SP,BP
        CALL  @POP
        XCHG  AX,BX
        jmp next

        primitive 'SWAP',_swap,0
        pop ax
        jmp @PUSHW

; -------------------
; Maths / Logic
; -------------------

@XOR:
  pop ax
  XOR bx,ax
  JMP DI

primitive '-',_MINUS,0
  NEG BX
@plus:        
  pop ax
  add bx,ax
  jmp next

prim '+',_plus,0,@plus

primitive '0=',_Zeq,0
@ZEQ:        
  sub bx,1
  sbb bx,bx
  jmp next

PRIM '=',_equals,0,@XOR
  JMP SHORT @ZEQ

; -------------------
; DEBUGER
; -------------------

PRIMITIVE 'H.',_HDOT,0
  XCHG  AX,BX
  CALL  @HDOT
  POP   BX
  JMP   NEXT


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
@DIG1:
  ADD   AL,'0'
  JMP   @COUT

@HDOT:
  CALL  @WORDOUT
@SPDOT:  
  MOV   AL,' '
  JMP   @COUT
  
@STRID:
  PUSH  CX DX DI
  MOV   DX,-1
  MOV   CX,32
  XCHG  AX,DI
@@IDLP:  
  INC   DX
  DEC   DI
  MOV   AL,[DI]
  AND   AL,127
  CMP   AL,DL
  JE    @@IDLPX
  LOOP  @@IDLP
@@IDLPX:
  XCHG  AX,DI
  POP   DI DX CX 
  RET
  
@STROUT:
  PUSH  CX DI
  XCHG  AX,DI
  MOV   AX,[DI]
  AND   AX,127
  MOV   CX,AX
@LPSTR:
  INC   DI
  MOV   AL,[DI]
  CALL  @COUT
  LOOP  @LPSTR
  POP   DI CX 
  RET
  
@CRDOT:  
  MOV   AL,13
  CALL  @COUT
  MOV   AL,10
  JMP   @COUT
  
@DBG:
  CALL  @PUSH   ; AX      1
  CALL  @CRDOT  ; AX .
  POP   AX
  CALL  @PUSH   ; RETADR  2
  ;CALL  @HDOT
  MOV   AX,SI   ; IP
  CALL  @HDOT
  MOV   AX,SP   ; DSP
  CALL  @HDOT
  LEA   AX,[BP+4]
  CALL  @HDOT   ; RSP
  CALL  @SPDOT

  ;ROT H.
  POP   AX
  CALL  @PUSH   ; DSP[2]  3
  POP   AX
  PUSH  AX
  CALL  @HDOT   ; DSP[3] .

  CALL  @POP    ; DSP[2] . 3
  PUSH  AX
  CALL  @HDOT
  MOV   AX,BX   ; DSP[1] .
  CALL  @HDOT
  
  CALL  @POP    ; RETADR BACK  2
  PUSH  AX
  MOV   AX,[BP]
  CALL  @HDOT  
  MOV   AX,CX
  CALL  @HDOT
  MOV   AX,DX
  CALL  @HDOT
  CALL  @SPDOT
  MOV   AX,PW[VAL_+_DP]
  CALL  @HDOT

  MOV   AX,[SI]
  CALL  @STRID
  CALL  @STROUT
  CALL  @READBIOS
@POP:
  XCHG  SP,BP
  POP   AX
  XCHG  SP,BP
  RET
  
@PUSH:
  XCHG  SP,BP
  push  Ax
  XCHG  SP,BP
  RET
  
; -------------------
; Peek and Poke
; -------------------

primitive '@',_fetch,0
  mov bx,PW [bx]
  jmp next

primitive '!',_store ,0
  pop PW [bx]
  jmp @DROPW

prim 'C@',_PEEKB,0,@PEEKB

; -------------------
; Inner Interpreter
; -------------------

next:   
        CALL  @DBG
        MOV    DI,[SI]
        CMPSW
        jmp PW [di-2]

; -------------------
; Flow Control
; -------------------

PRIM 'BYE',_BYE,0,0

primitive '(?BR',_zero_branch,0
  test bx,bx
  pop bx
  je @JUMP
  lodsw
  jmp next

primitive '(BR',_branch,0
@JUMP:        
  mov si,PW [si]
  jmp next

prim 'EXEC',_execute,0,@EXEC
@PERFORM:
  MOV BX,[BX]
@EXEC:
  LEA di,[bx+2]
  pop bx
  jmp PW [di-2]

prim 'PERFORM',_PERFORM,0,@PERFORM

primitive '(RET',_RET,0
@RET:        
        mov si,PW [bp]
@RDROP:        
        inc bp
        inc bp
        jmp next

; -------------------
; String
; -------------------

  primitive 'COUNT',_count,0
  inc bx
  push bx
  DEC BX
@PEEKB:        
  mov bl, PB[bx]
  mov bh,0
  jmp next

  primitive '>NUMBER',_to_number,0
  ;MOV AX,Pw[val_+_DP]
  ;CALL  @STROUT
 
  pop di
  pop cx
  pop ax
to_numl: 
  test bx,bx
    je to_numz
  push ax
  mov al,Pb[di]
  ;AND al,0DFH
to_nums: 
  cmp al,'9'+1
    jc to_numg
  cmp al,'A'
    jc to_numh
  sub al,7
to_numg: sub al,48
  mov   ah,0
  cmp   al,Pb[val_+_base]
    jnc to_numh
  xchg  ax,dx
  pop   ax
  push  dx
  xchg  ax,cx
  mul   Pw[val_+_base]
  xchg  ax,cx
  mul   Pw[val_+_base]
  add   cx,dx
  pop   dx
  add   ax,dx
  dec   bx
  inc   di
    jmp   to_numl
to_numz: 
  push  ax
to_numh: 
  push  cx
  push  di
    jmp next

; -----------------------
; Terminal Input / Output
; -----------------------

  primitive 'ACCEPT',_accept,0
  
  ;CALL @DBG
  CALL @CRDOT
  MOV   AL,'>'
  CALL @COUT
  
  POP  DI
  xor  cx,cx
acceptl:
  call acc 
  jnC  acceptl
  jmp next
 
acc1:	
  MOV   AL,7
  call outchar
acc:
  call getchar   
	cmp  al,8
        jne  acc2
        jCXz   acc1
  CLC
  dec  Cx
  dec  DI
	push ax
  call outchar
  mov  al,' '
outc2:
  call outchar
  pop  ax
outchar:
@COUT:
  MOV   AH,0EH
  INT   10H
  RET

;  xchg ax,dx
;  mov  ah,2
;  int  021h
;  ret
acc2:	
  cmp  al,13
        jne  acc3
  mov  Bx,Cx
  STC
  RET
;  mov ah,10
;  xchg  al,ah
;  push ax
;  mov al,ah
;  jmp outc2

acc3:	
  cmp  al,' '
        jc   acc1
  STOSB
  inc  Cx
  jmp outchar

@READBIOS:
  XOR   AX,AX
  INT   16H
  RET
  
primitive 'WORD',_word,0
        mov di,PW [val_+_dp]
        push di
        mov dx,bx
        mov bx,PW [val_+_tib]
        mov cx,bx
        add bx,PW [val_+_to_in]
        add cx,PW [val_+_number_tib]
wordf:  cmp cx,bx
        je wordz
        mov al,PB [bx]
        inc bx
        cmp al,dl
        je wordf
wordc:  inc di
        mov PB [di],al
        cmp cx,bx
        je wordz
        mov al,PB [bx]
        inc bx
        cmp al,dl
        jne wordc
wordz:  mov PB [di+1],32
        mov ax,PW [val_+_dp]
        xchg ax,di
        sub ax,di
        mov PB [di],al
        sub bx,PW [val_+_tib]
        mov PW [val_+_to_in],bx
        pop bx

;  MOV AX,BX
;  CALL  @STROUT
  jmp next

  primitive 'EMIT',_emit,0
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

  primitive 'FIND',_find,0
  PUSH SI
  PUSH   PW  _last+VAL_
findL:
  POP   SI
  MOV   DX,SI
  MOV   CX,DX
  jCXz  findnf
  LODSW
  PUSH  AX    ; LINK TO NEXT
  
  MOV   DI,BX
  LODSB
	AND  AX,31
  SCASB       ; LENGTH = ?
  JNE   findL
  
  XCHG  CX,AX
  rep  cmpsb
  jNe   findL
  
  POP   AX      ; DISCARD LINK
  INC   CX      ; FLAG FOUND
  mov   BX,si
  MOV   SI,DX
  TEST  PB [SI+2],080H  ; IMMEDIATE ?
  JZ    FINDNF
  NEG   CX
  
findnf:
  POP  sI
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

  colon 'CREATE',_create,0
    dw _dp,_fetch,_last,_fetch,_comma
    dw _last,_store,_Bl,_word,_count
    dw _plus,_dp,_store,_0,_comma
    dw _do_semi_code
dovar:
  XCHG  AX,DI
  jmp @PUSHW

  primitive '(;CODE)',_do_semi_code,0
  mov di,PW [val_+_last]
  mov al,PB [di+2]
  and ax,31
  add di,ax
  mov PW [di+3],si
  jmp @RET

; -----------------------
; Constants
; -----------------------

  colon 'CONST',_constant,0
    dw _create,_comma,_do_semi_code
doconst: 
  mov Ax,PW [di]
  jmp @PUSHW

; -----------------------
; Outer Interpreter
; -----------------------

final:
        colon 'INTERPRET',_interpret,0
interpt dw _number_tib,_fetch,_to_in,_fetch,_equals,_zero_branch,intpar ; NOT EMPTY ?
        
        ;DW  _LIT,'>',_EMIT
        DW _tib,_lit,50,_accept,_number_tib,_store,_0,_to_in,_store
        
intpar  dw _Bl,_word,_find,_dup,_zero_branch,intnf    ; WORD NOT FOUND ?
        
        DW _state,_fetch,_equals,_zero_branch,intexc,_comma,_branch,intdone
intexc  dw _execute,_branch,intdone                         ; USE THE WORD
        
        
intnf   dw _dup,_ROT,_count,_to_number,_zero_branch,intskip ; NUMBER OK

        DW _state,_fetch,_zero_branch,intnc                 ; DO NOT NEED CLEENUP
        DW _last,_fetch,_dup,_fetch,_last,_store,_dp,_store ; CLEAR GARBIGE WORD
intnc   dw _abort

intskip dw _drop, _drop, _state, _fetch,_zero_branch,intdone
        DW _lit,_lit,_comma,_comma    ; COMPILE NUMBER
intdone dw _branch,interpt

freemem:

MyCseg  ends
        end  Start

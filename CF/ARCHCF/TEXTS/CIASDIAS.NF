( $Id: asi86.frt,v 2.0 2000/08/02 08:37:49 albert Exp $ )
( Copyright{2000}:)
( Albert van der Horst, HCC FIG Holland by GNU Public License)
( ############## 8086 ASSEMBLER ADDITIONS ################### )
( The patch ofr the assembler doesn't belong in the        )
( generic part. To be used when overruling, e.g. prefix)
\ : lsbyte, 0 $100 U/ SWAP C, ;
: A_W, lsbyte, lsbyte, DROP ;
\ : L, lsbyte, lsbyte, lsbyte, lsbyte, DROP ;
: A_IS, C, ;
( Because there are no fixups-from-reverse that are larger than)
( 2 bytes this trick allows to debug -- but not run -- 8086    )
( assembler of 32 bits system. The pattern 00 01 {$100} to     )
( fixup the last bit becomes 00 00 00 01 {$1000000} on a 16 bit)
( system)
\ : 0s 2 ROTLEFT ;  ." WARNING : testing version on 8086"
: 0s NOP ;
( By defining 0s as a NOP you get a normal 8086 version        )
( ############## 8086 ASSEMBLER PROPER ####################### )
( The decreasing order means that a decompiler hits them in the)
( right order                                                 )

( cell relative to IP)
( Build an instruction given by BA BY BI the OPCODE and COUNT)
\ >BI CELL+ >BY >BA 3 >CNT 4 >DIS 5 
\ : COMMAER CREATE  , 0 , , , , , DOES> REMEMBER COMMA ;

0 0 CELL+  0 T! T@  $8000 ' A_W,  CFA  COMMAER (RX,)
( byte relative to IP)
0 1        0 T! T@  $4000 ' C,    CFA  COMMAER (RB,)
(  Segment: WORD     )
0 2        0 T! T@  $2000 ' A_W,  CFA  COMMAER SG,
( port number ; byte )
0 1        0 T! T@  $1000 ' C,    CFA  COMMAER P,
( immediate byte data, obligatory size)
0 1        0 T! T@   $800 ' C,    CFA  COMMAER IS,
( immediate data : cell)
0 0 CELL+  2 T! T@   $400 ' A_W,  CFA  COMMAER IX,
  ( immediate byte data)
0 1        1 T! T@   $400 ' C,    CFA  COMMAER IB,
  ( immediate data : address/offset )
0 0 CELL+  8 T! T@   $200 ' A_W,  CFA  COMMAER X,
  ( immediate byte : address/offset )
0 1        4 T! T@   $200 ' C,    CFA  COMMAER B,
  ( obligatory word     )
0 2        0 T! T@   $100 ' A_W,  CFA  COMMAER W,
( Bits in TALLY  1 OPERAND IS BYTE     2 OPERAND IS CELL  )
(                4 OFFSET   DB|        8 ADDRESS      DW| )
( By setting 20 an opcode can force)
( a memory reference, e.g. CALLFARO  )
(               10 Register op        20 Memory op      )
(               40 D0                 80 [BP]           )
( Only valid for 16 bits real mode  A0JUL04 AvdH )

$20 0 $0700 0s T!  $0100 0s 0 8 
FAMILY|R X/S X/D P/S P/D /SI /DI -- /BX

( Fits in the hole, safe incompatibility)
$A0 0 $0700 0s  $0600 0s FIR /BP
$12 0 $0700 0s T! $0100 0s 0 8 
FAMILY|R AX| CX| DX| BX| SP| BP| SI| DI|
$11 0 $0700 0s T!  $0100 0s 0 8 
FAMILY|R AL| CL| DL| BL| AH| CH| DH| BH|

 $60 $000  $C000 0s T! $0000 0s FIR      D0|
 $24 $200  $C000 0s T! $4000 0s FIR      DB|
 $28 $200  $C000 0s T! $8000 0s FIR      DW|
 $10 $000  $C000 0s T! $C000 0s FIR      R|
 $08 $200  $C700 0s T! $0600 0s FIR      MEM|
( Overrules D0| [BP] )

02 00 $3800 0s T!  $0800 0s 0 8 
FAMILY|R AX'| CX'| DX'| BX'| SP'| BP'| SI'| DI'|
01 00 $3800 0s T!  $0800 0s 0 8 
FAMILY|R AL'| CL'| DL'| BL'| AH'| CH'| DH'| BH'|

00 00 $02 0s T!   0002 0s 0 0s 2 
FAMILY|R F| T|
01 00 $01 0s   0 0s FIR B|
02 00 $01 0s   1 0s FIR W|

( --------- two fixup operands ----------)
00  00 $FF03 T!   0008 $0000 8 
2FAMILY, ADD, OR, ADC, SBB, AND, SUB, XOR, CMP,
00  00 $FF01 T!   0002 $0084 2 
2FAMILY, TEST, XCHG,
$00 00 $FF03  $0088 2PI MOV,
$22 00 $FF00  $008D 2PI LEA,
$22 00 $FF00 T!   0001 $00C4 2 
2FAMILY, LES, LDS,
00 $0400 $C701  $00C6 2PI MOVI,

( --------- one fixup operands ----------)
$12 00 07 T!   08 $40 4 
1FAMILY, INC|X, DEC|X, PUSH|X, POP|X,
$12   00  07  $90 1PI XCHG|AX,
$11 $0400 07  $B0 1PI MOVI|BR,
$12 $0400 07  $B8 1PI MOVI|XR,
00  $0400 $C701  T!  $800 $80 8 
2FAMILY, ADDI, ORI, ADCI, SBBI, ANDI, SUBI, XORI, CMPI,
02  $0800 $C700 T!  $800 $83 8 
2FAMILY, ADDSI, -- ADCSI, SBBSI, -- SUBSI, -- CMPSI,
00 00 $C701 T!
 $0800 $10F6 6 
2FAMILY, NOT, NEG, MUL, IMUL, DIV, IDIV,
 $0800 $00FE 2 
2FAMILY, INC, DEC,
00 $0400 $C701  $00F6 2PI TESTI,
02  00   $C700  $008F 2PI POP,
02  00   $C700  $30FE 2PI PUSH,
02  00   $C700 T!  $1000 $10FF 2 
2FAMILY, CALLO, JMPO,
$22 00   $C700 T!  $1000 $18FF 2 
2FAMILY, CALLFARO, JMPFARO,

( --------- no fixup operands ----------)
01 00 $20100 0s T! T@ $0000 0s xFI B'|
02 00 $20100 0s T! T@ $0100 0s xFI W'|
8 $0200 $201 T!    02 $A0 2 1FAMILY, MOVTA, MOVFA,
0 $0400 $201 T!
 08 $04 4 1FAMILY,  ADDI|A, ORI|A,  ADCI|A, SBBI|A,
 08 $24 4 1FAMILY,  ANDI|A, SUBI|A, XORI|A, CMPI|A,
00 00 $201 $A8 1PI TESTI|A,  
00 00 $201 T! 02 $A4 6 1FAMILY, MOVS, CMPS, ` STOS, LODS, SCAS,
0 $1000 $201 T! 2 $E4 2 1FAMILY, IN|P, OUT|P,
0 $0000 $201 T! 2 $EC 2 1FAMILY, IN|D, OUT|D,

( --------- special fixups ---------- )

00 00 $10001 0s T!
$0100 0s 0 0s 2 FAMILY|R Y| N|
00 00 $E   0s   T!
$0200 0s 0 0s 8 FAMILY|R O| C| Z| CZ| S| P| L| LE|
00 $4000 $10F T! $70 1PI J,

00 00 $18 0s T!  $0800 0s 0 0s 4 
FAMILY|R ES| CS| SS| DS|
00 00 $18    T!   01 06 2 
1FAMILY, PUSH|SG, POP|SG,
02 00 $DF02  $8C  2PI MOV|SG,

00 00 $10002 0s 00 0s xFI 1|
00 $800 $10002 0s 02 0s xFI V|
00 0 $1C703 T!  $0800 $00D0 8 
2FAMILY, ROL, ROR, RCL, RCR, SHL, SHR, -- SAR,

( --------- no fixups ---------------)

$01 $0400 00   $CD 1PI INT,
$0A $2200 00   $9A 1PI CALLFAR,
$0A $2200 00   $EA 1PI JMPFAR,
$02 $0100 00 T!    08 $C2 2 
1FAMILY, RET+, RETFAR+,
$04 $8000 00 T!    01 $E8 2 
1FAMILY, CALL, JMP,
$00 $4000 00   $EB 1PI JMPS,
$00 $0000 00 T!  
 08 $26 4 1FAMILY, ES:, CS:, SS:, DS:,
 08 $27 4 1FAMILY, DAA, DAS, AAA, AAS,
 01 $98 8 1FAMILY, CBW, CWD, -- WAIT, PUSHF, POPF, SAHF, LAHF,
 08 $C3 2 1FAMILY, RET,  RETFAR,
 01 $CC 4 1FAMILY, INT3, -- INTO, IRET,
 01 $D4 4 1FAMILY, AAM, AAD, -- XLAT,
 01 $E0 4 1FAMILY, LOOPNZ, LOOPZ, LOOP, JCXZ,
 01 $F0 6 1FAMILY, LOCK, -- REPNZ, REPZ, HLT, CMC,
 01 $F8 6 1FAMILY, CLC, STC, CLI, STI, CLD, STD,

( ############## 8086 ASSEMBLER PROPER END ###################)
( You may always want to use these instead of (RB,)
    : RB, ISS @ - (RB,) ;      : RX, ISS @ - (RX,) ;
(   : RW, ISS @ - (RW,} ;      : RL, ISS @ - (RL,} ;          )
(   : D0|  ' [BP] REJECT D0|  ;                               )
(   : [BP] ' D0|  REJECT [BP] ;                               )
(   : R| ' LES, REJECT ' LDS REJECT R| ;                      )
\ ASSEMBLER DEFINITIONS
(   : NEXT                                                    )
(        LODS, W1|                                            )
(        MOV, W| F| AX'| R| BX|                               )
(        JMPO, D0| [BX]                                       )
(     )
( ############## 8086 ASSEMBLER POST ######################## )
CODE: JAN  MOV|SG, T| ES| R| AX|  ;CODE
\ ADD, OR, ADC, SBB, AND, SUB, XOR, CMP,
' JAN EVEN  CR 10 DUMP


0 VALUE IDP   : <FIX H TO IDP ; : |IDP IDP EX TO IDP ;
: IDP- |IDP 1- ; : C@- 1 - DUP C@ ; 
: C| IDP- IDP C@ OR IDP C! ; : RB, HERE 1+ - : IB, C, ; 
: MEM, , ; : R, HERE 2+ - , ; : W, , ; : SEG, , ;   
: POST, CSTR C, ;       : FIX| C@- C| ; : SPLIT 1B U/MOD SWAP ;
: 1PI CREATE C, DOES>  POST, DROP ALIGNED ;                             
: 2PI CREATE C, C, DOES> POST,  POST, DROP ;                  
: 1FI CREATE C, DOES> <FIX 1+ FIX| DROP ALIGNED ;                      
: 2FI CREATE C, C, DOES> <FIX 2+ FIX| FIX| DROP ;              
: 1FAMILY, .STR| DUP 1PI : OVER+ OVER + ;                         
: 1FAMILY| .STR| DUP 1FI OVER+ ;                 
: 2FAMILY, .STR| DUP SPLIT 2PI OVER+ ;           
: 2FAMILY| .STR| DUP SPLIT 2FI OVER+ ;           
 8   0 4 1FAMILY| ES| CS| SS| DS|    
 1   4 2 1FAMILY, PUSHS, POPS,  
 8 $26 4 1FAMILY, ES:, CS:, SS:, DS:,                        
 8 $27 4 1FAMILY, DAA, DAS, AAA, AAS,                            
 1 0 2 1FAMILY| B1| W1|   08 04 8 
1FAMILY, ADDAI, ORAI, ADCAI, SBBAI, ANDAI, SUBAI, XORAI, CMPAI, 
2 $A0 2 1FAMILY, MOVTA, MOVFA,
1 0 2 1FAMILY| Y| N|   
2 0 8 1FAMILY| O| C| Z| CZ| S| P| L| LE|
 $70 1PI J,  ( As in J, L| Y| <CALC> S, )                        
 1 0 8 1FAMILY| AX| CX| DX| BX| SP| BP| SI| DI|                 
 08 $40 4 1FAMILY, INCX, DECX, PUSHX, POPX,    $90 1PI XCHGX,     
 ( C7) 6 1FI MEM|   ( C0) $40 00 4 1FAMILY| D0| DB| DDW| R|      
( 38) 08 $C0 8 1FAMILY| AX1| CX1| DX1| BX1| SP1| BP1| SI1| DI1|
 ( 07) 1 0 8 
1FAMILY| [BX+SI] [BX+DI] [BP+SI] [BP+DI] [SI] [DI] [BP] [BX]
1 0 8 1FAMILY| AL| CL| DL| BL| AH| CH| DH| BH|                 
1 0 2 2FAMILY| B| W|   2 0 2 2FAMILY| F| T|                     
8 0 8 2FAMILY, ADD, OR, ADC, SBB, AND, SUB, XOR, CMP,           
2 $84 2 2FAMILY, TEST, XCHG,   0 $88 2PI MOV,                     
( 00FD) 0 $8C 2PI MOVSW,   ( 00FE) 0 $8D 2PI LEA,                 
( IRR,egular)  ( FF) $9A 1PI CALLFAR,  ( FE) $A8 1PI TESTAI, 
1 $98 8 1FAMILY, CBW, CWD, IR2, WAIT, PUSHF, POPF, SAHF, LAHF,   
2 $A4 6 1FAMILY, MOVS, COMPS, IR3, STOS, LODS, SCAS,       
8 $B0 2 1FAMILY, MOVRI, MOVXI,                                  
8 $C2 2 1FAMILY, RET+, RETFAR+,  8 $C3 2 1FAMILY, RET,  RETFAR,   
1 $C4 2 1FAMILY, LES, LDS,  0 $C6 2PI MOVI,  0 $CD 2PI INTI,       
1 $CA 4 1FAMILY, INT3, IRR, INTO, IRET,                          
1 $D4 4 1FAMILY, AAM, AAD, IL3, XLAT,                            
1 $E0 4 1FAMILY, LOOPNZ, LOOPZ, LOOP, JCXZ,                      
2 $E4 2 1FAMILY, INAI, OUTAI,  2 $EC 2 1FAMILY, INAD, OUTADI,     
1 $E8 2 1FAMILY, CALL, JMP,  $EA 1PI JMPFAR,  $EB 1PI JMPS,        
1 $F0 6 2FAMILY, LOCK, ILL, REP, REPZ, HLT, CMC,                 
1 $F8 6 2FAMILY, CLC, STC, CLI, STI, CLD, STD, ( 38FE)           
$800 $80 8 
2FAMILY, ADDI, ORI, ADCI, SBBI, ANDI, SUBI, XORI, CMPI,
$800 $83 8 
2FAMILY, ADDSI, IL4, ADCSI, SBBSI, IL5, SUBSI, IL6, CMPSI,
$800 $D0 8 2FAMILY, ROL, ROR, RCL, RCR, SHL, SHR, IL6, RAR,       
$800 $10F6 6 2FAMILY, NOT, NEG, MUL, IMUL, DIV, IDIV,             
00 $F6 2PI TESTI, $800 $FE 2 2FAMILY, INC, DEC,                    
( 38FF) 00 $8F 2PI POP,  $30 $FE 2PI PUSH,                         
$800 $10FF 4 2FAMILY, CALLO, CALLFARO, JMPO, JMPFARO,             
								
: CODE ALIGNED HERE 1+ =: !CSP ; 
: C; ?CSP ; 
: NEXT                                                          
     LODS, W1|                                                  
     MOV, W| F| R| BX| AX1|                                     
     MOV, W| F| BX1| DX|                                        
     INCX, DX|                                                  
     JMPO, D0| [BX]                                             
 ;                                                              
CODE TEST NEXT C; 
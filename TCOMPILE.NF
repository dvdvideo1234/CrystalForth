$E7B IS SOURCE  META @OK  vOK.  META (BE EMIT   META (AC ACCEPT
' , 3 OPER[] ! PAGE  META (ERR vERR HERE $8000 ' HERE 2+ EXEC
0 , : ;@ + EX @- DROP; ,< : @@ 4 ;@ @- ; : @@@ 6 ;@ @- @- ;
=H THERE ' HERE @@ , , , { HERE} : CODE: HERE 2+ =, ;
HERE $E8 C, #DOES HERE  2+ - , >, C@ C, ;   DUP =, #CAL, $E8 ,
DUP =, #JMP, $E9 , DUP =, JMPS, $EB , =, RET, $C3 ,
: DOES, 0 : DOES- #DOES SWAP - : CALL, #CAL, : ,R HERE 2+ - , ;
     HERE DOES, >, C@ HERE SWAP DOES- >, ;  DUP DUP  =, 0]>
 0 C, =, 1]> 1 C, =, 2]> 2 C, : ;A, EX : A, 3 OPER[] @EXEC ;
: W, ;A, STR ; : RECURCE` ;A, : LATEST DICT : N>C CSTR + @ ;
: `;code POP : TOBE LATEST ! ;  0]> : `(TO @ ' + ;
1]> RECURCE A, ; 2]> RECURCE EXEC ; =, TO  =, TO`  =, 'TO  2 ,
' TO STR =, AT STR =, AT`   @ =, 'AT  4 ,
\ : <H HERE   THERE TO HERE TO THERE ; ' <H =: H>
LIKE ;` =, DOES>` >, `;code DOES, ,< {  DOES !}

: WAS ' : BD@ 2+ @ ;    LIKE #,` : (,) =H  #, , , : Z, 0 , ;
: (: =H : ;, EX , ;  ' KEY 2+ 2+ @ (,) (VAR`  LIKE bl (,) (CON`
: CONST (: (CON` ;  ' LIT (,) (LIT` : ;Z, EX Z, ; : W. STR H. ;
: VARIABLE ;Z, : CREATE =H (VAR` ;     LIKE vERR (,) (DEF`
: DEFER (: (DEF` ;  WAS HERE  (,) (SET`  LIKE HERE (,) (CON2`
: VALUE (: (CON2` (SET` ; ' HANDLES STR (,) (STK>` @ (,) (>STK`
LIKE vERR  1- (,) (DEF2`     : VECTOR ,  (: (DEF2` (SET` ;
: STACK (: (STK>` (>STK` (VAR` TUCK , , ;
  TBL TIB + DUP TBL 2/ + DUP TBUF  STACK CSTK>   STACK <CSTK
0 VALUE H-PTR  0 VALUE T-HI  0 VALUE T-LO  0 VALUE XK
: `HR HERE TO H-PTR ; LIKE KEY (,) (DEF3` WAS HERE 1- (,) (SET2`
 : VQUAN (: (DEF3` (SET2` (VAR` ; \  ' vINIT @@ 2 (:) POINT ,
LIKE bl 2- (,) (CON3` : QUAN (: (CON3` (SET2` (VAR` ;
LIKE bs (,) (BCON`    : CONST.C (BCON` (SET` ;
: MRK>` HERE Z, ;

' EXIT  (,) ;T         ' DROP (,) DROP`      ' (IF  (,) (IF`
' (JUMP (,) (JMP`      ' ;GO  (,) ;GO`       ' (#IF (,) (#IF`
' (NEXT (,) (NXT`      ' PUSH (,) PUSH`     ' (CALL (,) (CALL`
' (OF   (,) (OF`       ' POP  (,) POP`       ' J    (,) J`
' ("    (,) ("`        ' (A"  (,) (A"`       ' (."  (,) (."`
: SUCSTR SWAP XEP CSTR ;
: `THEN EX : THEN` CSTK> : RES>` HERE SWAP! `HR ;









: AHEAD` (JMP` : MARK>` MRK>` TO CSTK> ;
: FOR`   PUSH`  : FOR>`  AHEAD` : BEGIN` HERE TO <CSTK ;
: NEXT` THEN`   : <NEXT`  (NXT` : <BEG` <CSTK , `HR ;
: STK? AT <CSTK ITEMS AT CSTK> ITEMS + ;
: `;STK> CSTK> EX TO CSTK> ;    : `;<STK <CSTK EX TO <CSTK ;
: "` ("` : (",) '"  : (?",)  WORD : CSTR, CSTR
: STR, ;HERE (S! DROP ;  : A"` (A"` (",) ;   : ."`  (."` (",) ;
: `(A,) `HR DUP ;, : T-RANGE? T-LO T-HI WITHIN 0= A" RANGE!" ;
' `(A,) 3 OPER[] !  1 TO T-LO  : `BLK.  BLK . ;







\ EXIT \ TO 146 BLOCK MOVED ORIGINAL 15
: .( ') WORD ". ;   : ,T bl (?",) ;  : [ID] ;[] ". ;
: CSWAP>` `;STK> `;STK> SWAP ;  : <CSWAP` `;<STK `;<STK SWAP ;
: ELSE` AHEAD` CSWAP>` THEN` ;  : FOR?`  (NXT` MARK>` ;
: IF` (IF` MARK>` ; : CALL`  (CALL` MARK>` ; ' IF`   =: WHILE`
: #IF` (#IF` MARK>` ; : OF`  (OF` MARK>` ;
: REPEAT` `THEN : AGAIN` (JMP` <BEG` ; : UNTIL` (IF` <BEG` ;
: CASE` 0 TO CSTK> ; : `TOK DROP EX TOKEN? ;
: ;CASE` DROP` BEGIN CSTK> #IF  TO CSTK> THEN` REPEAT DROP ;
: M: ';  : ?M: CREATE (?",) DOES> SEVAL ; { MACROSES }
: .B `BLK. 1K LTIB - 1L U/ . KEY : DROP DROP ;  LIKE 2DROP; 1+
 =, 2DROP $247 =: RDROP   : <>0; IF RDROP THEN ;
: EXIST? LTIB PUSH LOCATE POP TO LTIB NIP ; 0]> `TOK  RECURCE
 0; TBUF [ID] BLK 0; `BLK. ;   =, SAME? ' SAME? $289 !


: '(, ' DEFER ;        \ TAIL RECURCION OPTIMIZER
0 VECTOR vIS:? : H- ;DROP : @H- ;HERE @- ;
: `:=? @ LIT ,< LIKE Z, , >, = ;  ' `:=? TO vIS:?
0 VECTOR vTOC>ADR      ' 2+ TO vTOC>ADR
: ;;` ;T  STK? <>0; : ,<` ,<` ;
: `x??x EX #?? : `(@H, @H- vTOC>ADR TO <CSTK ;
: `?? `x??x : `H@:? HERE @- DROP vIS:? ;        : ;THEN` `THEN
: ;` `H@:? ;;` 0; H- `(@H, AGAIN` ;          : ?;` `?? UNTIL` ;
: #?;` `?? (#IF` <BEG` ;        : :;` `??  ;GO` <BEG` ;

\ 17 LOAD        143 145 THRU  \ 137 LOAD
\ 137 LOAD   114 121  THRU      \ 17 LOAD  \ 144 LOAD
\ 206 LOAD    \ ASSEMBLER      : .. '. EMIT ;



\ : NIP SWAP : DROP DROP : NOP ; \ DICTIONARY SEARCH
: 3RDR; RDROP : 2RDR; RDROP : RDR; RDROP ; : C@I  J C@ ;
: NAME> CSTR + ;  : (>NEXT NAME> 2+ ;     : (TYP N>C @ ;
: WAS@ ' : BDY@ 2+ @ ;          : `H ." `$" H. ;
: CORA DUP C@ 1+ : -TEXT
      FOR PUSH CSTR XCHG CSTR POP = IF CSWAP> NEXT
      -1 PUSH THEN  DROP DROP POP 1+ ;
: ;FND DICT : ;FND2 BEGIN PUSH C@I
         WHILE   DUP J EXECUTE POP  (>NEXT  REPEAT  0  2RDR; ;
: C>N? ;FND J N>C - : `C <>0; DROP J J 3RDR; ;
: `CN 2- C>N?  : `N  RDR; ?; POP ID.   ID. RDR; ;
: `TO. `CN ,< ,T TO   : `AT. `CN ,< ,T AT




: B>N? ;FND J  N>C BDY@ - <>0;           \ CALL
  J (TYP (LIT ,< LIKE (VAR` , >, - `C ;  \ CALL   -  `C ;
: `SHN3 SPACE 3 LOOPS ROT DUP H. ;
: SHN \ THEN THEN
      CR POP J H. PUSH J H. I H. `SHN3 I @
    CALL { ?ID.} KEY     : DROP; DROP : NOP ;

: ?ID. THEN C>N? 0= ID. ?; `TO. `AT. 2+ 2+
        B>N? `H ?; CSTR 1- ;SPC    TYPE ;
: .ALL ;2DROP ;FND J (TYP : >PRINT = 0; : JID J ID. ;

: .CODE ;2DROP ;FND DROP J N>C @+ >PRINT ;
: .WORDS ;2DROP ;FND DUP >PRINT ;
: -FIND TOKEN? : FND  ;FND J CORA `C ;


\ FAMILY #FAMILY  THRU +THRU +LOAD SHN -
: FAMILY ' ;2DROP PUSH FOR DUP J EXEC OVER + NEXT RDR; ;
: `TMS POP XCHG : `TIMES PUSH : TIMES; FOR J EXEC NEXT RDR; ;
: TIMES SWAP `TIMES ;   : 'TIMES ' `TIMES ;  ' `TMS  (,) TIMES`
$269 =: NUM? : >NUM TOKEN? NUM? ;
: #FAMILY ' PUSH FOR >NUM J EXEC NEXT RDR; ;
: THRU  ;RANGE LOOPS DXEP+ : LOAD DUP '# EMIT . LOAD ;
: +THRU ;RANGE LOOPS DXEP+ : +LOAD BLK + LOAD ;
\ 1 +LOAD  \ DEBUGGER
\ 2 +LOAD  \ BLOCK SEARCH






\ DEBUGGER  : ;[] '[ EMIT EX '] EMIT ; : ;CR EX CR ;
 HERE DOES, >, PUSH XCHG CSTR POP SCAN 1+ 0;  ;SPC ;[]
 DUP ". CSTR + ;     =, `?STR 3 C, >, (A"  (" (." ,<
0 VALUE `WW : `;WW `WW EX TO `WW ;  : `STR EX DUP 2- @ `?STR ;
: `:ID. DUP C>N? NOP #?; XEP OVER CALL ." : " ID. ;THEN : ``CR-H
 CR H. ; : `CR-H `:ID. ``CR-H ?; ;  : `CR- `:ID. DROP; ?; ;
: SEE ' : @SEE TO `WW : L `;WW bs LOOPS
: WW `CR-H @+ OVER H. : `W0 `STR XEP ?ID. ;
: `;TYPE  DUP 1H - 1H SPACE ;[] TYPE ;  \ : BE ' ! ;
: WDUMP bs ?DU ;DROP LOOPS CR DUP H. SPACE bs LOOPS STR H. ;
: DUMP 1H ?DU ;DROP : DU LOOPS CR DUP H. SPACE `;TYPE :;
  1H LOOPS CSTR B. ; \ SPC W>B 1H U/MOD  TWICE  DIG. ;
: HACK ' : @HACK TO `WW : HL CR bs LOOPS `;WW `CR- @+ `W0 ;
: -HL `WW 23 - @HACK ;  : .HL `WW H. ;


\   SEARCHBUF C@ TO BUF-LEN  BLOCK-SEARCH ;
: SIT ;   238 CONST `LASTBLOCK     80 1 - CONST `SBUFSIZE
D0 0 4 FAMILY VALUE `INBLKCNT  `BUFLEN  `BLKPOS `OLDSCR
CREATE `GETBUF `SBUFSIZE 1 + DUP ALLOT  CREATE `SEARCHBUF ALLOT
\ : CORA DUP C@ 1+ : -TEXT FOR PUSH CSTR XCHG CSTR POP =
\       IF CSWAP> NEXT -1 PUSH THEN  DROP DROP POP 1+ ;
: `GETBLOCK `OLDSCR SCR DUP TO `OLDSCR - IF -1 TO XY THEN
    SCR BLOCK 1K `BUFLEN - XY - TO `INBLKCNT TO `BLKPOS ;
: `BLOCKSEARCH  SCR `LASTBLOCK U< 0; `GETBLOCK `INBLKCNT  FOR
 `SEARCHBUF 1+  XY 1+ >XY `BLKPOS XY + `BUFLEN -TEXT IF CSWAP>
 NEXT SCR 1+ TO SCR RECURCE ; THEN XY `BUFLEN RDROP + >XY E ;
: `GETSTRING  WORD `GETBUF      : PLACE OVER C@ 1+ CMOVE ;
: S bl AHEAD    : S" '"  AHEAD  : ?S TOKEN? 1+ C@ THEN THEN
    `GETSTRING `GETBUF C@ IF   `GETBUF `SEARCHBUF PLACE  THEN
    `SEARCHBUF C@ TO `BUFLEN  `BLOCKSEARCH ;  : S0! 0 TO SCR ;
   .( ALL )    ' (BK TO KEY


 : N>LINK N>C 2- ;
 : V>LINK     2- ;
 0 VALUE FENCE

 : forget DUP FENCE  U< A" fence !" PUSH ( ����������� - R@ )
 BEGIN VOCLINK       ( ������� ������ �� ������ �� ���-��������� ������)
  @ ?DUP R@ U<        ( ��� ��-����� �� � �� ��������� ?)
 0= WHILE @ VOCLINK !  ( ������ �� � - �������� �� � ������� ��� ��������)
 REPEAT
 VOCLINK             ( ���� ���� �� ���������� ������ ��-����� �������)
 BEGIN DUP 2-        ( �� �� ������� ������ � � ������ �� ����������)
   BEGIN @ DUP       ( - ������ �� ������ �� ���-��������� ���� �� �������)
     R@ U<           ( - ��� ��-����� �� � �� ��������� ?)
   0= WHILE N>LINK     ( - ������ �� � - ������� ��� ��������)
   REPEAT            ( - ��� � ������� -v ������)
   OVER 2- !         ( ������������ �� ������ )
   @ ?DUP            ( ���� ��������� ������ �� � ?)
 0= UNTIL FORTH        ( FORTH -> CONTEXT)
 TO FORTH POP        ( FORTH -> CURRENT)
 TO HERE             ( R> -> HERE )
 DROP ;              ( VOCLINK @ )


 : FORGET ' C>N DROP forget ;

( HERE TO FENCE)

: WORDS CR 10 TO CSP CONTEXT -1 0 DO @ ?DUP
 IF DUP
    C@ #LEN AND 6 + OUTC + 80 <
    0= IF CR CSP ?DUP
        IF 1- TO CSP
        ELSE 10 TO CSP KEY LOW 27 =
            IF DROP I " LISTED" LEAVE THEN
        THEN
    THEN DUP H. DUP ID.
    1H OUTC OVER MOD ?DUP
    0= IF DUP THEN - DUP 13 < 0= IF DROP 1 THEN
    OUTC 64 < 0= IF 1- THEN SPACES
    N>C 2-
 ELSE CR I " TOTAL" LEAVE THEN
 LOOP ". ."  WORDS = " . ;

: PRUNE VOCLINK
 BEGIN DUP PUSH  ( ������ ��� ��� �������               )
        V>LINK   ( ������������� ����� ������           )
   BEGIN @ DUP   ( ������ � ������� ��� ��� ����        )
     HERE U<     ( ��� ������ � >= HERE                 )
 0= WHILE N>LINK REPEAT  ( �������� �� ���������          )
 DUP R@ V>LINK !
       ( ������� ��� ���������� ���� ���� �� ���� < HERE)
       ( ������ ���� �������� ������ �� �����           )
 ?DUP IF DUP PUSH      ( ��� ������� � ������ - ������� )
 BEGIN N>LINK          ( �������� ����                  )
 @ ?DUP                ( ��� ��                         )
 WHILE DUP HERE U<     ( ������ ������ �� � ����� < HERE)
  IF DUP POP            ( �� ��������� � ������        )
    N>LINK               ( ���������� �� ���������     )
    ! DUP PUSH           (                              )
  THEN                  (                             )
 REPEAT                (                              )
 0 POP N>LINK !        ( ���������� �� ���� �� �������)
 THEN
 POP @ ?DUP 0= UNTIL     ( ������� ������)
 -HEAD  AT HIDDEN OFF
 ;

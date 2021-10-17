\ ctype.fth

((
Copyright (c) 1998, 2003, 2007, 2012
MicroProcessor Engineering
133 Hill Lane
Southampton SO15 5AF
England

tel:   +44 (0)23 8063 1441
fax:   +44 (0)23 8033 9691
email: mpe@mpeforth.com
       tech-support@mpeforth.com
web:   http://www.mpeforth.com
Skype: mpe_sfp

From North America, our telephone and fax numbers are:
       011 44 23 8063 1441
       011 44 23 8033 9691
       901 313 4312 (North American access number to UK office)


To do
=====

Change history
==============
20121220 SFP001 Update for VFX Forth 4.6.
		DocGen overhaul.
))


\ =======
\ *> libc
\ =======

\ **********************************************
\ *S CTYPE - Character Type Query and conversion
\ **********************************************
\ *P This is an implementation of the ANSI "C" library for testing
\ ** and converting individual characters in the standard character
\ ** form.

\ ===============
\ *N C prototypes
\ ===============

\ *C char isalpha( char t );
\ *P Returns non-zero if the character t is either an uppercase or
\ ** lowercase alphabetic character. ('A'..'Z' or 'a'..'z' ).

\ *C char isascii( char t );
\ *P Returns non-zero if the character t is within the 7 bit
\ ** ASCII alphabet.

\ *C char isblank( char t );
\ *P Is the supplied character a blank?

\ *C char iscntrl( char t );
\ *P Is the supplied character a control character?

\ *C char isdigit( char t );
\ *P Is the supplied character a numeric digit?

\ *C char isxdigit( char t );
\ *P Is the supplied character a hexadecimal digit?

\ *C char isgraph( char t );
\ *P Is the supplied character a graphics character?

\ *C char islower( char t );
\ *P Is the supplied character a lower case alphabetic?

\ *C char isupper( char t );
\ *P Is the supplied character an uppercase alphabetic?

\ *C char isspace( char t );
\ *P Is the supplied character a space?

\ *C char ispunct( char t );
\ *P Is the supplied character a puncuation mark?

\ *C char isprint( char t );
\ *P Is the supplied character printable?

\ *C char isalnum( char t );
\ *P Is the supplied character an alphanumeric?

\ *C char tolower( char t );
\ *P Convert char to lower case where possible.

\ *C char toupper( char t );
\ *P Convert char to upper case where possible.

\ =======================
\ *N Forth implementation
\ =======================
\ *P Conversion and testing is controlled by a type table.

\ *[
: _U    $01 c, ; immediate          \  UpperCase
: _L    $02 c, ; immediate          \  LowerCase
: _N    $04 c, ; immediate          \  Numeric
: _S    $08 c, ; immediate          \  WhiteSpace
: _P    $10 c, ; immediate          \  Punctuation
: _C    $20 c, ; immediate          \  Control
: _X    $40 c, ; immediate          \  Xdigit
: _B    $80 c, ; immediate          \  Space
: _CS   $28 c, ; immediate          \  Control or WhiteSpace
: _SB   $88 c, ; immediate          \  Space character
: _UX   $41 c, ; immediate          \  Uppercase or XDigit
: _LX   $42 c, ; immediate          \  Lowercase or XDigit
\ *]

create ctype-table	\ -- addr
\ *G Type table for ASCII characters.
  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  \ 00..07
  $20 c,  $28 c,  $28 c,  $28 c,  $28 c,  $28 c,  $20 c,  $20 c,  \ 08..0F
  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  \ 10..17
  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  $20 c,  \ 18..1F
  $88 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  \ 20..27
  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  \ 28..2F
  $04 c,  $04 c,  $04 c,  $04 c,  $04 c,  $04 c,  $04 c,  $04 c,  \ 30..37
  $04 c,  $04 c,  $10 c,  $10 c,  $04 c,  $04 c,  $04 c,  $04 c,  \ 38..3F
  $10 c,  $41 c,  $41 c,  $41 c,  $41 c,  $41 c,  $41 c,  $01 c,  \ 40..47
  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  \ 48..4F
  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  $01 c,  \ 50..57
  $01 c,  $01 c,  $01 c,  $10 c,  $10 c,  $10 c,  $10 c,  $10 c,  \ 58..5F
  $10 c,  $42 c,  $42 c,  $42 c,  $42 c,  $42 c,  $42 c,  $02 c,  \ 60..67
  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  \ 68..6F
  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  $02 c,  \ 70..77
  $02 c,  $02 c,  $02 c,  $10 c,  $10 c,  $10 c,  $10 c,  $20 c,  \ 78..7F
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,
  0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 , 0 ,

: [ctype]       \ char -- val
\ *G Return the type value of a character.
  ctype-table + c@
;

: _isalpha      \ char -- flag
\ *G Returns non-zero if the character t is either an uppercase or
\ ** lowercase alphabetic character. ('A'..'Z' or 'a'..'z' ).
  [ctype] 0x03 and 0<>
;

: _isascii      \ char -- flag
\ *G Returns non-zero if the character is within the 7 bit
\ ** ASCII alphabet.
  [ctype] 0<>
;

: _isblank      \ char -- flag
\ *G Is the supplied character a blank?
  [ctype] 0x80 and 0<>
;

: _iscntrl      \ char -- flag
\ *G Is the supplied character a control character?
  [ctype] 0x20 and 0<>
;

: _isdigit      \ char -- flag
\ *G Is the supplied character a numeric digit?
  [ctype] 0x04 and 0<>
;

: _isxdigit     \ char -- flag
\ *G Is the supplied character a hexadecimal digit?
  dup _isdigit swap
  [ctype] 0x40 and OR
;

: _isgraph      \ char -- flag
\ *G Is the supplied character a graphics character?
  [ctype] 0x5F and 0<>
;

: _islower      \ char -- flag
\ *G Is the supplied character a lower case alphabetic?
  [ctype] 0x02 and 0<>
;

: _isupper      \ char -- flag
\ *G Is the supplied character an uppercase alphabetic?
  [ctype] 0x01 and 0<>
;

: _isspace      \ char -- flag
\ *G Is the supplied character a space?
  [ctype] 0x08 and 0<>
;

: _ispunct      \ char -- flag
\ *G Is the supplied character a puncuation mark?
  [ctype] 0x10 and 0<>
;

: _isprint      \ char -- flag
\ *G Is the supplied character printable?
  dup _isgraph swap
  _isblank or
;

: _isalnum      \ char -- flag
\ *G Is the supplied character an alphanumeric?
  dup _isalpha
  swap _isdigit or
;

: _tolower      \ char -- 'char
\ *G Convert char to lower case where possible.
  dup _isupper
  if bl + then
;

: _toupper      \ char -- 'char
\ *G Convert char to upper case where possible.
  dup _islower
  if bl - then
;


\ ======
\ *> ###
\ ======

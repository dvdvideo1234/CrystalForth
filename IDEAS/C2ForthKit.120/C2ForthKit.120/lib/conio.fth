\ conio.fth

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

\ ****************************************
\ *S CONIO - Extended Console IO functions
\ ****************************************

\ *P The conio library holds functions relating to console input
\ ** and output which, whilst useful, are not part of the ANSI/ISO
\ ** library standards.

\ *C int kbhit( void )
\ *P Returns non-zero is a key has been pressed, otherwise
\ ** returns 0. This is a non-blocking "peek" operation on
\ ** stdin.

: _kbhit        \ -- flag
\ *G Return true when a key has been pressed. Equivalent to the
\ ** Forth word *\fo{KEY?}.
  key?
;


\ ======
\ *> ###
\ ======

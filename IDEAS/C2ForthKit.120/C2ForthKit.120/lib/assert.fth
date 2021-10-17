\ assert.fth

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

\ ***************************************
\ *S ASSERT - Runtime Debugging Exception
\ ***************************************

\ *P The *\b{ASSERT()} mechanism provides runtime error checking
\ ** facilities. The parameter to *\b{ASSERT()} is a small piece
\ ** of RT code which when evaluated to 0 at runtime causes the
\ ** program to halt and display the original source file and
\ ** line number.

\ *C void assert( <expression> )
\ *P If <expression> evaluates to 0 (ZERO)at runtime, cause a halt.

: ___assert     \ failedexpr line file --
\ *G Runtime for a failed *\b{assert()}.
  cr ." Assertion " rot
  begin dup c@ while dup c@ emit 1+ repeat drop
  ."  failed: file "
  begin dup c@ while dup c@ emit 1+ repeat drop
  ." , line " . cr
  _abort
;


\ ======
\ *> ###
\ ======

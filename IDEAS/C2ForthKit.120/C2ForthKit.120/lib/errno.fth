\ errno.fth

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

\ *************************************
\ *S Error handling - errno and friends
\ *************************************
\ *P At present *\b{_errno} is a Forth variable. In multitasking
\ ** systems, it may be appropriate to convert this to a *\fo{USER}
\ ** variable providing that appropriate initialisation is provided
\ ** for each task.

variable _errno	\ -- addr
\ *G Just a variable.


\ ======
\ *> ###
\ ======

\ c2f_core.fth - VFX Forth harness for runing C code

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

decimal

\ ==========
\ *! c2forth
\ *T C2Forth - Compiling C for a Forth System
\ ==========
\ *P With the development of MPE's VFX Forth family of compilers
\ ** that produce optimised native code from high level Forth,
\ ** an experiment was performed to use high level Forth as the
\ ** assembly language of a C compiler. The C2Forth system is the
\ ** result.

\ *P The C2Forth system allows you to compile C source to be run
\ ** VFX Forth and XC6/7 cross compilers. It consists of a tool
\ ** chain that produces Forth source from C source, and a build
\ ** harness for the Forth System.


\ ***********
\ *S Overview
\ ***********
\ *P Traditional C compiler chains usually have four stages.
\ *D PreProcess         This step takes a C source file and parses it
\ **                    and any included header files to produce a
\ **                    single reference source. Macros are expanded at
\ **                    this stage and conditional compilation structures
\ **                    are evaluated to remove irrelevant information.
\ *D Compile            This step takes to output from the preprocess
\ **                    stage and produces an assembler listing for the
\ **                    target CPU.
\ *D Assemble           The assembler source from the compile stage is
\ **                    assembled into a binary form along with any
\ **                    relocation information, symbol tables and
\ **                    missing dependancy lists.
\ *D Link               All the binaries for a project as output from
\ **                    the Assemble stage are merged along with any
\ **                    pre-compiled libraries. Dependant symbols from
\ **                    an object are resolved with exported symbols
\ **                    from the surrounding binaries and libraries to
\ **                    form a standalone image.

\ *P MPE has developed a C tool chain which targets a virtual machine
\ ** rather than a specific processor. The compiler is based on the LCC
\ ** system with the preprocess/assembler/linker derived from other
\ ** sources.

\ *P The MPE virtual machine design is a dual stack, no register
\ ** architecture design which is similar to a conventional Forth
\ ** virtual machine. The virtual machine runtime is written in
\ ** Forth.

\ ===============
\ *N C Preprocessor
\ ===============
\ *P The preprocessor used comes as part of the LCC toolchain.
\ ** Only detail changes have been made to this code, mostly to
\ ** aid compilation.

\ ===========
\ *N C Compiler
\ ===========
\ *P The compiler is a heavily modified derivative of LCC. The LCC
\ ** system is designed such that all the processing of C source into
\ ** DAG lists as well as tree reduction and analysis are common. Only
\ ** the part of the code which translates the final DAG trees into
\ ** assembler need retargeting. The "back-end" which performs this job
\ ** is usually built with lBurg.

\ *P lBurg is a code-generator generator system developed by the same
\ ** authors as LCC. Unfortunately the LCC and lBurg combination was
\ ** never designed to cope with the kind of architecture our dual
\ ** stack VM used. For that reason it became necessary to replace the
\ ** "normal" back-end interface in LCC with our own.

\ =======================
\ *N Assembler and Linker
\ =======================
\ *P A VFX Forth Kernel replaces the more traditional Assembler and
\ ** Linker. The output from the compiler for each file in the project
\ ** is passed into the Forth Kernel which has a support harness. The
\ ** binary is placed directly into the Forth dictionary and label names
\ ** are linked either against each other or against the current Forth
\ ** search-order. Therefore libraries and such are not linkable binaries
\ ** but Forth definitions built into the system before the converted
\ ** code.

\ ***************************
\ *S Current Status and Goals
\ ***************************
\ *P This tool chain has reached the stage of proving that a good Forth
\ ** compiler can be used as a back-end for C. As the usage of C2Forth
\ ** increases, the amount of carnal knowledge about the target Forth
\ ** system will decrease. Ultimately the goal is to have output source
\ ** which is 100% ANS Forth compliant. This is theoretically possible to
\ ** achieve - just difficult.

\ *P No attempt has been made to either implement a harness or port the
\ ** existing one onto anything other than an MPE VFX Forth system.

\ *******************************
\ *S Contents of the distribution
\ *******************************
\ *E \BIN            C compiler binaries
\ **     CPP         C Preprocessor
\ **     FCC         C Compiler
\ **     OMAKE       Make utility
\ **     C2FPOST     Parsing utility to take FCC output and pad
\ **                 it into a form which can be safely TFTP'd
\ **                 in 512byte packets.
\ ** \DOC            C2F Distribution documentation.
\ **                 See C2Forth.pdf
\ ** \DOC\LIBC       Documentation on sample C library implementation.
\ ** \HARNESS        C2F Forth Target Harness, reference source.
\ **                 See C2Forth.pdf for details.
\ ** \INCLUDE        C Header files for sample C library implementation.
\ ** \LIB            Forth source for C library functions.
\ ** \SRC            C source code for tools.
\ ** \TESTS          Some simple test programs and a suitable makefile


\ ======
\ *> ###
\ ======


\ ========
\ *! limit
\ *T Limitations
\ ========
\ *P You would have to go a long way to find two langauges so far apart
\ ** as C and Forth so obviously this system has some limitations.

\ *******************
\ *S Short Data Types
\ *******************
\ *P Some C programmers are used to the data type SHORT on a 32bit
\ ** system being 16 bits. The current C compiler tool treats all SHORTs
\ ** as INTs.

\ *****************
\ *S Floating Point
\ *****************
\ *P There is absolutly no support in this system for floating point
\ ** numbers at all.

\ ***********************************
\ *S Namespace Visibility and Linking
\ ***********************************
\ *P At the moment the runtime code on the Forth kernel makes no
\ ** attempt to obey the C EXTERN directive. All public labels are
\ ** built in the global name space, i.e. Forth's currentvocabulary.
\ ** Also since the delivery mechanism for this system is source
\ ** code to an open Forth, there is no binary library format to
\ ** link against.

\ *********************
\ *S Standard C Library
\ *********************
\ *P Due to the lack of a binary library format there is no
\ ** method of compiling C libraries from C source code and
\ ** storing the object code for linking. C2Forth has been
\ ** designed to link C to Forth; since the Forth search-order
\ ** is used to resolve symbols during compilation it is possible
\ ** to write library functions in Forthwith a preceeding
\ ** underscore in the name and call that definition from the C
\ ** code by name. You will need a header file and prototype for
\ ** the C compiler.C2Forth contains a very limited subset of
\ ** the C standard library as Forth source code along with C
\ ** header files.

\ **********************
\ *S Target Forth Kernel
\ **********************
\ *P This system has been designed to exploit the optimising Forth
\ ** kernels built by MPE. As such some tradeoffs have been made
\ ** between portability of output code and speed.
\ *P The VFX kernels from MPE all have the following characteristics:
\ *(
\ *B 32 bit CELL, 8 bit CHAR.
\ *B Native Code Generation.
\ *B An XT or CFA is an executable address not some other id.
\ *B Return Stack access is permitted outside of the current definition.
\ *B Headerless definitions supported.
\ *B MPE standard local variable code present.
\ *)

\ *P There is no technical reason why the required kernel support
\ ** cannot be built on any Forth System. The next section describes
\ ** the output form of the Forth source and the functionality
\ ** required above and beyond ANS Forth. The harness/kernel file
\ ** supplied is for our VFX targets and as such, the nearer a
\ ** Forth Kernel is to our specification, the easier it will be
\ ** to port the existing harness.

\ ======
\ *> ###
\ ======


\ =======
\ *! libs
\ *T Libraries and Calling Forth
\ =======
\ *P Since there is no librarian tool or intermediate binary in the
\ ** C2Forth system it is necessary for some other mechanism for
\ ** declaring C library functions such as *\b{printf()} etc.

\ *P The C2F system allows code output from the C compiler to
\ ** reference symbols in the Forth dictionary. This means that the
\ ** standard C libraries and user functions can be coded in Forth
\ ** and built into the system before the C build.

\ *P Supplied with the kit is a minimal implementation of some of the
\ ** more useful standard C libs.

\ ************************************
\ *S Coding Library Functions in Forth
\ ************************************
\ *P As an example, here is the library implementation of the standard
\ ** C library function *\b{malloc()}.

\ *P First the function prototype for the C compiler is placed in the
\ ** header file *\i{stdlib.h}. It has the form:-
\ *E    extern void *malloc( size_t s );
\ *P In a Forth world this can be seen as:-
\ *E    : malloc        \ size_t -- void*
\ *P Therefore a suitable definition for *\fo{malloc} in Forth
\ ** would be:-
\ *E    : _malloc       \ size_t -- void*
\ **      allocate
\ **      if drop 0 then
\ **    ;
\ *P There are three key things to remember about Forth definitions for
\ ** C library calls.
\ *( 1
\ *B Each function must have a prototype in a C header file.
\ *B Names in Forth must have a preceeding underscore character.
\ *B Input parameters are in reverse order to the C prototype.
\ *)

\ *********************
\ *S Variadic Functions
\ *********************
\ *P Implementing a variadic function in Forth is slightly more
\ ** complex. With a variadic function you have a fixed formal parameter
\ ** list, followed by N other items.

\ *P In Forth you know the fixed parameter list, the variadic members
\ ** should be pulled off the data stack using PICK as required. Note
\ ** that the Forth definition is responsible for keeping the overall
\ ** stack effect of the C prototype for FORMAL PARAMETERS ONLY. The
\ ** Forth definition should not *\fo{DROP} the variadic members.

\ *P Please examine the Forth definition for *\b{_SPRINTF()} in
\ ** the *\i{STDIO.FTH} library file.

\ ======
\ *> ###
\ ======


\ ======
\ *! use
\ *T Usage with VFX Forth
\ ======
\ *P This section explains how to compile the supplied test programs
\ ** and build them on the ProForth VFX system using the reference
\ ** harness.

\ *************************
\ *S Building the Test Apps
\ *************************
\ *P In the distributions \TESTS directory there are three sample
\ ** applications.
\ *D BANNER     Does large screen pretty printing, similar to the Unix
\ **            banner program.
\ *D TESTHEAP   Performs a stress test on the system heap.
\ *D VARTEST    Test program for simply variadic functions.

\ *P By entering MAKE <testname> in the \TESTS directory you can build
\ ** each test program. The translated source for each file will have
\ ** a CXX file extension. This is the Forth style output.

\ *P MAKE itself is a batch file which calls OMAKE in the \BIN folder
\ ** and uses the supplied .MAK file which can be used as a template
\ ** for all builds.

\ ************************
\ *S Running the Test Apps
\ ************************
\ *P In order to compile and run the test programs from the Forth
\ ** sources you need to perform the steps below. For Windows
\ ** systems, there are batch files (scripts) that simplify the
\ ** process. If you are using a Unix system, you can use these
\ ** as the basis of your own scripts.

\ =================
\ *N Windows script
\ =================
\ *P In the root of the C2Forth system, you will find a batch
\ ** file called *\i{InstallWin.bat}. Run this from a console
\ ** prompt at the root of the C2Forth directory.
\ *C C:\Products\C2ForthKit.120>InstallWin
\ *P The script creates apermanent environment variable called
\ ** C2FORTH that specifies the root of the C2Forth directory.
\ ** If you are using Windows XP, you may have to download
\ ** *\i{setx.exe} from the Microsoft web site as it is required
\ ** by *\i{InstallWin.bat}.

\ *P The *\b{tests} directory contains *\i{banner.bld} which
\ ** can be compiled directly by VFX Forth for Windows.

\ ================
\ *N Run VFX Forth
\ ================
\ *P You need any version of VFX Forth.

\ ===============================
\ *N Change to the C2Forth Folder
\ ===============================
\ *P VFX Forth contains a command CD which behaves the same way as the
\ ** Unix/Windows CD shell command. Use it to change to the folder
\ ** into which you installed the C2F system. You can use DIR <cr> to
\ ** verify you are in the correct directory.

\ ================================================
\ *N Compile the C2F Reference Harness and Libraries
\ ================================================
\ *P This distribution contains a sample implementation of the C2F
\ ** harness and some simple C style libraries. Change into the \HARNESS
\ ** folder and include the sources using:
\ *C   include c2f_vfx.bld <CR>

\ =================================
\ *N Change to the \TESTS directory
\ =================================
\ *P On the default installation you can change to the \TESTS folder
\ ** after building the harness by performing:-
\ *C   CD ..\TESTS <cr>

\ ==============================
\ *N Compile your first test app
\ ==============================
\ *P Compilation of a C build is performed in three steps.
\ *P The first is to initialise the C2F harness for a new compile.
\ *C   "C" <cr>                        Initialise C2F Harness
\ *P Second, include the source files which make up your project:
\ *C   #include banner.cxx <cr>        Include banner source
\ *P Third, signal the end of the build and switch back to Forth.
\ *C   "FORTH" <cr>                    Back to Forth Mode
\ *P If all has gone well you should see a report on the compilation.
\ ** If you perform *\fo{WORDS <cr>} on the Forth system you will find that
\ ** all the C procedures are available. Type _MAIN <CR> to run the
\ ** program.

\ *****************************
\ *S Rebuilding the C toolchain
\ *****************************
\ *P If you are going to rebuild the compiler using the same
\ ** tools as MPE, you will need a copy of Visual C++ 6.0. The
\ ** batch file *\i{setpath.bat}, adds the VC++ include directory
\ ** to the Windows search order.

\ *P If you convert the code to use other compilers, please return
\ ** your updates and scripts to MPE for the benefit of others.

\ ======
\ *> ###
\ ======


\ ==========
\ *! coutput
\ *T Forth Style Output from Compiler
\ ==========
\ *P This section describes the format of the compiler output which is
\ ** to be built on a Forth System. In many ways the output is Forth
\ ** but with certain necessary extensions. The local variable format
\ ** may vary between versions of the C compiler and Forth target.

\ *******************
\ *S Simple C program
\ *******************
\ *P
\ *E void main( void )
\ ** {
\ **         int a;
\ **         a = 0;
\ **         while( a < 26 )
\ **         {
\ **                 putchar( a+65 );
\ **                 a++;
\ **         }
\ **         printf("\n");
\ ** }

\ *R @vskip 6.0in
\ **************************************
\ *S Output from the C to Forth Compiler
\ **************************************
\ *E PUBLIC _main
\ ** FLABEL _main
\ ** :NONAME
\ **
\ ** 	MAKELVS [ #0 w, #1 w, ]
\ ** 	#0
\ **
\ ** 	[ #-4 lv, ]
\ ** 	!
\ ** 	CompileBranch @3
\ ** LABEL  @2
\ **
\ ** 	[ #-4 lv, ]
\ ** 	@
\ ** 	#65
\ ** 	+
\ ** 	CompileCall _putchar
\ ** 	drop
\ ** 	#1
\ **
\ ** 	[ #-4 lv, ]
\ ** 	+!
\ ** LABEL  @3
\ **
\ ** 	[ #-4 lv, ]
\ ** 	@
\ ** 	#26
\ ** 	<
\ ** 	CompileCondBranch @2
\ ** 	CompileAddrLit @5 #0
\ ** 	CompileCall _printf
\ ** 	drop
\ ** LABEL  @1
\ **
\ ** 	RELLVS
\ ** ; drop
\ **
\ ** EXTERN _printf
\ ** EXTERN _putchar
\ ** LABEL  @5
\ ** 		$0A c,
\ ** 		$00 c,

\ ********************************
\ *S Binary Generated on VFX Forth
\ ********************************
\ *E Target    Assembler/Binary Data Compiled               Correlation To
\ ** Address                                                Original C Source
\ **
\ **
\ ** 00469ED6  call    MAKELVS                              void main void 
\ ** 00469EDB    Inline data16: 0000                        {
\ ** 00469EDD    Inline data16: 0001                          int a;
\ **
\ ** 00469EDF  mov     dword Ptr [edi+-04], 00000000          a = 0;
\ **
\ ** 00469EE6  call    LIT                                    while  a<26 
\ ** 00469EEB    Inline data32: 00469F14  Label @3 
\ ** 00469EEF  push    ebx
\ ** 00469EF0  mov     ebx, [ebp]
\ ** 00469EF3  lea     ebp, [ebp+04]
\ ** 00469EF6  ret
\ **
\ ** Label @2  mov     edx, [Edi+-04]                         putchar a+65 
\ ** 00469EFA  add     edx, 41
\ ** 00469EFD  lea     ebp, [ebp+-04]
\ ** 00469F00  mov     [ebp], ebx
\ ** 00469F03  mov     ebx, edx
\ ** 00469F05  call    _PUTCHAR
\ ** 00469F0A  add     [edi+-04], 01                          a++;
\ ** 00469F0E  mov     ebx, [ebp]
\ ** 00469F11  lea     ebp, [edp+04]
\ **
\ ** Label @3  cmp     [edi+-04], 1a                          .... Test code for
\ ** 00469F18  jnl/ge  00469F24                               .... WHILE clause
\ ** 00469F1E  push    00469EF7  Label @2 
\ ** 00469F23  ret
\ **
\ ** 00469F24  call    LIT                                    printf"\n";
\ ** 00469F29    Inline data32: 00469F3E  Label @5 
\ ** 00469F2D  call    _PRINTF
\ ** 00469F32  mov     ebx, [ebp]
\ ** 00469F35  lea     ebp, [ebp+04]
\ **
\ ** 00469F38  call    RELLVS                               }
\ ** 00469F3D  ret
\ **
\ ** Label @5    Inline data8: 0                            .... String Literal
\ ** 00469F3F    Inline data8: 0

\ *P The output is largely Forth code with some non-standard
\ ** words being used. These "strange" definitions are Forth compiler
\ ** directives built in a harness file on top of the Forth Kernel by
\ ** exploiting Forth's ease of extensibility.

\ *P The compiler aids are split into 4 groups: Label handling, Control
\ ** flow, data address literals and local frame access. Both the flow
\ ** control directives and the data address literal directives support
\ ** forward referencing by name and offset.

\ *P Most "traditional" C compilers produce code from top to bottom and
\ ** assume a back-end assembler which can do 2 pass compilation. The
\ ** Forth system cannot easily be coerced into a dual pass compiler
\ ** so any attempt to reference an unresolved label adds a record into
\ ** a forward reference chain, and generates a form of binary whereby
\ ** the address can be patched up later. For this reason there are
\ ** "magic" compiler directives for anything which may be formed by
\ ** using a label which could be forward references.

\ *****************************
\ *S Code Generation Extensions
\ *****************************
\ *P The following definitions are used to provide required compilation
\ ** behaviour not standard in Forth. All definitions for data addresses
\ ** and flow control are *\fo{IMMEDIATE}.

\ *P For details of how to implement these directives as well as formal
\ ** stack comments and operation descriptions, please see the section
\ ** describing the current reference harness.

\ =================
\ *N Label Creation
\ =================
\ *P There are four compiler directives which create and modify labels.
\ ** All branch targets and data addresses have a label.
\ *D PUBLIC     Parses a <name> and creates a label entry with no
\ **            specified type or address.
\ *D EXTERN     Currently not used since C2F assumes all labels are
\ **            global and anything not found in the current C source
\ **            will be searched for in the Forth dictionary.
\ *D FLABEL     Used to define an address for a function entry point.
\ **            FLABEL will either patch the address and type of an
\ **            already defined PUBLIC label creating a public function
\ **            label, or will create a new code label for the current
\ **            address. Note that the address stored by FLABEL is not
\ **            the current value of HERE, but the value HERE will be at
\ **            after executing a :NONAME. IE, the label address stored
\ **            will be the XT of the following headerless code.
\ *D LABEL      Behaves as FLABEL for internal branch targets and
\ **            data addresses. The value stored will be the value of
\ **            HERE. Therefore LABEL cannot be used for function entry
\ **            points.

\ =====================
\ *N Local Frame Access
\ =====================
\ *P Local frame access is performed by exploiting the implementation
\ ** of local variables which is common to all MPE targets. For the
\ ** purposes of the C2F compiler we need three definitions:
\ *D MAKELVS    This definition builds a local frame of a specified size
\ **            and moves any parameters from the data stack into the
\ **            local frame. The frame itself is usually created by
\ **            "dropping" the return stack pointer.
\ **            MAKELVS is always followed by a 32 bit number where the
\ **            high 16 bits represent the number of arguments and the
\ **            low 16 bits represent the size in bytes of the local
\ **            data space.
\ *D RELLVS     This definition will release the last allocated locals
\ **            frame and restore the return stack pointer.
\ *D LV,        An internal definition which when executed will take
\ **            a literal frame offset value and compile the code
\ **            necessary to put the address of the local frame + offset
\ **            onto the data stack at runtime.

\ *P The local variable format used was designed during the SENDIT
\ ** and PRACTICAL projects. The frame is built on the return stack.
\ *E argn
\ ** ...        paramteters
\ ** arg1
\ ** ----
\ ** previous return stack pointer (RSP)
\ ** previous locals pointer (LP)
\ ** ---- new LP points to old LP
\ ** uninitialised locals
\ ** ---- new RSP points here

\ *P In an environment with interrupts, the code laid or performed
\ ** by *\fo{RELLVS} must restore LP before RSP.


\ ========================
\ *N Data Address Literals
\ ========================
\ *P There are two definitions which are used whenever a data address
\ ** literal reference needs to be compiled.
\ *D CompileAddrLit     Compiles code which will place the address of
\ **                    the label specified on the top of the data stack
\ **                    at runtime.
\ *D CommaAddrLit       Places the address of the specified label into
\ **                    the next cell in the dictionary.

\ *P Both these directives have the same argument syntax. The first
\ ** token is the label name, and the second token is a signed 32bit
\ ** offset literal. Forward referencing is built into these two
\ ** compilers such that, if the label has allready been resolved the
\ ** address is used directly either as a literal or via *\fo{,}
\ ** (comma). If the label has not yet been defined or resolved
\ ** then code generation is completed assuming a value of 0 and
\ ** a forward reference entry is generated for later resolution.
\ ** Any generated code which requires a forward reference should
\ ** be built in such a way that it can have its value changed
\ ** later. This is implementation specific.

\ ===============
\ *N Control Flow
\ ===============
\ *P There are three definitions which are used to perform branches.
\ *D CompileCall        Lay code to CALL the address represented by
\ **                    the given label. If the address is allready
\ **                    known, this is a COMPILE, otherwise some code is
\ **                    compiled whereby the XT is built into the
\ **                    dictionary as a CELL which can be updated when
\ **                    the address for the label has been resolved.
\ *D CompileBranch      Similar to CompileCall except it behaves as an
\ **                    assembler JUMP instruction. There is no direct
\ **                    Forth equivilant to this operation, on a number
\ **                    of systems it can be acheived by performing
\ **                    calling a definition which performs >R. This is
\ **                    very implementation specific but common.
\ *D CompileCondBranch  Compiles code to perform a branch if
\ **                    top-of-stack is non-zero. Some systems may have
\ **                    the word ?BRAN for this operation, other more
\ **                    ANS compliant targets can define this as using
\ **                    POSTPONE IF POSTPONE COMPILEBRANCH POSTPONE THEN

\ ======
\ *> ###
\ ======


\ ==========
\ *! harness
\ *T VFX Forth Runtime Harness
\ ==========
\ *P *\i{C2F_CORE.FTH} provides a reference source for the Forth compiler
\ ** support harness required to use C2F on the MPE VFX Forth Kernels.

\ *P This harness provides all the directives which occur in the
\ ** compiler output source to control forward referencing etc.

\ *P Documentation here is in source-code order and should be used as
\ ** a roadmap when reading the reference code.

\ **********************
\ *S Misc Configurations
\ **********************

variable <periodic-resolve>	\ -- addr
\ *G This variable is used to force the system to attempt to resolve
\ ** pending forward references each time the PUBLIC directive is
\ ** encountered. Performing this extra pass on the resolve rather than
\ ** the default setting of only resolving at the end of a source will
\ ** reduce the amount of heap memory used at compile time, but will
\ ** increase compilation time.
  <periodic-resolve> off

: periodic-resolve?	\ -- flag
\ *G Returns TRUE if periodic address resolution is required.
  <periodic-resolve> @
;

\ *********************
\ *S CPU Specific Tools
\ *********************
\ *P These words and utilities are used to generate target code. They
\ ** are isolated here since the required settings and actions may
\ ** vary from host to host.

\ *P These primitives assume an MPE VFX Forth target.

5 constant size-of-machine-call
\ *G The size in address-units of a target call instruction. Primarily
\ ** used by 'literal'

: get-parent-cfa	\ xt -- addr:32
\ *G When passed the xt of a definition which is a child of a defining
\ ** word, this returns the xt of the runtime action'sparent. Used
\ ** in the CONSTANT-XT? definition.
  dup 5 + swap
  1+ @ +
;

: NonameGap	\ loc -- xt
\ *G This primitive will return the XT that would be generated if
\ ** :NONAME was invoked whilst HERE was at loc. It is used by the
\ ** system to record function entry points.
  2 cells+              \ VFX has 2 cells dummy header in :NONAME
;

code lp@	\ -- *lp
\ *G This definition returns the local frame pointer. The format of the
\ ** local frame is defined in the MPE Locals Section of this text.
        sub     ebp, 4
        mov     0 [ebp], ebx
        mov     ebx, edi
        next,
end-code

: flush-opt	\ --
\ *G This directive forces the MPE code optimiser to flush any pending
\ ** code trees.
  postpone [o/f]
;

: [literal]     \ n -- ;
\ *G This directive lays down the target code necessary to generate the
\ ** literal value N at runtime.
  ['] lit compile, ,
;

: 'literal'     \ dp n --
\ *G This directive can change the literal value compiled by [literal]
\ ** when HERE was at DP. It is used to resolve forward referenced
\ ** data address literals.
  swap SIZE-OF-MACHINE-CALL + !
;

: CONSTANT-XT?          \ xt -- flag
\ *G Return TRUE if XT is a child of CONSTANT. Used when CONSTANTS are
\ ** defined for addresses.
  get-parent-cfa
  ['] true get-parent-cfa =
;


\ *************************
\ *S Multitasking and PAUSE
\ *************************
\ *P The code in this section can be used with Forth systems that
\ ** have a cooperative multitasker called by the word *\fo{PAUSE}.
\ ** When the C2F compiler lays a call to a known XT via
\ ** *\fo{COMPILECALL} this code is used. If the current value of
\ ** *\fo{HERE} is between the variables *\fo{COMP-PAUSE-START}
\ ** and *\fo{COMP-PAUSE-END}, a call to the *\fo{PAUSE} is
\ ** compiled before the normal call.

\ *P This arrangement allows you to specifiy a range of the
\ ** dictionary for which target calls will cause a schedule
\ ** operation. By default the range is 0 - 0 which turns *\fo{PAUSE}
\ ** generation off. The best settings are usually between the end
\ ** of the normal Forth kernel and the start of the C compiled
\ ** source. This will make calls to the larger library definitions
\ ** have a *\fo{PAUSE} but calls to the kernel primitives will not.

variable comp-pause-start	\ -- addr
  comp-pause-start off
variable comp-pause-end		\ -- addr
  comp-pause-end off

: Set-Comp-Pause-Range  \ start end --
\ *G This definition sets the range of addresses in the dictionary
\ ** for which a compiled word will be preceeded by *\fo{PAUSE}.
  comp-pause-end !  comp-pause-start !
;

: ?compile-pause        \ where --
\ *G Compiles a *\fo{PAUSE} if the specified address is within the
\ ** range set by *\fo{SET-COMP-PAUSE-RANGE}. Note that if there
\ ** is no multitasker present, nothing is compiled by this definition.
  comp-pause-start @
  comp-pause-end @
  within? if
    [defined] pause [if] ['] pause compile, [then]
  then
;

\ ========
\ *S Tools
\ ========

[undefined] cksum [if]
: cksum         \ addr len -- cksum
\ *G The INET Check sum algorithm. Used to provide a checksum of
\ ** generated code to ensure delivery.
  0 -rot
  swap 2- swap                          \ start address 2- so we can inc it more efficiently
  begin
    dup 1 >                             \ check if more than 1 byte left
  while
    2- >r                               \ dec & shift the length out of the way
    2+ tuck w@                          \ get 16 bits of data
    +                                   \ and add it into cksum
    dup $80000000 and                   \ check top bit
    if
      dup $0FFFF and                    \ get low 16 bits
      swap $10000 / +                   \ and add in the high 16 bits !!!
    endif
    swap                                \ re-order values
    r>                                  \ retrieve length
  repeat
  if                                    \ odd byte left
    2+ c@ $0100 * +
    dup $80000000 and                   \ check top bit
    if
      dup $0FFFF and                    \ get low 16 bits
      swap $10000 / +                   \ and add in the high 16 bits !!!
    endif
  else                                  \ all done
    drop
  endif
  begin
    dup $10000 /
  while
    dup $0FFFF and                      \ get low 16 bits
    swap $10000 / +                     \ and add in the high 16 bits !!!
  repeat
  $FFFF xor
;
[then]

[undefined] icompare [if]
: icompare      \ c-addr1 u1 c-addr2 u2 -- flag
\ *G Case insensitive version of the ANS word *\fo{COMPARE}.
  rot swap                      \ c-addr1 c-addr2 u1 u2
  2dup - >r min                 \ c-addr1 c-addr2 minlen -- R: lendiff? --

  begin
    dup
  while
    -rot over c@ upc over c@ upc -      \ length c-addr1 c-addr2 (char1-char2)

    ?dup if                     \ If chars are different
        r> drop >r              \  replace lendiff result with error code
        drop 0                  \  and put 0 on TOS (make len==0 at BEGIN)
    else                        \ otherwise
        1+ swap 1+ swap rot 1-  \ increment addresses and decrement length
    then

  repeat

  drop 2drop                    \ remove addresses and null count from stack
                                \ -- ; R: result --
  r> dup if 0< 1 or then        \ make nice flag, 0 becomes 0, -ve becomes -1
                                \            and  +ve becomes 1
;
[then]

[undefined] upc [if]
: upc           \ v -- 'v
\ *G Perform where possible an upper case character conversion.
  dup [char] a [char] z within? if bl - then
;
[then]

[undefined] zcount [if]
: zstrlen       \ addr -- len
\ *G Given a pointer to a zero-terminated string this will return the
\ ** character length excluding the terminator.
  0 >r
  begin
    dup c@ 0<> if
      r> 1+ >r 1+ 0
    else
      drop -1
    then
  until
  r>
;

: zcount        \ zaddr -- zaddr len
\ *G A zero terminated string version of COUNT.
  dup zstrlen
;
[then]

[undefined] >pos [if]
: >pos          \ n --
\ *G Used in diagnostic display. Move the cursor X position to column N.
  out @ - 1 max spaces
;
[then]

[undefined] .dword [if]
: .dword        \ n --
\ *G Used in diagnostic display. Show the value N as an unsigned
\ ** 32 bit hexadecimal.
  base @ >r hex s>d <# # # # # # # # # #> type r> base !
;
[THEN]

[undefined] c@s [if]
: c@s           \ addr -- cell
\ *G Fetch character from ADDR and sign extend to a CELL.
  c@ dup 255 > if $FFFFFF00 or then
;
[THEN]

[undefined] allot&erase [if]
: allot&erase   \ n --
\ *G Allot N bytes from the dictionary and pre-erase it.
  here swap dup allot erase
;
[THEN]

: char>cell             \ signed-byte -- signed-int
\ *G Sign extend the supplied character to a CELL.
  dup $80000000 and if $FFFFFF00 or then
;

\ ***********************
\ *S Code Stream Handlers
\ ***********************
\ *P The *\b{codestream} is an area into which strings are built to
\ ** *\fo{EVALUATE} in order to perform compilation.

256 buffer: CodeStream
\ *G The temporary buffer into which a string is built.

: ResetStream           \ --
\ *G Re-initialises the *\fo{CodeStream} buffer to zero length.
  0 CodeStream c!
;

: EvalStream            \ --
\ *G Perform an *\fo{EVALUATE} on the code stream.
  CodeStream count evaluate
;

: $>stream              \ c-addr u --
\ *G Append a string to the code stream buffer.
  CodeStream count + >r
  dup CodeStream c+!
  r> swap move
;

: h>stream              \ n --
\ *G Add a string to the end of the code stream buffer which represents
\ ** the hexadecimal number N. The number text is preceeded by a $
\ ** character as per MPE practice.
  S" $" $>stream
  base @ >r hex s>d <# #s #> $>stream r> base !
;

\ ***********************
\ *S LABEL Chain Handlers
\ ***********************
\ *P During compilation of a converted C source file, all labels defined
\ ** are kept in a linked list. Each list entry holds the name of the
\ ** label, the address of the labels target if known and a set of flags
\ ** which describe the label useage. All data pointers and branch
\ ** targets have a corresponding label.

\ *P Label Struct Format - all entries are 1 cell and in order 
\ *D LBL.link    link, pointer to next label record in list or NULL
\ *D LBL.*name   Pointer to label name which is a counted string
\ *D LBL.flags   Flags, describe the label type, see Flags
\ *D LBL.address Address, the target address the label equates to

struct  LBL
        cell    field   LBL.link
        cell    field   LBL.*name
        cell    field   LBL.flags
        cell    field   LBL.address
end-struct

\ *P Label Flags consists of one or more of:
\ *D LF_PUBLIC          Label scope is global.
\ *D LF_ADDRESSVALID    The Address field of the label structure is valid.
\ *D LF_DATALABEL       The label represents an internal address. This
\ **                    is either a data pointer, or a function local label.
\ *D LF_CODELABEL       The label represents a function entry point.
\ *D LF_DELETE          Used internally. The label is marked for deletion

$00000001 constant LF_PUBLIC
$00000002 constant LF_ADDRESSVALID
$00000004 constant LF_DATALABEL
$00000008 constant LF_CODELABEL
$00000010 constant LF_DELETE

0 Value LabelChain
\ *G Either NULL or a pointer to the first label structure.

: .label_flags          \ n --
  dup LF_PUBLIC         and if [char] * else [char] _ then emit
  dup LF_ADDRESSVALID   and if [char] * else [char] _ then emit
  dup LF_DATALABEL      and if [char] * else [char] _ then emit
  dup LF_CODELABEL      and if [char] * else [char] _ then emit
  dup LF_DELETE         and if [char] * else [char] _ then emit
  drop
;

: .label                \ *LABEL --
\ *G Given a pointer to a label structure this definition will output
\ ** a human readable dump of the label information.
  cr
  dup LBL.*name @ $. 40 >pos
  dup LBL.address @ .dword
  space
  LBL.flags @ .label_flags
;

: .l                    \ --
\ *G Lists all currently defined labels and their attributes. The
\ ** output for each label will be the name, address and flags status as
\ ** according to the header displayed on screen.
  cr ." Label List"
  cr ."   Name                                 | Address |PADCK|"
  LabelChain
  begin
    ?dup
  while
    dup .label
    LBL.link @
  repeat
  cr
;

: DestroyLabelChain     \ --
\ *G Destroy the entire current label chain.
  LabelChain
  begin
    ?dup
  while
    dup LBL.*name @ ?dup if free drop then
    dup LBL.link @
    swap free drop
  repeat
  NULL to LabelChain
;

: AddLabel              \ c-addr u flags address --
\ *G Add a new label entry using the name flags and address supplied.
\ cr ." AddLabel " 2over type
  LBL allocate abort" Failed to allocate label storage" >r
  LabelChain r@ LBL.link !
  r@ LBL.address !
  r@ LBL.flags !
  dup 1 chars + allocate abort" Failed to allocate label sub storage"
  dup r@ LBL.*name !
  2dup c!
  1 chars + swap move
  r> to LabelChain
;

: FindLabel	\ c-addr u -- *LABEL | NULL
\ *G Look for a label given a name. Returns either a label structure
\ ** pointer or NULL if the label was not found. Please note that under
\ ** VFX Forth label names are not case sensitive.
  2>r
  LabelChain
  begin
    ?dup
  while
    dup LBL.*name @ count 2r@ icompare 0= if
        2r> 2drop exit
    then
    LBL.link @
  repeat
  2r> 2drop
  0
;

: FindResolvedLabel     \ c-addr u -- c-addr u 0 | address true
\ *G Similar to FindLabel except only a label which has a valid address
\ ** is accepted. On success the label address and TRUE is returned, if
\ ** the label does not exist or has not yet been resolved the original
\ ** name and namelen parameters are returned with a FALSE flag.
  2dup FindLabel
  ?dup if
          dup LBL.flags @ LF_ADDRESSVALID and if
                nip nip
                LBL.address @ true exit
          else
                drop 0 exit
          then
       then

  \ c-addr u --

  2dup upper
  2dup forth-wordlist search-wordlist
  if
    nip nip
    dup CONSTANT-XT? if execute then
    true
  else
    0
  then
;

: GarbageCollectLBL     \ --
\ *G Walks the label list removing and deallocating any structures
\ ** marked for delete.
  { | new -- }
  0 -> new
  LabelChain
  begin
    ?dup
  while
    dup LBL.link @ >r

    dup LBL.flags @ LF_DELETE and if    \ trash?
        dup LBL.*name @
        free drop
        free drop
    else
        new over LBL.link !
        -> new
    then

    r>
  repeat
  new to LabelChain
;

: ExportLBL             \ *lbl --
\ *G Exports a label from a label chain structure supplied into the
\ ** current Forth definitions wordlist. Code labels are built by
\ ** generating a : definition of the same name which will pass the
\ ** compiled codes address to *\fo{EXECUTE}. Non-Code labels are
\ ** built as *\fo{CONSTANT}s.
  dup LBL.address @ swap        \ address *lbl --
  dup LBL.*name @ count rot     \ address c-addr u *lbl --
  LBL.flags @ LF_CODELABEL and  \ address c-addr u code? --

  ResetStream
  if
        S" : " $>stream
        $>stream
        S"  " $>stream
        h>stream
        S"  execute ;" $>stream
  else
        rot h>stream
        S"  constant " $>stream
        $>stream
  then
  EvalStream
;

: PatchLabel            \ address iflag *LABEL --
\ *G Modify the supplied label structure to use the supplied address
\ ** and combine the supplied flags with the existing ones. This is
\ ** used to resolve a label which had no valid address when defined.
\ ** A fatal error has occured if any attempt is made to patch a label
\ ** which already has a valid target address.
  >r
  r@ LBL.flags @
  dup LF_ADDRESSVALID and if
        cr ." PatchLabel allready has a valid address"
        cr r@ LBL.*name @ $. cr cr
        abort
  then
  or LF_ADDRESSVALID or r@ LBL.flags !
  r> LBL.address !
;

: NewLabel              \ address iflag c-addr u --
\ *G This definition is similar to *\fo{AddLabel} except the *\fo{LF_ADDRESSVALID}
\ ** flag is automatically added. Used as a shortcut for those times
\ ** when a known address label is to be added.
\ cr ." NewLabel " 2dup type
  2swap LF_ADDRESSVALID or swap AddLabel
;

: (label)               \ address iflag "name" --
\ *G The internal factor used to create most labels. A label name is
\ ** parsed from the input buffer and if it exists the address and *\i{iflag}
\ ** are passed to *\fo{PatchLabel}. If the label does not
\ ** exist it is created by *\fo{NewLabel}.
\ cr ." (Label)"
  bl word count         \ -- address iflag c-addr u
  2dup FindLabel        \ -- address iflag c-addr u *LABEL|NULL
  ?dup if
\    >r  cr ." PatchLabel " type  r> PatchLabel
    nip nip  PatchLabel
  else  NewLabel  then
;

: RemoveLocalLabels     \ --
\ *G Destroys the local label list by marking each entry for deletion
\ ** and then calling calling *\fo{GarbageCollectLBL}.
  LabelChain
  begin
    ?dup
  while
     dup LBL.flags @ LF_PUBLIC and 0= if
        dup LBL.flags dup @ LF_DELETE or swap !
     then
     LBL.link @
  repeat
  GarbageCollectLBL
;

: ExportPublics         \ --
\ *G Exports all public labels to the Forth namespace. Works by calling
\ ** *\fo{EXPORTLBL} for each local label entry with the public attribute and
\ ** then marking it for delete.
  LabelChain
  begin
    ?dup
  while
    dup LBL.flags @ LF_PUBLIC and if
        dup ExportLBL
        dup LBL.flags dup @ LF_DELETE or swap !
    then
    LBL.link @
  repeat
  GarbageCollectLBL
;


\ ***********************************
\ *S Forward Reference Chain Handlers
\ ***********************************
\ *P Address literals and branch targets are referenced by symbol name
\ ** during compilation. Since C generated code may forward reference
\ ** such symbols a chain of unresolved targets is kept during the "C"
\ ** build. Each entry in the chain holds the symbol name, a numeric
\ ** offset to apply to the symbol, the dictionary pointer for the
\ ** target code to patch and the type of patch to apply.

$00000001 constant FF_CELL	\ -- x
\ *G This flag when set in the FW.flags field indicates the target code
\ ** to be patched is a CELL, otherwise the code to be patched is the
\ ** literal code as generated by [literal].

\ *P The FWForward reference struct has the following fields:
\ *D FW.link     link, pointer to next record in list or NULL
\ *D FW.*name    Pointer to label name which is a counted string. A zero
\ **             in this field indicates invalid FW and the records is
\ **             removed on the next garbage collect.
\ *D FW.here     Target dictionary location to perform patch operation.
\ *D FW.offset   Offset to apply to address of symbol in *name before
\ **             patching dictionary.
\ *D FW.flags    Flags, describe the patch type. Either 0 or FF_CELL.

struct FW	\ -- len
        cell    field   FW.link
        cell    field   FW.*name                \ when 0 means delete me!
        cell    field   FW.here
        cell    field   FW.offset
        cell    field   FW.flags
end-struct

0 Value FWChain	\ -- addr|0
\ *G Either NULL or pointer to the first forward reference record.

: .fw                   \ *FW --
\ *G Given a pointer to a FW structure display it in human readable
\ ** form.
  cr
  dup FW.*name @ ?dup if $. else ." null record (delete)" then 40 >pos
  dup FW.offset @ .dword
  space
  dup FW.here @ .dword
  space
  FW.flags @ FF_CELL and if ." Only a CELL" else ." default: Literal RT" then
;

: .f                    \ --
\ *G Display list of all pending forward references, their target
\ ** location and type of patch to apply.
  cr ." Outstanding Forward Reference Literals"
  cr ."   Name                                 | Offset  | CodeAddress"
  FWChain
  begin
    ?dup
  while
    dup .fw
    FW.link @
  repeat
  cr
;

: DestroyFWChain        \ --
\ *G Destroy the entire forward reference chain.
  FWChain
  begin
    ?dup
  while
    dup FW.*name @ ?dup if free drop then
    dup FW.link @
    swap free drop
  repeat
;

: $AddLitFW             \ c-addr u -- *FW
\ *G Add a new forward reference record for symbol whose name is
\ ** passed as *\i{C-ADDR U}. Returns a pointer to the record to
\ ** allow the addresses and flags to be set by the caller.
  dup 1 chars + allocate abort" Failed namespace allocate for FW"
  2dup c! dup >r 1 chars + swap move
  FW allocate abort" Failed allot for FW chain"
  r> over FW.*name !
  0 over FW.here !
  0 over FW.offset !
  0 over FW.flags !
  FWChain over FW.link !
  dup to FWChain
;

: Resolve               \ *FW -- res?
\ *G If possible resolve the forward reference whose structure is at
\ ** *\i{*FW}. Returns TRUE if the reference was found or false if the
\ ** name does not exist or the address has not been resolved yet.
  dup FW.*name @ count
  FindResolvedLabel
  if
        \ *FW label-address --

        over FW.offset @ +      \ add any offset to resolved label address
        over FW.here @ swap rot \ dp n fw --
        FW.flags @ FF_CELL and if
                swap !          \ resolve CELL
        else
                'literal'       \ do the resolve for literal
        then
        true                    \ flag, DONE IT!
  else
        \ *FW c-addr u -- ; No resolved label, cannot resolve fw
        2drop
        drop
        false
  then

;

: GarbageCollectFW      \ --
\ *G Destroy any forward reference records with the FW.*name field
\ ** at zero.
  { | new -- }
  0 -> new
  FWChain
  begin
    ?dup
  while
    dup FW.link @ >r

    dup FW.*name @ if
      new over FW.link !                \ attach to new chain (still active)
      -> new
    else
      free drop                         \ remove
    then

    r>
  repeat
  new to FWChain
;

: ResolveFW             \ --
\ *G Attempt to resolve all forward references and delete any which
\ ** have succesfully been resolved.
  FWChain
  begin
    ?dup
  while
    dup Resolve if
        dup FW.*name dup @ free drop off        \ free name memory and mark
                                                \ for delete
    then
    FW.link @
  repeat
  GarbageCollectFW
;


\ ************
\ *S Compilers
\ ************
\ *P Provides the harness definitions for the compilation of address
\ ** literals and branches. Each compilation directive will attempt
\ ** to resolve the required address and generate optimial code, for
\ ** an unresolved address and forward reference is generated and some
\ ** less optimal but patchable code is generated.

#256 buffer: name-store	\ -- addr
\ *G A buffer to store the first token after a directive, i.e. the target
\ ** label name. Performed since VFX parses text at *\fo{HERE} which will
\ ** be corrupted during code generation.

: >name-store           \ c-addr u -- 'c-addr u
\ *G Copy the string *\i{C-ADDR U} to the name-store buffer for use later.
  dup name-store c!
  name-store 1 chars + swap move
  name-store count
;

: ParseNumericOffset    \ "offset" -- val
\ *G Parse the next token from the input stream and attempt to convert
\ ** to a signed numeric offset. *\fo{ABORT}s if the next token is not
\ ** numeric. This is used to parse and set the address offset as
\ ** specified by directives such as *\fo{COMMAADDRLIT}.
  bl word number? 1 <> abort" non-numeric offset used"
;

: CommaAddr             \ "symbol" "offset" --
\ *G Generate code to place the address of "symbol" with "offset" into
\ ** the dictionary as a CELL via comma. If the address is already
\ ** known it is simply passed to comma, otherwise a 0 value is compiled
\ ** and a FF_CELL forward reference added to the FW chain.
  bl word count >name-store
  FindResolvedLabel
  if
        ParseNumericOffset +
        ,
        exit
  then

  flush-opt

  $AddLitFW >r            \ *FW --
  here r@ FW.here !
  ParseNumericOffset
  r@ FW.offset !
  FF_CELL r> FW.flags !

  0 ,

; immediate

: CompileAddrLit        \ "symbol" "offset" --
\ *G Similar to *\fo{CommaAddr} except rather than laying the data as a CELL
\ ** in the dictionary the runtime code for a literal is compiled.
\ ** As with *\fo{CommaAddr} if the label is resolved the literal is used
\ ** directly as though it was present in the source otherwise a
\ ** patchable literal is compiled via *\fo{[LITERAL]} and a forward reference
\ ** is added.
  bl word count
  >name-store

  FindResolvedLabel
  if                    \ Found Symbol: address--
        ParseNumericOffset +
        postpone literal
        exit
  then                  \ No Symbol:    c-addr u --

  flush-opt

  $AddLitFW >r            \ *FW --
  here r@ FW.here !
  ParseNumericOffset
  r> FW.offset !

  0 [literal]
; immediate

: CompileCall           \ "symbol" --
\ *G Compile a call to the address named "symbol". If the address is
\ ** known it is passed to *\fo{COMPILE,} otherwise  "symbol" is treated as
\ ** with *\fo{COMPILEADDRLIT} and a call to the Forth *\fo{EXECUTE} is compiled
\ ** afterwards. Also note that when compiling a resolved symbol the
\ ** target address is passed to *\fo{?COMPILE-PAUSE} as documented above in
\ ** the section on multitasking.
  bl word count
  >name-store

  FindResolvedLabel
  if
        dup ?compile-pause
        compile,
        exit
  then

  flush-opt

  $AddLitFW             \ *FW --
  here swap FW.here !
  0 [literal]

  ['] execute compile,
; immediate

\ ----

: CompileJump           \ --
\ *G Compile code into target to perform a JUMP to the address in TOS.
  postpone >r  doexit,
; immediate

\ : :noname                             \ note to self: Hack for StrongArm
\   :noname
\   $00 c, $40 c, $2D c, $E9 c,
\ ;

\ : CompileJump
\   $0A c, $00 c, $A0 c, $E1 c,   \       mov r0, r10
\   $00 c, $04 c, $BC c, $E8 c,   \       ldmia r12 ! { r10 }
\   $00 c, $F0 c, $A0 c, $E1 c,   \       mov pc, r0
\ ; immediate

\ ----

: CompileBranch         \ "symbol" --
\ *G Compile a jump the address reference by "symbol". This is acheived
\ ** by compiling a literal as with CompileAddrLit and then calling
\ ** *\fo{COMPILEJUMP} to lay the branch code.
  bl word count >name-store
  FindResolvedLabel
  if
        postpone literal
  else
        flush-opt
        $AddLitFW
        here swap FW.here !
        0 [literal]
  then

  postpone CompileJump
; immediate

: CompileCondBranch     \ "symbol" --
\ *G Lays code for a conditional variant of *\fo{COMPILEBRANCH}. The normal
\ ** method of achieving this is to postpone IF COMPILEBRANCH THEN.
  postpone if
  postpone CompileBranch
  postpone then

; immediate


\ ********************
\ *S Label Definitions
\ ********************
\ *P These definitions form part of the language extensions as used by
\ ** the output from the c2forth translator. They each record a specific
\ ** kind of label.

: FLabel                \ "name" --
\ *G Adds a new code-entry point label. The actual address represented
\ ** is the target XT address which will be returned if *\fo{:NONAME} is
\ ** invoked at the current value of *\fo{HERE}. If the label already exists
\ ** it has the *\fo{LF_CODELABEL} flag added to its current incarnation.
  flush-opt
  align here NoNameGap			\ SFPxx
  LF_CODELABEL
  (label)
; immediate

: Label                 \ "name" --
\ *G Adds a new non-entry point label. These labels are either reference
\ ** points within a definition, e.g. branch targets, or are pointers to
\ ** data items. As with *\fo{FLabel}, an existing label is patched. This time
\ ** with the *\fo{LF_DATALABEL} flag.
  flush-opt
  here
  LF_DATALABEL
  (Label)
; immediate

: Public                \ "name" --
\ *G Add a new label of type *\fo{LF_PUBLIC}. This operation allways adds a
\ ** new label, and does not specify a type. It will usually be immediately
\ ** followed by a *\fo{FLABEL} or *\fo{LABEL} directive to specify type.
  periodic-resolve? if ResolveFW then
  bl word count LF_PUBLIC -1 AddLabel
; immediate

: Extern                \ "name" --
\ *G *\fo{EXTERN <label>} will eventually be used to mark external labels.
\ ** Currently C2F ignores these directives and everything is treated as
\ ** global.
  bl word drop
;


\ ****************************
\ *S Variadic Function Support
\ ****************************
\ *P The calling method for variadic functions involves placing the
\ ** known stack depth into the first local variable, building a frame
\ ** with the specified parameters and using an equivalent to Forth's
\ ** *\fo{PICK} instruction to grab the variadic parameters. These three
\ ** definitions are used at runtime to support variadics.

: _vm_va_depth          \ -- i
\ *G Return the contents of the first local variable.
  lp@ cell- @
;

: _VM_depth             \ -- n
\ *G Return data stack depth. A sanity check, how far down the data
\ ** stack can a variadic function safely perform *\fo{PICK}.
  depth
;

: _VM_pick              \ n -- c
\ *G An alias for *\fo{PICK} to complete the isolation layer.
  pick
;


\ ****************
\ *S Outer Harness
\ ****************
\ *P The definitions used to control the compilation of C files within
\ ** a Forth interpreter.

variable        c-build-start-dp
\ *G A variable which records the value of HERE when C compile mode
\ ** is enabled. Simply used to report the size of generated target code
\ ** on completion.

: [EOF]                 \ --
\ *G This definition is invoked at the end of each individual source
\ ** include during a C build. It resolves forward references where
\ ** possible, deletes the source-file local labels and exports public
\ ** symbols to the Forth namespace.
  ResolveFW
  RemoveLocalLabels
  ExportPublics
;

: "C"                   \ --
\ *G Begin "C" source code build. Records start HERE position and ensures
\ ** the local label and forward reference chain are clear.
  here c-build-start-dp !
  DestroyLabelChain
  DestroyFWChain
;

: "FORTH"               \ --
\ *G End a "C" source code build. Reports unresolved forward references
\ ** and size/checksum of generated code.
  FWChain if
        cr cr ." Build Failed: Unresolved Forward References:" cr
        .f
        DestroyFWChain
        abort
  then

  cr cr ." Compilation Complete. " here c-build-start-dp @ - . ." bytes"
  ."  target code generated."
  c-build-start-dp @ here over - cksum ." Checksum = $" hex u. decimal cr cr
;

: #included             \ c-addr u --
\ *G A version of the ANS word *\fo{INCLUDED} which automatically
\ ** calls *\fo{[EOF]} on completion. Used to include each
\ ** individual C file between the *\fo{"C"} and *\fo{"FORTH"}
\ ** directives.
  included [eof]
;

: #include              \ "name" --
\ *G A version of the ANS INCLUDE word. Performs as #INCLUDED.
  bl word count #included
;

\ ======
\ *> ###
\ ======


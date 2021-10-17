@echo off
rem *** Builds C2Forth manual

set VFXDIR=C:\Products\VfxForth.dev\Sources\Images

rem *** build TeX files
del *.html
del *.tex
del C2Forth.pdf
start /w %VFXDIR%\VfxForth.exe  include ManFiles\MakeDocFiles.dgs

rem *** make PDF and clean up
copy *.tex texfiles
texify -p manual.tex
texify -p manual.tex
ren manual.pdf c2forth.pdf
ren manual.tex c2forth.tex
ren manual.log c2forth.log
ren manual.fn  c2forth.fn
copy manual.off+manual.fns c2forth.fns
del manual.*
ren c2forth.pdf manual.pdf
ren c2forth.tex manual.tex
ren c2forth.log manual.log
ren c2forth.fn  manual.fn
ren c2forth.fns manual.fns

rem *** save last copy
move /Y manual.pdf C2Forth.pdf
move /Y manual.fns C2Forth.vix

rem *** delete trivia and TeX files
del *.html
del *.tex
del manual.fn

rem *** all done
echo Read and then delete MANUAL.LOG.
pause

@echo off
rem - set environment variables for C2FORTH
rem - must be run from the directory containing InstallWin.bat

echo *
echo * The program setx.exe is part of Win7 or can be downloaded as
echo * part of the XP Service Pack 2 Support Tools.
echo *

rem - permanent but not yet
setx C2FORTH %CD%
rem - temporary but now
set C2FORTH=%CD%


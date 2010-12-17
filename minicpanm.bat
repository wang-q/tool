@rem = '--*-Perl-*--
@echo off
if "%OS%" == "Windows_NT" goto WinNT
cpanm --mirror file:///e:/minicpan --mirror-only %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofperl
:WinNT
cpanm --mirror file:///e:/minicpan --mirror-only %*
if NOT "%COMSPEC%" == "%SystemRoot%\system32\cmd.exe" goto endofperl
if %errorlevel% == 9009 echo You do not have Perl in your PATH.
if errorlevel 1 goto script_failed_so_exit_with_non_zero_val 2>nul
goto endofperl

:endofperl

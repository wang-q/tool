@rem
@echo off
if "%OS%" == "Windows_NT" goto WinNT
cpan-outdated --mirror file:///d:/minicpan %1 %2 %3 %4 %5 %6 %7 %8 %9
goto end
:WinNT
cpan-outdated --mirror file:///d:/minicpan %*

:end

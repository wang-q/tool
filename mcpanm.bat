@rem
@echo off
if "%OS%" == "Windows_NT" goto WinNT
cpanm --mirror file:///e:/minicpan --mirror-only %1 %2 %3 %4 %5 %6 %7 %8 %9
goto end
:WinNT
cpanm --mirror file:///e:/minicpan --mirror-only %*

:end

@echo off

echo I'm going to update folders to server.

setlocal

set exe="c:\Program Files (x86)\Beyond Compare 3\BCompare.exe"
set script="d:\wq\Scripts\tool\bcompare\update_folders.txt"

set name=data
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% \\114.212.200.213\wangq\%name%

set name=Scripts
echo %name%
%exe% /leftreadonly /closescript @%script% d:\wq\%name% \\114.212.200.213\wangq\%name%

endlocal

:end
echo
echo All done. Byebye.
@echo on

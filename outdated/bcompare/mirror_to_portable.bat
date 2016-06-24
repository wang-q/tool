@echo off

echo I'm going to mirror folders to portable disk.
set /p yes="Type [yes] if you sure:"

if /i "%yes%" neq "yes" goto end

setlocal

set exe="c:\Program Files (x86)\Beyond Compare 3\BCompare.exe"
set script="d:\wq\Scripts\tool\bcompare\mirror_folders.txt"

set name=data
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=material
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=minicpan
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=software
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=wq
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=zotero
echo %name%
%exe% /leftreadonly /closescript @%script% d:\%name% f:\%name%

set name=tools
echo %name%
%exe% /leftreadonly /closescript @%script% c:\%name% f:\%name%

endlocal

:end
echo
echo All done. Byebye.
@echo on

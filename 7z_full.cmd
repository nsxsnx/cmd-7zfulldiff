echo OFF

REM slash at the end of all dirs!
set src_path=D:\Test\
set src_dir=somedir\
set backup_dir=D:\Test\
REM set exclude=-xr0!*.avi -xr0!*.jpg -xr0!*.mp3 -xr0!*.cab -xr0!*.msi -xr0!*.mpg
REM set ftp=ftp://login:pass@192.168.110.58
set ftp_dir=.

set pre_run1=
set pre_run1_parm=
set pre_run2=
set pre_run2_parm=
set post_run1=
set post_run1_parm=
set post_run2=
set post_run2_parm=
set post_run_on_error=yes

set v=111026
set log_file=%src_dir:~0,-1%.log
set err_file=%src_dir:~0,-1%.err.log
set exe_dir=.\exe\
call :l_SetDT
set arcfile=%backup_dir%%src_dir:~0,-1%_%dt%_Full.7z
set remotefile=%src_dir:~0,-1%_%dt%_Full.7z
set lastarcfile=%backup_dir%%src_dir:~0,-1%_Full_Last.7z

echo ------ >> %log_file%
echo %dt%: 7z FULL backup started (v.%v%) >> %log_file%
call :l_Run pre_run1 %pre_run1% %pre_run1_parm%
call :l_Run pre_run2 %pre_run2% %pre_run2_parm%

call :l_SetDT
echo %dt%: %exe_dir%7z.exe a -mx=7 -ssw %arcfile% %src_path%%src_dir% %exclude% >> %log_file%
%exe_dir%7z.exe a -mx=7 -ssw %arcfile% %src_path%%src_dir% %exclude%
if errorlevel 1 (
	call :l_SetDT
	echo %dt%: non fatal ERROR occured during 7z execution >> %log_file%
	echo %dt%: non fatal ERROR occured during 7z execution >> %err_file%
)
if errorlevel 2 (
	call :l_SetDT
	echo %dt%: an ERROR occured during 7z execution >> %log_file%
	echo %dt%: an ERROR occured during 7z execution >> %err_file%
	call :l_Die
)
call :l_SetDT
echo %dt%: 7z execution completed successfully >> %log_file%

call :l_SetDT
if not exist %arcfile% (
	echo %dt%: archive file DOES NOT exists: %arcfile% >> %log_file%
	echo %dt%: archive file DOES NOT exists: %arcfile% >> %err_file%
	call :l_Die
)
echo %dt%: archive file exists: %arcfile% >> %log_file%

call :l_SetDT
echo %dt%: creating a link %lastarcfile% >> %log_file%
del %lastarcfile%
mklink %lastarcfile% %arcfile%
call :l_SetDT
if errorlevel 1 (
	echo %dt%: creating of a link FAILED >> %log_file%
	echo %dt%: creating of a link FAILED >> %err_file%
	del /q %lastarcfile%
	call :l_Die
)
echo %dt%: a link has been created >> %log_file%

call :l_Run post_run1 %post_run1% %post_run1_parm%
call :l_Run post_run2 %post_run2% %post_run2_parm%
if not [%ftp%] == [] (
	call :l_Upload
)

call :l_SetDT
echo %dt%: FULL backup completed successfully >> %log_file%
goto :EOF

:l_SetDT
	set tm=%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%
	if ["%tm:~0,1%"] == [" "] (
		set tm=0%tm:~1,5%
	)
	set dt=%DATE:~8,2%%DATE:~3,2%%DATE:~0,2%_%tm%
	goto :EOF

:l_Die
	if not [%post_run_on_error%] == [] (
		call :l_Run post_run1 %post_run1% %post_run1_parm%
		call :l_Run post_run2 %post_run2% %post_run2_parm%
	)
	exit

:l_Run
	set name=%1%
	set run=%2%
	set parm=%3%
	if not [%run%] == [] (
		call :l_SetDT
		echo %dt%: starting %name%: %run% %parm%>> %log_file%
		%run% %parm%
	)
	goto :EOF

:l_Upload
	%exe_dir%winscp.com /command "option batch abort" "option confirm off" "open %ftp% -passive" "cd %ftp_dir%" "put %arcfile% %remotefile%" "chmod 444 %remotefile%" "exit"
	if errorlevel 1 (
		call :l_SetDT
		echo %dt%: an ERROR occured during uploading to ftp >> %log_file%
		echo %dt%: an ERROR occured during uploading to ftp >> %err_file%
		exit
	)


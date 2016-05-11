@setlocal
@echo http://kcat.strangesoft.net/openal.html
@set TMPREPO=git://repo.or.cz/openal-soft.git
@set TMPDIR=openal-source
@if NOT EXIST %TMPDIR%\nul goto CHKOUT

@cd %TMPDIR%
@call git status
@echo Continue with PULL - Ctrl+C to abort...
@pause

@call git pull
@cd ..

@goto END

:CHKOUT
@echo This is a FRESH checkout, since %TMPDIR% does NOT exist in %CD%
@echo Will do: 'call git clone %TMPREPO% %TMPDIR%'
@echo *** CONTINUE? *** Only Ctrl+c aborts. All other keys continue
@if "%~1x" == "x" goto WAIT
@if "%1x" == "NOPAUSEx" goto DOIT
:WAIT
@pause
:DOIT

call git clone %TMPREPO% %TMPDIR%

@if NOT EXIST %TMPDIR%\nul goto FAILED

@echo New clone done...

@goto END

:FAILED
@echo.
@echo ERROR: git clone into %TMPDIR% FAILED!
@echo.
@exit /b 1

:END

@REM eof


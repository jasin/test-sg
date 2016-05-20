@setlocal
@REM in boost root - bjam --build-dir=c:\boost --build-type=complete --toolset=msvc-9.0 address-model=64 architecture=x86 --with-system
@set CWD=%CD%
@call _selectMSVC.x64
@if ERRORLEVEL 1 goto NOMSVC
@REM echo Is MSVC setup ok... any key to continue...
@REM pause

@REM Send build output to a 'temporary' folder
@set TMPBLD=%CD%\build\boost
@if NOT EXIST build\nul ( @mkdir build )

@set BOOST_ROOT=%CD%\Boost
@if NOT EXIST %BOOST_ROOT%\nul goto NOBOOST
@REM This should be set in _selectMSVC
@set TMPINST=%CD%\%RDPARTY%

@cd %BOOST_ROOT%
@if ERRORLEVEL 1 goto NOROOT

@set TMPBS=bootstrap.bat
@set TMPEXE=b2.exe
@set TMPLIB=lib
@if EXIST %TMPLIB%\nul goto DONELIB

@if EXIST %TMPEXE% goto GOTBS
@if NOT EXIST %TMPBS% goto NOBS
call %TMPBS%
@if NOT EXIST %TMPEXE% goto ERR1
@echo Done bjam build...
@REM pause
:GOTBS

@set B2OPTS=stage
@set B2OPTS=%B2OPTS% --toolset=msvc
@set B2OPTS=%B2OPTS% --address-model=64
@set B2OPTS=%B2OPTS% --build-type=complete
@set B2OPTS=%B2OPTS% --build-dir=%TMPBLD%
@REM Maybe NOT required for 'stage' build
@set B2OPTS=%B2OPTS% --prefix="%TMPINST%"

@set TMPOPTS=%B2OPTS%
@echo Show libraries that will be built...
@echo Doing: %TMPEXE% %TMPOPTS% --show-libraries
@%TMPEXE% %TMPOPTS% --show-libraries
@echo *** CONTINUE with BUILD? *** Only Ctrl+C aborts. All other key continue...
@pause

@echo Doing %TMPEXE% %TMPOPTS%
@%TMPEXE% %TMPOPTS%
@if ERRORLEVEL 1 goto BJAMERR

@if NOT EXIST stage\lib\nul goto NOLIBS

@move stage\lib .
@if ERRORLEVEL 1 goto NOMOVE

@echo.
@echo For cleanup could delete ROOT\build\boost...
@echo Appears a successful Boost build...
@echo.
@goto END

:NOMOVE
@echo Error: Tried 'move stage\lib .`! Got error!
@goto ISERR

:NOLIBS
@echo.
@echo Action '%TMPEXE% %TMPOPTS%' did not build stage\lib dir!!!
@echo.
@goto ISERR

:BJAMERR
@echo.
@echo Action '%TMPEXE% %TMPOPTS%' exited error! Fix and re-run...
@echo.
@goto ISERR

:NOROOT
@echo Error: cd %BOOST_ROOT%! FAILED!
@goto ISERR

:NOBOOST
@echo Error: Can NOT locate boost root %BOOST_ROOT%! *** FIX ME ***
@goto ISERR

:ERR1
@echo ERROR: Unable to build the build tools, like %TMPEXE%
@goto ISERR

:NOBS
@echo ERROR: Can NOT locate %TMPBS% file in %CD%! *** FIX ME ***!!!
@goto ISERR

:NOMSVC
@echo ERROR: In MSVC setup...
@goto ISERR

:ISERR
@endlocal
@exit /b 1

:DONELIB
@echo.
@echo Found a 'lib' diretory in %CD%
@echo Delete this to RE-BUILD all the libraries
@echo.
@goto END


:END
@endlocal
@exit /b 0

@REM eof

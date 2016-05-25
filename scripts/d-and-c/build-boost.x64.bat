@setlocal
@REM in boost root - bjam --build-dir=c:\boost --build-type=complete --toolset=msvc-9.0 address-model=64 architecture=x86 --with-system
@set CWD=%CD%
@if NOT "%RDPARTY_DIR%x" == "x" goto DNSEL
@call _selectMSVC.x64
@if ERRORLEVEL 1 goto NOMSVC
@if "%RDPARTY_DIR%x" == "x" goto NOMSVC
@if "%GET_EXE%x" == "x" set GET_EXE=wget
@if "%GET_OPT%x" == "x" set GET_OPT=-O
@if "%UZ_EXE%x" == "x" set UZ_EXE=7z
@if "%UZ_OPT%x" == "x" set UZ_OPT=x
@if "%HAVELOG%x" == "x" set HAVELOG=0
@if "%ERRLOG%x" == "x" set ERRLOG=error2.txt
@REM echo Is MSVC setup ok... any key to continue...
@REM pause
:DNSEL
@goto DO_BOOST_BUILD
:DO_BOOST_SP
@echo %0: ##### Download ^& compile LIBBOOST %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ##### Download ^& compile LIBBOOST to %LOGFIL%
)

@REM But must have something of boost, even at this early stage
@echo But must have something of boost, even at this early stage... UGH!
@REM GOTO DO_BOOST2

@REM ECHO However this is ONLY obtaining the simpits boost and binaries %BLDLOG%
@REM ECHO while download_and_compile obtains the SVN source and does a compile %BLDLOG%
@REM ECHO So this is presently SKIPPED %BLDLOG%
@REM GOTO DN_BOOST
@REM :DO_BOOST2

@REM set TMP_URL=http://flightgear.simpits.org:8080/job/Boost-Win64/lastSuccessfulBuild/artifact/*zip*/archive.zip
@REM set TMP_URL=http://flightgear.simpits.org:8080/job/Boost-Win64/lastSuccessfulBuild/artifact/*zip*/Boost.zip
@REM 20160509 - Update Jenkins Boot-win artifacts...
@set TMP_URL=http://flightgear.simpits.org:8080/view/Windows/job/Boost-Win/lastSuccessfulBuild/artifact/*zip*/archive.zip
@set TMP_ZIP=libboost.zip
@set TMP_SRC=Boost

@if EXIST %TMP_SRC%\nul goto DN_BOOST_SP

@echo Check fo existance of %TMP_ZIP%

@if NOT EXIST %TMP_ZIP% (
@echo Doing 'CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%'
@CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
@if ERRORLEVEL 1 goto NO_B_ZIP
) else (
@echo Found simpits boost %TMP_ZIP%
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Download from %TMP_URL% to %TMP_ZIP% FAILED!
@echo %HAD_ERROR%: Download from %TMP_URL% to %TMP_ZIP% FAILED! >> %ERRLOG%
@GOTO NO_B_ZIP
@REM goto DN_BOOST
)

@if NOT EXIST Boost\nul (
@if NOT EXIST archive\Boost\nul (
@echo Doing: 'CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%'
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
MOVE archive\Boost .
RMDIR archive
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%!
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%! >> %ERRLOG%
@GOTO NO_B_SRC
)

CD %TMP_SRC%

@if NOT EXIST lib\nul (
@if EXIST lib64\nul (
@REN lib64 lib
)
)

@cd %CWD%
@REM if NOT EXIST include\boost-1_55\nul (
@REM MD include\boost-1_55
@REM )

@REM @if EXIST boost (
@REM MOVE boost include\boost-1_55
@REM )
@set _TMP_LIBS=%_TMP_LIBS% BOOST
@echo Have done simpits setup of Boost...

@goto DN_BOOST_SP
@REM Boost from simpits archive errors
:NO_B_ZIP
@echo Unable to download %TMP_ZIP%
@goto ISERR
:NO_B_SRC
@echo Failed to create %TMP_SRC%
@goto ISERR

:DN_BOOST_SP
@goto END 

:DO_BOOST_BUILD
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
@set B2OPTS=%B2OPTS% --build-type=complete
@set B2OPTS=%B2OPTS% --build-dir=%TMPBLD%
@set B2OPTS=%B2OPTS% toolset=msvc
@set B2OPTS=%B2OPTS% link=static
@set B2OPTS=%B2OPTS% address-model=64
@REM Maybe NOT required for 'stage' build
@REM set B2OPTS=%B2OPTS% --prefix="%TMPINST%"
@REM limit the build to just 'system' and 'thread'
@set B2OPTS=%B2OPTS% --with-system --with-thread --with-date_time

@set TMPOPTS=%B2OPTS%
@if "%SHOW_LIBS%x" == "1x" (
    @echo Show libraries that will be built...
    @echo Doing: %TMPEXE% %TMPOPTS% --show-libraries
    @%TMPEXE% %TMPOPTS% --show-libraries
    @echo *** CONTINUE with BUILD? *** Only Ctrl+C aborts. All other key continue...
    @pause
)

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

:SLEEP1
@echo Doing: 'timeout /t 1`
@timeout /t 1 >nul 2>&1
@goto :EOF

:END
@endlocal
@exit /b 0

@REM eof

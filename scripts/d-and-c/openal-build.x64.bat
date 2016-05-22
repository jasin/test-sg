@setlocal
@REM #############################################################
@REM Build OpenAL - 20160522
@REM Part of d-and-c project - expect call from make3rd.x64.bat - with MSVC ENV set
@REM ############################################################
@set CWD=%CD%
@set TMPSRC=%CD%\openal-source
@set TMPBLD=openal-build
@REM ####################################################
@REM fgmeta SuperBuild
@REM ####################################################
@set TMPPRJ=OpenAL
@echo Build %TMPPRJ% project, in 64-bits
@set BLDDIR=%CD%\%TMPBLD%
@REM Default - only release build...
@set BLDDBG=0
@if "%LOGFIL%x" == "x" @set LOGFIL=templog.txt

@if "%RDPARTY_DIR%x" == "x" goto NO_MSVC
@if "%GENERATOR%x" == "x" goto NO_GEN
@set TMPINST=%CD%\%RDPARTY_DIR%

@if EXIST %TMPSRC%\nul goto GOT_SRC
@REM no source, git it...
@set TMPREPO=git://repo.or.cz/openal-soft.git
@set TMPDIR=openal-source
@call git clone %TMPREPO% %TMPDIR%
@if ERRORLEVEL 1 goto NO_AL_CLONE
@REM clone worked...
@goto GOT_SRC
:NO_AL_CLONE
@echo Failed 'call git clone %TMPREPO% %TMPDIR%'
@goto ISERR
:NO_MSVC
@echo Failed RDPARTY_DIR must be set in ENV
@goto ISERR
:NO_GEN
@echo Failed GENERATOR must be set in ENV
@goto ISERR
:GOT_SRC

@REM set TMPSRC=..\openal-source
@if NOT EXIST %TMPSRC%\CMakeLists.txt goto NOCM

@if NOT EXIST %TMPINST%\nul goto NOINST

@if NOT EXIST %TMPBLD%\nul @md %TMPBLD%

@cd %TMPBLD%

@echo Doing OpenAL build output to %LOGFIL%
@echo Doing OpenAL build output to %LOGFIL% >> %LOGFIL%

@REM ############################################
@REM NOTE: SPECIAL INSTALL LOCATION
@REM Adjust to suit your environment
@REM ##########################################
@REM set TMPINST=F:\Projects\software.x64
@set TMPOPTS=-DCMAKE_INSTALL_PREFIX=%TMPINST%
@set TMPOPTS=%TMPOPTS% -G "%GENERATOR%"

@REM call chkmsvc %TMPPRJ%

@REM Special extra clean ups, until it runs...
@REM Some HELP finding things

@if EXIST CMakeCache.txt @del CMakeCache.txt

@echo Doing: 'cmake %TMPSRC% %TMPOPTS%'
@echo Doing: 'cmake %TMPSRC% %TMPOPTS%' >> %LOGFIL%
@cmake %TMPSRC% %TMPOPTS% >> %LOGFIL% 2>&1
@if ERRORLEVEL 1 goto ERR1

@if NOT %BLDDBG% EQU 1 goto DNDBG

@echo Doing: 'cmake --build . --config debug'
@echo Doing: 'cmake --build . --config debug' >> %LOGFIL%
@cmake --build . --config debug >> %LOGFIL%
@if ERRORLEVEL 1 goto ERR2

:DNDBG

@echo Doing: 'cmake --build . --config release'
@echo Doing: 'cmake --build . --config release' >> %LOGFIL%
@cmake --build . --config release >> %LOGFIL% 2>&1
@if ERRORLEVEL 1 goto ERR3
:DNREL

@echo Appears a successful build
@echo.
@echo Note install location %TMPINST%
@echo.

@if NOT %BLDDBG% EQU 1 goto DNDBG2
@REM cmake -P cmake_install.cmake
@echo Doing: 'cmake --build . --config debug --target INSTALL'
@echo Doing: 'cmake --build . --config debug --target INSTALL' >> %LOGFIL%
@cmake --build . --config debug --target INSTALL >> %LOGFIL% 2>&1
@if ERRORLEVEL 1 goto ERR4

:DNDBG2

@echo Doing: 'cmake --build . --config release --target INSTALL'
@echo Doing: 'cmake --build . --config release --target INSTALL' >> %LOGFIL%
@cmake --build . --config release --target INSTALL >> %LOGFIL% 2>&1
@if ERRORLEVEL 1 goto ERR5

@REM fa4 " -- " %LOGFIL%

@echo Done build and install of %TMPPRJ%...
@echo Done build and install of %TMPPRJ%... >> %LOGFIL%

@goto END

:NOCM
@echo.
@echo CD:%CD% Can NOT locate %TMPSRC%\CMakeLists.txt! *** FIX ME ***
@echo.
@goto ISERR

:NOINST
@echo Can NOT locate directory %TMPINST%! *** FIX ME ***
@goto ISERR

:ERR1
@echo cmake config, generation error
@goto ISERR

:ERR2
@echo debug build error
@goto ISERR

:ERR3
@fa4 "mt.exe : general error c101008d:" %LOGFIL% >nul
@if ERRORLEVEL 1 goto ERR32
:ERR33
@echo release build error
@goto ISERR
:ERR32
@echo Stupid error... trying again...
@echo Doing: 'cmake --build . --config release'
@echo Doing: 'cmake --build . --config release' >> %LOGFIL%
@cmake --build . --config release >> %LOGFIL% 2>&1
@if ERRORLEVEL 1 goto ERR33
@goto DNREL

:ERR4
@echo debug install error
@goto ISERR

:ERR5
@echo release install error
@goto ISERR

:ISERR
@cd %CWD%
@echo FAILED build and install of %TMPPRJ%... >> %LOGFIL%
@endlocal
@exit /b 1

:END
@cd %CWD%
@endlocal
@exit /b 0

@REM eof

@setlocal
@set TMPSRC=%CD%\openal-source
@set TMPBLD=openal-build

@if NOT EXIST %TMPBLD%\nul @md %TMPBLD%

@cd %TMPBLD%

@REM ####################################################
@REM fgmeta SuperBuild
@REM ####################################################
@set TMPPRJ=OpenAL
@echo Build %TMPPRJ% project, in 64-bits
@set TMPLOG=bldlog-1.txt
@set BLDDIR=%CD%
@REM Default - only release build...
@set BLDDBG=1
@set TMPROOT=..

@set SET_BAT=%ProgramFiles(x86)%\Microsoft Visual Studio %_MSVS%.0\VC\vcvarsall.bat
@if NOT EXIST "%SET_BAT%" goto NOBAT
@if NOT EXIST %TMPROOT%\nul goto NOROOT
@REM set TMPSRC=..\openal-source
@if NOT EXIST %TMPSRC%\CMakeLists.txt goto NOCM

@if /I "%PROCESSOR_ARCHITECTURE%" EQU "AMD64" (
@set TMPINST=%TMPROOT%\3rdParty.x64
) ELSE (
@echo ERROR: Appears 64-bit is NOT available... aborting...
@goto ISERR
)
@if NOT EXIST %TMPINST%\nul goto NOINST

@echo Doing build output to %TMPLOG%
@echo Doing build output to %TMPLOG% > %TMPLOG%

@echo Doing: 'call "%SET_BAT%" %BUILD_BITS%
@echo Doing: 'call "%SET_BAT%" %BUILD_BITS%' >> %TMPLOG%
@call "%SET_BAT%" %BUILD_BITS% >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR0
@REM call setupqt64
@cd %BLDDIR%

:DNARCH

@pushd %TMPINST%
@set TMPINST=%CD%
@popd

@REM ############################################
@REM NOTE: SPECIAL INSTALL LOCATION
@REM Adjust to suit your environment
@REM ##########################################
@REM set TMPINST=F:\Projects\software.x64
@set TMPOPTS=-DCMAKE_INSTALL_PREFIX=%TMPINST%
@set TMPOPTS=%TMPOPTS% -G "Visual Studio %_MSVS% Win64"

:RPT
@if "%~1x" == "x" goto GOTCMD
@set TMPOPTS=%TMPOPTS% %1
@shift
@goto RPT
:GOTCMD

@call chkmsvc %TMPPRJ%

@REM Special extra clean ups, until it runs...
@REM Some HELP finding things

@echo Begin %DATE% %TIME%, output to %TMPLOG%
@echo Begin %DATE% %TIME% >> %TMPLOG%

@if EXIST CMakeCache.txt @del CMakeCache.txt

@echo Doing: 'cmake %TMPSRC% %TMPOPTS%'
@echo Doing: 'cmake %TMPSRC% %TMPOPTS%' >> %TMPLOG%
@cmake %TMPSRC% %TMPOPTS% >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR1

@if NOT %BLDDBG% EQU 1 goto DNDBG

@echo Doing: 'cmake --build . --config debug'
@echo Doing: 'cmake --build . --config debug' >> %TMPLOG%
@cmake --build . --config debug >> %TMPLOG%
@if ERRORLEVEL 1 goto ERR2

:DNDBG

@echo Doing: 'cmake --build . --config release'
@echo Doing: 'cmake --build . --config release' >> %TMPLOG%
@cmake --build . --config release >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR3
:DNREL

@echo Appears a successful build
@echo.
@REM echo No INSTALL configured at this time
@REM goto END

@echo Note install location %TMPINST%
@echo.
choice /D Y /T 10 /M "Pausing for 10 seconds. Def=Y"
@if ERRORLEVEL 3 goto NOCHOICE
@if ERRORLEVEL 2 goto GOTNO
@goto DOINST
:NOCHOICE
@REM Ask, or continue...
@ask *** CONTINUE with install? *** Only y continues
@if ERRORLEVEL 2 goto NOASK
@if ERRORLEVEL 1 goto DOINST
:GOTNO
@echo.
@echo Skipping install to %TMPINST% at this time...
@echo.
@goto END
:NOASK
@echo ask not found in path...
@echo *** CONTINUE with install? *** Only ctrl+c aborts... all other keys continue..
@pause

:DOINST

@if NOT %BLDDBG% EQU 1 goto DNDBG2
@REM cmake -P cmake_install.cmake
@echo Doing: 'cmake --build . --config debug --target INSTALL'
@echo Doing: 'cmake --build . --config debug --target INSTALL' >> %TMPLOG%
@cmake --build . --config debug --target INSTALL >> %TMPLOG% 2>&1

:DNDBG2

@echo Doing: 'cmake --build . --config release --target INSTALL'
@echo Doing: 'cmake --build . --config release --target INSTALL' >> %TMPLOG%
@cmake --build . --config release --target INSTALL >> %TMPLOG% 2>&1

@fa4 " -- " %TMPLOG%

@echo Done build and install of %TMPPRJ%...

@goto END

:NOBAT
@echo Can NOT locate MSVC setup batch "%SET_BAT%"! *** FIX ME ***
@goto ISERR

:NOROOT
@echo Can NOT locate %TMPROOT%! *** FIX ME ***
@goto ISERR

:NOCM
@echo.
@echo CD:%CD% Can NOT locate %TMPSRC%\CMakeLists.txt! *** FIX ME ***
@echo.
@goto ISERR

:NOINST
@echo Can NOT locate directory %TMPINST%! *** FIX ME ***
@goto ISERR

:ERR0
@echo MSVC 10 setup error
@goto ISERR

:ERR1
@echo cmake config, generation error
@goto ISERR

:ERR2
@echo debug build error
@goto ISERR

:ERR3
@fa4 "mt.exe : general error c101008d:" %TMPLOG% >nul
@if ERRORLEVEL 1 goto ERR32
:ERR33
@echo release build error
@goto ISERR
:ERR32
@echo Stupid error... trying again...
@echo Doing: 'cmake --build . --config release'
@echo Doing: 'cmake --build . --config release' >> %TMPLOG%
@cmake --build . --config release >> %TMPLOG% 2>&1
@if ERRORLEVEL 1 goto ERR33
@goto DNREL

:ISERR
@endlocal
@exit /b 1

:END
@endlocal
@exit /b 0

@REM eof


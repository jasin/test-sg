@setlocal
@set DBG_MSVC=1
@REM After testing, the above will be removed
@REM is meant to be called from another BAT to set the ENV
@REM ##############################################################
@REM Setting -
@REM TMPERR = should be zero on exit
@REM _MSVS  = Visual Studion Version
@REM _MSNUM = MS version emitted
@REM VS_PATH = THe root path to the MSVC installed
@REM VS_BAT = Usually vcvarsall.bat
@REM BUILD_BITS = The parameter to use when calling the above
@REM GENERATOR = The cmake -G value
@REM ##############################################################
@set TMPERR=0
@REM Switch MSVC Version
@set _MSVS=10
@set _MSNUM=1600
@set VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio %_MSVS%.0
@set "VS_BAT=%VS_PATH%\VC\vcvarsall.bat"
@set BUILD_BITS=%PROCESSOR_ARCHITECTURE%
@set GENERATOR=Visual Studio %_MSVS% Win64
@IF EXIST "%VS_PATH%" goto GOT_VS_PATH
@set _MSVS=12
@set _MSNUM=1800
@set VS_PATH=%ProgramFiles(x86)%\Microsoft Visual Studio %_MSVS%.0
@set "VS_BAT=%VS_PATH%\VC\vcvarsall.bat"
@REM set BUILD_BITS=%PROCESSOR_ARCHITECTURE%
@set GENERATOR=Visual Studio %_MSVS% Win64
@IF EXIST "%VS_PATH%" goto GOT_VS_PATH
@REM Could search for other VERSIONS
@REM *******************************
@goto NO_VS_PATH

:GOT_VS_PATH
@IF NOT exist "%VS_BAT%" goto NO_VS_BAT
@REM ######################### CHECK AVAILABLE TOOLS ######################################

@echo Set ARCHITECTURE, based on PROCESSOR_ARCHITECTURE=%BUILD_BITS%
@REM ####################### SET 32/64 BITS ARCHITECTURE ##################################
@IF exist "%VS_PATH%\VC\bin\%BUILD_BITS%" (
    @set "RDPARTY_ARCH=x64"
    @set "RDPARTY_DIR=3rdParty.x64"
    @set "MSVCBIN=%VS_PATH%\VC\bin\%BUILD_BITS%\vcvars%BUILD_BITS%.bat"
    @set "COMPILER=%BUILD_BITS%"
) ELSE (
    @IF exist "%VS_PATH%\VC\bin\x86_%BUILD_BITS%" ( 
        @set "RDPARTY_ARCH=x64"
        @set "RDPARTY_DIR=3rdParty.x64"
        @set "MSVCBIN=%VS_PATH%\VC\bin\x86_%BUILD_BITS%\vcvarsx86_%BUILD_BITS%.bat"
        @set "COMPILER=x86_%BUILD_BITS%"
    ) ELSE (
        @set "RDPARTY_ARCH=win32"
        @set "RDPARTY_DIR=3rdParty"
        @set "MSVCBIN=%VS_PATH%\VC\bin\vcvars32.bat"
        @echo.
        @echo BUILD neither x86_amd64 nor amd64. IE no 64-bit build!
        @echo *** FIX ME *** if some other BUILD_BITS=%BUILD_BITS% is correct...
        @echo and just comment out this exit
        @set TMPERR=1
        @goto END
    )
)

@REM what is in bin? x86_amd64 and/or amd64
@echo 1: Checking for "%MSVCBIN%" ...
@if EXIST "%MSVCBIN%" goto GOT_BIN
@echo Warning: Can NOT locate "%MSVCBIN%
@REM oops found nothing... what to do???
@echo.
@echo Can NOT locate neither x86_amd64 nor amd64. Maybe no 64-bit build!
@echo *** FIX ME *** if some other BUILD_BITS=%BUILD_BITS% is correct...
@set TMPERR=1
@set MSVCBIN=
@goto END

:GOT_BIN

@echo Will: CALL "%VS_BAT%" %COMPILER%
@call "%VS_BAT%" %COMPILER%
@if ERRORLEVEL 1 goto BAT_FAILED

@echo Have set the MSVC%_MSVS% (%_MSNUM%) environment... Platform=%Platform%
@if "%DBG_MSVC%x" == "x" goto END
@REM #######################################################
@REM Runs some verification tests...

@call nmake /? >nul
@if ERRORLEVEL 1 goto NMAKE_FAILED
@echo.
@echo Some information about that environment
@if /i "%Platform%x" == "x" goto DN_PLAT
@echo Note Platform=%Platform%
:DN_PLAT
@if "%INCLUDE%x" == "x" goto DN_INC
@echo Includes for COMPILING
@echo Have INCLUDE=%INCLUDE%
:DN_INC
@if "%LIB%x" == "x" goto DN_LIB
@echo Lib paths for LINKING
@echo Have LIB=%LIB%
:DN_LIB

@goto END

:BAT_FAILED
@echo.
@echo Oops the setup BAT "%VS_BAT%" FAILED!
@set TMPERR=1
@goto END

:NAMKE_FAILED
@echo.
@echo Oops NMAKE /? FAILED!
@set TMPERR=1
@goto END

:NO_VS_PATH
	@echo.
    @echo ERROR: "%VS_PATH%" doesn't exist
    @echo You must install a working MSVC, and adjust version above...
	@set TMPERR=1
	@echo.
@goto END

:NO_VS_BAT
	@echo.
    @echo ERROR: %VS_BAT% doesn't exist
    @echo You must install a working MSVC, to have this BAT
	@set TMPERR=1
	@echo.
@goto END

:END
@REM For debug ONLY
@endlocal
@exit /b %TMPERR%

@REM eof

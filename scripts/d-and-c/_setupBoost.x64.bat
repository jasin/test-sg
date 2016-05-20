@setlocal
@REM ###########################################################################
@REM ################### Build Boost download source & build ###################
@REM ###########################################################################

@set PWD=%CD%
@REM #### STAND-ALONE - DEBUG ####
@if NOT "%RDPARTY_DIR%x" == "x" goto DNSEL
@set GET_EXE=wget
@set GET_OPT=-O
@set UZ_EXE=7z
@set UZ_OPT=x
@call _selectMSVC.x64.bat
@REM #### STAND-ALONE - DEBUG ####
:DNSEL
@if "%RDPARTY_DIR%x" == "x" goto NOSEL

@set BOOST_MAJ=1
@set BOOST_MIN=60
@set BOOST_REV=0
@set BOOST_DOT_VER=%BOOST_MAJ%.%BOOST_MIN%.%BOOST_REV%
@set BOOST_DASH_VER=%BOOST_MAJ%_%BOOST_MIN%_%BOOST_REV%
@set BOOST_URL="https://sourceforge.net/projects/boost/files/boost/%BOOST_DOT_VER%/boost_%BOOST_DASH_VER%.7z"
@set BOOST_INSTALL_DIR=%PWD%\%RDPARTY_DIR%
@REM set COMPILE=1

:DO_BOOST
@set _TMP_BZ7=boost_%BOOST_DASH_VER%.7z
@echo ##############################
@echo ##########  BOOST  ###########
@echo ##############################

@if NOT exist Boost\nul (
    @if NOT EXIST  %_TMP_BZ7% (
        @REM Download the zip
        @echo Doing 'call %GET_EXE% %GET_OPT% %_TMP_BZ7% %BOOST_URL%'
        @call %GET_EXE% %GET_OPT% %_TMP_BZ7% %BOOST_URL%
        @if ERRORLEVEL 1 goto NODWN
        
    )
    @if NOT EXIST %_TMP_BZ7% (
        @echo ERROR: Failed in call %GET_EXE% %GET_OPT% %_TMP_BZ7% %BOOST_URL%
        @set %HAD_ERR%+=1
        @goto ISERR
    )
    @call %UZ_EXE% %UZ_OPT% %_TMP_BZ7%
    @ren boost_%BOOST_DASH_VER% Boost
)
@if NOT exist Boost\nul goto NOBOOST
@call build-boost.x64
@if ERRORLEVEL 1 goto NOBLD

echo Done Boost ...
@goto DN_BOOST

:NOSEL
@echo.
@echo ERROR: RDPARTY NOT set in the ENV!
@echo.
@goto ISERR

:NODWN
@echo.
@echo ERROR: Failed download of %_TMP_BZ7%!
@echo.
@goto ISERR

:NOBOOST
@echo.
@echo ERROR: No Boost source directory created!
@echo.
@goto ISERR

:NOBLD
@echo.
@echo ERROR: Boost build has FAILED!
@echo.
@goto ISERR

:ISERR
@exit /b 1


:DN_BOOST

:exit

@REM eof

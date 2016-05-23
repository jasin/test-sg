@setlocal
@echo off
@REM History, growing upwards...
@REM d-and-c.x64.bat v1.3.11 20160522 - use external make3rd.x64.bat ...
@set TMPMK3RD=make3rd.x64.bat
@REM d-and-c.x64.bat v1.3.10 20160515 - use external _selectMSVC.x64.bat ...
@REM d-and-c.x64.bat v1.3.9 20160515 - Name change... add .x64 build ...
@REM d-and-c.bat v1.3.8 20160510 geoff - Fix config, gen, ...
@REM d-and-c.bat v1.3.7 20160509 geoff - Boost done in make3rd.x64 run
@REM d-and-c.bat v1.3.6 20160428 geoff - added SG/FG Debug build /D
@REM d-and-c.bat v1.3.5 20150614 geoff
@REM d-and-c.bat v1.3.4 20140903 geoff
@REM Original: Clement de l'Hamaide - Oct 2013
@REM Required software: Visual Studio 10, CMake, SVN, GIT, gmp and libcgal
@REM 
@set HAD_ERROR=0
set  error=0
@set PWD=%CD%
@set "WORKSPACE=%CD%"
@set INSTALL_DIR=%PWD%\install
@REM set FG_ROOT=x:\fgdata
@set FG_ROOT=%INSTALL_DIR%\fgdata
@REM IF NOT EXIST %FG_ROOT%\version (
@REM echo Unable to locate %FG_ROOT%\version
@REM exit /b 1
@REM )
@set LOGFIL=%PWD%\build\bldlog-1.txt
@echo Begin build %DATE% %TIME% > %LOGFIL%
@set BLDLOG=
@set HAVELOG=0
@REM Uncomment this, and add %BLDLOG% to config/build lines, if you want output to a LOG
@set BLDLOG= ^>^> %LOGFIL% 2^>^&1
@set HAVELOG=1
@set TMPDN3RD=make3rd.x64.txt

@if EXIST %TMPDN3RD% goto DONE_3RD

:NO3RD
@REM Oops, the 3rdParty setup has NOT run, sans fault...
@REM Do we have a setup batch file?
@if NOT EXIST %TMPMK3RD% goto NO3RD2
@REM Call it... to fix 3rd Party
@echo Doing: 'call %TMPMK3RD%' ... to fix 3rd Party
@call %TMPMK3RD%
@if ERRORLEVEL 1 goto NO3RD1
@if NOT EXIST %TMPDN3RD% goto NO3RD1
@echo A successful setup of %RDPARTY_DIR% %BLDLOG%
@goto DONE_3RD

:NO3RD1
@set /A HAD_ERROR+=1
@echo.
@echo Ran %TMPDN3RD%, but still an error!
@echo Sometimes just re-running %TMPDN3RD% can fix the problem...
@echo If NOT, file an issue https://github.com/geoffmcl/test-sg/issues
@echo Or fork the repo, find the problems, and present a PR... thanks...
@echo.
@goto ISERR

:NO3RD2
@set /A HAD_ERROR+=1
@echo.
@echo Can NOT locate file %TMPDN3RD%!
@echo And can NOT locate file %TMPMK3RD% to fix this...!
@echo.
@goto ISERR

:DONE_3RD
@REM ######################################################################################
@REM externa; setup
@set TMP_MSVC=_selectMSVC.x64.bat
@if NOT "%RDPARTY_DIR%x" == "x" goto DNSEL
@if NOT EXIST %TMP_MSVC% goto NO_MSVC_SEL 

@REM Switch MSVC Version
@set _MSVS=0
@set _MSNUM=0
@set VS_BAT=
@set GENERATOR=
@set MSC_VERS=
@call %TMP_MSVC%
@if "%GENERATOR%x" == "x" (
@set /A HAD_ERROR+=1
@set /A error+=1
@echo.
@echo No GENERATOR set! %TMP_MSVC% FAILED! **FIX ME**
@echo.
@goto ISERR
)
@if "%VS_BAT%x" == "x" (
@set /A HAD_ERROR+=1
@set /A error+=1
@echo.
@echo No ENV VS_BAT SET_BAT set! %TMP_MSVC% FAILED! **FIX ME**
@echo.
@goto ISERR
)
@if "%MSC_VERS%x" == "x" (
@set /A HAD_ERROR+=1
@set /A error+=1
@echo.
@echo No ENV MSC_VER set! Expect 'msvc100', ... %TMP_MSVC% FAILED! **FIX ME**
@echo.
@goto ISERR
)
:DNSEL
@REM MSVC has been setup, do NOT call this a 2nd time
@set VS_BAT=

@set CGAL_DIR=libcgal-source

REM ######################################################################################
REM ############################## SEARCH PATHS ##########################################
REM Search SVN.EXE path
set SVN_EXE=svn
CALL %SVN_EXE% --version --quiet
@if ERRORLEVEL 1 goto TRYSVNREG
@echo Found SVN
@goto GOTSVN
:TRYSVNREG
FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY HKLM\Software\TortoiseSVN /v Directory') DO SET SVN_EXE=%%Bbin\svn.exe
:GOTSVN
REM Search CMAKE.EXE path
set CMAKE_EXE=cmake
CALL %CMAKE_EXE% --version
@if ERRORLEVEL 1 goto TRYCMAKEREG
@echo Found CMAKE
@goto GOTCMAKE
:TRYCMAKEREG
FOR /F "tokens=1* delims=\" %%A IN ('REG QUERY HKLM\Software\Wow6432Node\Kitware') DO SET CMAKE_REG=HKLM\%%B
FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY "%CMAKE_REG%" /ve') DO SET CMAKE_EXE=%%B\bin\cmake.exe
IF NOT exist "%CMAKE_EXE%" (
	FOR /F "tokens=3* delims=	 " %%A IN ('REG QUERY "%CMAKE_REG%" /ve') DO SET CMAKE_EXE=%%B\bin\cmake.exe
)
:GOTCMAKE

REM Search GIT path
@set GIT_EXE=git
CALL %GIT_EXE% --version
@if ERRORLEVEL 1 goto TRYGITREG
@echo Found GIT
@goto GOTGIT
:TRYGITREG
FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY HKCU\Software\Git-Cheetah /v PathToMsys') DO SET string=%%B
SET GIT_PATH=%string:git-cheetah\..=bin%
:GOTGIT

REM Search CGAL path
@if "%CGAL_DIR%x" == "x" (
FOR /F "tokens=2* delims=	 " %%A IN ('REG QUERY HKCU\Environment /v CGAL_DIR') DO SET CGAL_PATH=%%B
@REM set "CGAL_PATH=C:\Program Files\CGAL-4.3"
) else (
@set "CGAL_PATH=%CGAL_DIR%"
)

REM ######################### SET EXECUTABLES PATH #######################################
REM set "CURL_EXE=%GIT_PATH%\curl.exe"
REM set "GIT_EXE=%GIT_PATH%\git.exe"
REM set "UNZIP_EXE=%GIT_PATH%\unzip.exe"
set CURL_EXE=wget
set CURL_OPTS=-O
set UNZIP_EXE=C:\MDOS\temp\unix\unzip.exe
set "VC_BAT=%VS_PATH%\VC\vcvarsall.bat"

REM #########################     SET REPO PATH     ######################################
set "BOOST_REPO=http://svn.boost.org/svn/boost/tags/release/Boost_1_55_0"
set "CGAL_REPO=https://gforge.inria.fr/frs/download.php/32358/CGAL-4.2.zip"
set "RDPARTY_REPO=http://fgfs.goneabitbursar.com/fgwin3rdparty/trunk/%MSC_VERS%"
set "FG_REPO=git://git.code.sf.net/p/flightgear/flightgear"
set "TG_REPO=git://git.code.sf.net/p/flightgear/terragear"
set "TGGUI_REPO=git://git.code.sf.net/p/flightgear/fgscenery/terrageargui"
set "SG_REPO=git://git.code.sf.net/p/flightgear/simgear"
set "FGRUN_REPO=git://git.code.sf.net/p/flightgear/fgrun"
set "FGDATA_REPO=git://git.code.sf.net/p/flightgear/fgdata"
@REM set "FGDATA_REPO=git://mapserver.flightgear.org/fgdata"
set "FGSG_BRANCH=next"
set "FGDATA_BRANCH=master"
set "TG_BRANCH=scenery/ws2.0"
set "TGGUI_BRANCH=master"

REM #########################       GOTO HELP       ######################################
IF "%1"=="--help" GOTO Usage
IF "%1"=="-h" GOTO Usage
IF "%1"=="/h" GOTO Usage
IF "%1"=="/?" GOTO Usage
IF "%1"=="/help" GOTO Usage


IF "%CGAL_PATH%"=="" (
echo.
echo ERROR ! "CGAL path can't be found in environment or registry"
echo You must install it ^( https://gforge.inria.fr/frs/download.php/32362/CGAL-4.2-Setup.exe ^)
set "error=1"
echo.
)
IF NOT exist "%CGAL_PATH%"\auxiliary\gmp\lib\libgmp*.lib (
echo.
echo ERROR ! LIBGMP doesn't exist at %CGAL_PATH%\auxiliary\gmp\lib\
echo You must install it ^( https://gforge.inria.fr/frs/download.php/32362/CGAL-4.2-Setup.exe ^)
set "error=1"
echo.
)

IF "%SVN_EXE%"=="" (
	echo.
    echo ERROR ! "SVN.EXE can't be found in PATH or registry"
    echo You must install it ^( http://tortoisesvn.net/downloads.html ^)
	set "error=1"
	echo.
)
REM IF NOT exist "%SVN_EXE%" (
REM	echo.
REM    echo ERROR ! "%SVN_EXE%" doesn't exist
REM    echo You must install it ^( http://tortoisesvn.net/downloads.html ^)
REM	set "error=1"
REM	echo.
REM )
REM IF "%GIT_PATH%"=="" (
REM	echo.
REM    echo ERROR ! "GIT path can't be found in registry"
REM    echo You must install it ^( http://git-scm.com/download/win ^)
REM	set "error=1"
REM	echo.
REM )
REM IF NOT exist "%GIT_EXE%" (
REM	echo.
REM    echo ERROR ! "%GIT_EXE%" doesn't exist
REM    echo You must install it ^( http://git-scm.com/download/win ^)
REM	set "error=1"
REM	echo.
REM )
REM IF NOT exist "%CURL_EXE%" (
REM	echo.
REM    echo ERROR ! "%CURL_EXE%" doesn't exist
REM	echo You must install it ^( http://git-scm.com/download/win ^)
REM	set "error=1"
REM	echo.
REM )
REM IF NOT exist "%UNZIP_EXE%" (
REM	echo.
REM    echo ERROR ! "%UNZIP_EXE%" doesn't exist
REM    echo You must install it ^( http://git-scm.com/download/win ^)
REM	set "error=1"
REM	echo. 
REM )
IF %error% EQU 1 (
	exit /b 1
)

@REM /O option uses REPO2
@set _TMP_OSG_REPO=http://flightgear.simpits.org:8080/view/Windows/job/OSG-Win/lastSuccessfulBuild/artifact/*zip*/archive.zip
@set _TMP_OSG_REPO2=https://github.com/openscenegraph/OpenSceneGraph.git
@REM altern set _TMP_OSG_REPO=http://flightgear.simpits.org:8080/view/Windows/job/OSG-Win/lastSuccessfulBuild/artifact/install/*zip*/install.zip
@REM set _TMP_OSG_REPO=http://flightgear.simpits.org:8080/view/Win/job/OSG-stable-Win64/lastSuccessfulBuild/artifact/install/%MSC_VERS%-64/OpenSceneGraph/*zip*/OpenSceneGraph.zip"
@set "OSG_REPO=%_TMP_OSG_REPO%"
@set OSG_DIR=%MSC_VERS%-64
@set OSG_REPO2=%_TMP_OSG_REPO2%
@set OSG_BRANCH=OpenSceneGraph-3.4

REM ############################      SET PATHS      #####################################
IF NOT exist install ( mkdir install )
IF NOT exist build ( mkdir build )
set "OSG_INSTALL_DIR=%INSTALL_DIR%\OpenSceneGraph"
@REM 20160509 - Include Boost in make3rd.x64.bat
set "BOOST_INSTALL_DIR=%PWD%\Boost"
@REM This does a complete clone, and build of boost
@REM set "BOOST_INSTALL_DIR=%INSTALL_DIR%\Boost"
set "RDPARTY_INSTALL_DIR=%PWD%\%RDPARTY_DIR%"
set "SIMGEAR_INSTALL_DIR=%INSTALL_DIR%\SimGear"
set "FLIGHTGEAR_INSTALL_DIR=%INSTALL_DIR%\FlightGear"
set "FGDATA_INSTALL_DIR=%FLIGHTGEAR_INSTALL_DIR%\fgdata"
set "FGRUN_INSTALL_DIR=%INSTALL_DIR%\FGRun"
set "TERRAGEAR_INSTALL_DIR=%INSTALL_DIR%\TerraGear"
set "TGGUI_INSTALL_DIR=%INSTALL_DIR%\TerraGearGUI"
set "CGAL_INSTALL_DIR=%INSTALL_DIR%\CGAL"
REM IF "%FG_ROOT%x" == "x" goto DN_FGROOT
REM IF NOT EXIST %FG_ROOT%\nul goto DN_FGROOT
REM IF NOT EXIST %FG_ROOT%\version goto DN_FGROOT
REM set /p "FGVER=" < %FG_ROOT%\version
REM set FGDATA_INSTALL_DIR=%FG_ROOT%
REM echo set FGDATA_INSTALL_DIR to %FG_ROOT% version %FGVER%
REM :DN_FGROOT

REM ###########################      SET OPTIONS      ####################################
set "PULL=1"
set "CMAKE=1"
set "COMPILE=1"
set DEBUGBLD=0
@REM OSG Install - 0 == simpits binaries - archive.zip - 1 == OSG Repo clone
set OSGREPO=0

REM ###################### DOWNLOAD FGDATA IN BACKGROUND #################################
IF "%1"=="" (
    set BUILD_ALL=1
    IF NOT exist "%FLIGHTGEAR_INSTALL_DIR%" ( mkdir "%FLIGHTGEAR_INSTALL_DIR%" )
    REM echo Uncomment this is you need to clone fgdata
    REM echo Start FGDATA download in background
    REM START "" /MIN cmd /C "%PWD%"\download_and_compile.bat fgdata
) ELSE (
    set BUILD_ALL=0
)

REM test jump
REM GOTO boost
REM GOTO terragear

REM ###########################    PARSE ARGUMENTS    ####################################
:Parser
IF %BUILD_ALL% EQU 0 (
    IF "%1"=="" (
        GOTO finished
    )
	IF "%1" == "/P" (
		set "PULL=0"
		SHIFT
		GOTO Parser
	)
	IF "%1" == "/M" (
		set "CMAKE=0"
		SHIFT
		GOTO Parser
	)
	IF "%1" == "/C" (
		set "COMPILE=0"
		SHIFT
		GOTO Parser
	)
	IF "%1" == "/D" (
		set DEBUGBLD=1
		SHIFT
		GOTO Parser
	)
	IF "%1" == "/O" (
		set OSGREPO=1
		SHIFT
		GOTO Parser
	)
    ECHO goto %1
	GOTO %1
    @if ERRORLEVEL 1 (
        @echo Build of %1 FAILED!
        @exit /b 1
    )
)

:3rdparty
echo ##############################
echo #########  3RDPARTY  #########
echo ##############################
@REM This could be replaced by BUILDING all the 3rdParty components
cd "%PWD%"
ECHO Check if %PWD%\%RDPARTY_DIR% exists
IF NOT exist %PWD%\%RDPARTY_DIR%\nul (
    echo Cloning "%RDPARTY_REPO%/%RDPARTY_DIR%"...
    CALL %SVN_EXE% co %RDPARTY_REPO%/%RDPARTY_DIR% %RDPARTY_DIR%
)
cd "%PWD%"
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

@REM 20160509 - Boost now comes with 3rdParty
@goto DN_BOOST
:boost
echo ##############################
echo ##########  BOOST  ###########
echo ##############################
cd "%PWD%"
IF NOT exist "%PWD%"\boost (
    echo Cloning "%BOOST_REPO%"...
    CALL "%SVN_EXE%" co "%BOOST_REPO%" boost
)
cd "%PWD%"\boost
IF %COMPILE% EQU 1 (
    echo Checking BOOST_INSTALL_DIR=%BOOST_INSTALL_DIR%
	IF NOT exist %BOOST_INSTALL_DIR% (
		call .\bootstrap
        IF /i %RDPARTY_ARCH% EQU x84 (
                .\b2 install --prefix="%BOOST_INSTALL_DIR%" address-model=64
            ) ELSE (
                .\b2 install --prefix="%BOOST_INSTALL_DIR%"
            )
		)
	) else (
        echo Already done! Remove %BOOST_INSTALL_DIR% to redo...
    )
)
cd "%PWD%"
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:DN_BOOST

@REM test exit
@REM GOTO finished

:cgal
echo ##############################
echo ###########  CGAL  ###########
echo ##############################

IF NOT exist %CGAL_INSTALL_DIR% (
	cd "%PWD%"\build
	IF NOT exist cgal (mkdir cgal)
	cd cgal
	IF %CMAKE% EQU 1 (
		DEL CMakeCache.txt 2>nul
		ECHO "Doing: 'CALL %CMAKE_EXE% %CGAL_PATH% -G %GENERATOR% -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX:PATH=%CGAL_INSTALL_DIR% -DCMAKE_PREFIX_PATH=%CGAL_PATH%\auxiliary\gmp;%BOOST_INSTALL_DIR% -DCGAL_Boost_USE_STATIC_LIBS:BOOL=ON -DZLIB_LIBRARY=%RDPARTY_INSTALL_DIR%\lib\zlib.lib -DZLIB_INCLUDE_DIR=%RDPARTY_INSTALL_DIR%\include'"
		CALL "%CMAKE_EXE%" "%CGAL_PATH%" ^
			-G "%GENERATOR%" ^
			-DCMAKE_BUILD_TYPE="Release" ^
			-DCMAKE_INSTALL_PREFIX:PATH="%CGAL_INSTALL_DIR%" ^
			-DCMAKE_PREFIX_PATH="%CGAL_PATH%\auxiliary\gmp;%BOOST_INSTALL_DIR%" ^
			-DCGAL_Boost_USE_STATIC_LIBS:BOOL=ON ^
			-DZLIB_LIBRARY="%RDPARTY_INSTALL_DIR%\lib\zlib.lib" ^
			-DZLIB_INCLUDE_DIR="%RDPARTY_INSTALL_DIR%\include"
	)
	IF %COMPILE% EQU 1 (
		CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL
	)
)
cd "%PWD%"
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:osg
@echo ##############################
@echo ###########  OSG  ############
@echo ##############################

cd %PWD%
@if %OSGREPO% EQU 1 goto DO_OSG_REPO2
@REM Use a binary install, from simpits archive.zip
set "OSG_ZIP=osg.zip"
IF NOT exist %OSG_ZIP% (
    echo Downloading %OSG_REPO%...
    CALL "%CURL_EXE%" %CURL_OPTS% %OSG_ZIP% %OSG_REPO%
    @if ERRORLEVEL 1 goto NOOSG1
) else (
    echo Found %OSG_ZIP%
)
@goto GOT_OSG_ZIP
:NOOSG1
@if EXIST %OSG_ZIP% @del %OSG_ZIP%
@echo.
@echo CMD FAILED: 'CALL "%CURL_EXE%" %CURL_OPTS% %OSG_ZIP% %OSG_REPO%'
@echo ERROR: %OSG_ZIP% is missing: download FAILED
@goto the_end
:GOT_OSG_ZIP

IF NOT exist %OSG_ZIP% (
    echo ERROR: %OSG_ZIP% is missing: download failed
    GOTO the_end
)

@REM OSG Source and destination
@REM Like - install\archive\install\msvc100-64\OpenSceneGraph
@set _OSG_SRC=install\archive\install\%OSG_DIR%\OpenSceneGraph
@REM "OSG_INSTALL_DIR=%INSTALL_DIR%\OpenSceneGraph"
IF NOT exist "%OSG_INSTALL_DIR%" (
    @if NOT EXIST %_OSG_SRC%\nul (
        @ECHO Doing: CALL "%UNZIP_EXE%" %OSG_ZIP% -d "%INSTALL_DIR%"
        @CALL "%UNZIP_EXE%" %OSG_ZIP% -d "%INSTALL_DIR%"
        @if ERRORLEVEL 1 goto OSGERR1
    )
    @if NOT EXIST %_OSG_SRC%\nul goto OSGERR2
    @REM Need to copy/move them to the right places
    @echo Setting up "%OSG_INSTALL_DIR%" from "%_OSG_SRC%"
    @xcopy %_OSG_SRC%\* "%OSG_INSTALL_DIR%" /s /e /i /Y /q
    @echo WIP, thinking... do I need to do more... maybe clean up... choose a tmp location...
    @REM goto the_end
    @goto DN_OSG_ZIP
:OSGERR1
    @echo.
    @echo Error: Unzip of OSG zip %OSG_ZIP% showed error!
    @echo Is this the right zip from Jenkins???
    @echo.
    @goto the_end
:OSGERR2
    @echo.
    @echo Error: OSG zip %OSG_ZIP% did not create %CD%\install\archive\install\%OSG_DIR%!
    @echo Is this the right zip from Jenkins???
    @echo.
    @goto the_end
) else (
    @ECHO Found "%OSG_INSTALL_DIR%"
)
@goto DN_OSG_ZIP

:DO_OSG_REPO2
@REM Handle OSG through a repo clone and build
@set OSG_REPO=%OSG_REPO2%
@IF exist "%PWD%"\OpenSceneGraph (
    @REM No update needed for a release branch
    @REM CALL :_gitUpdate OpenSceneGraph
  	@echo Done: '@CALL %GIT_EXE% clone -b %OSG_BRANCH% --single-branch %OSG_REPO%' 
    @echo Delete 'OpenSceneGraph' folder to do a fresh clone...
) ELSE (
    @echo Cloning "%OSG_REPO%"...
	@REM CALL %GIT_EXE% clone -- %OSG_REPO% - what is this '--'???
	@echo Doing: '@CALL %GIT_EXE% clone -b %OSG_BRANCH% --single-branch %OSG_REPO%' %BLDLOG%
	@CALL %GIT_EXE% clone -b %OSG_BRANCH% --single-branch %OSG_REPO% %BLDLOG%
	@REM CALL %GIT_EXE% checkout %OSG_BRANCH%
)
@cd %PWD%
@if NOT exist build\nul (mkdir build)
@cd build
@IF NOT exist OpenSceneGraph (mkdir OpenSceneGraph)
@cd OpenSceneGraph
@echo In OSG build directory %CD%
@set TMPOPTS=-G "%GENERATOR%" -DOSG_USE_QT:BOOL=OFF -DBUILD_OSG_APPLICATIONS:BOOL=ON ^
-DOSG_PLUGIN_SEARCH_INSTALL_DIR_FOR_PLUGINS:BOOL=OFF ^
-DCMAKE_LIBRARY_PATH:STRING="%RDPARTY_INSTALL_DIR%\lib" ^
-DCMAKE_INCLUDE_PATH:STRING="%RDPARTY_INSTALL_DIR%\include";"%RDPARTY_INSTALL_DIR%\include\freetype" ^
-DGDAL_LIBRARY:FILEPATH="%RDPARTY_INSTALL_DIR%\lib\gdal_i.lib" ^
-DCMAKE_INSTALL_PREFIX:PATH="%OSG_INSTALL_DIR%"
@IF %CMAKE% EQU 1 (
    @IF %HAVELOG% EQU 1 (
        @ECHO Doing: 'CALL "%CMAKE_EXE%" ..\..\OpenSceneGraph %TMPOPTS%' out to %LOGFIL%
    ) else (
        @ECHO Doing cmake configuration, generation for OSG...
    )
    @if EXIST CMakeCache.txt (
        @REM @DEL CMakeCache.txt 2>nul
    )
	@CALL "%CMAKE_EXE%" ..\..\OpenSceneGraph %TMPOPTS% %BLDLOG%
	@if ERRORLEVEL 1 (
	    @ECHO cmake configuration, generation for OSG FAILED!
        @goto ISERR
	)
	@echo Done cmake configuration, generation for OSG...
)
	
@IF %HAVELOG% EQU 1 (
    @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config Release --target INSTALL' output to %LOGFIL%
)
@CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
    @ECHO Compile of OSG failed! See %LOGFIL%
    @goto ISERR
)

:DN_OSG_ZIP

cd "%PWD%"
echo Done OSG Install, hopefully...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

@REM IF EXIST build_3rdParty2.x64.bat (
@REM CALL build_3rdParty2.x64
@REM )

:simgear
@echo ##############################
@echo #########  SIMGEAR  ##########
@echo ##############################
@IF %HAVELOG% EQU 1 (
@echo ############################## %BLDLOG%
@echo #########  SIMGEAR  ########## %BLDLOG%
@echo ############################## %BLDLOG%
)
IF exist "%PWD%"\simgear (
	CALL :_gitUpdate simgear
) ELSE (
    echo Cloning "%SG_REPO%"...
    REM CALL %GIT_EXE% clone -- %SG_REPO% - what is this '--'???
    echo Doing: CALL %GIT_EXE% clone %SG_REPO%
    CALL %GIT_EXE% clone %SG_REPO%
)

cd "%PWD%"\build
IF NOT exist simgear (mkdir simgear)
cd simgear
@REM	-DCMAKE_BUILD_TYPE="Release"
@echo In simgear build directory %CD%
@set OSG_ROOT=%OSG_INSTALL_DIR%
@echo Added ENV OSG_ROOT=%OSG_ROOT% %BLDLOG%
@REM ##################################################################
@REM Setup the important SimGear options
@set TMPOPTS=-G "%GENERATOR%" -DENABLE_TESTS=OFF ^
-DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO" -DMSVC_3RDPARTY_ROOT="%RDPARTY_INSTALL_DIR%" ^
-DBOOST_ROOT="%BOOST_INSTALL_DIR%" ^
-DCMAKE_PREFIX_PATH:PATH="%BOOST_INSTALL_DIR%;%OSG_INSTALL_DIR%;%RDPARTY_INSTALL_DIR%" ^
-DCMAKE_INSTALL_PREFIX:PATH="%SIMGEAR_INSTALL_DIR%"
@REM echo %TMPOPTS%
IF %CMAKE% EQU 1 (
    @IF %HAVELOG% EQU 1 (
        @echo Doing: 'CALL "%CMAKE_EXE%" ..\..\simgear %TMPOPTS%' out to %LOGFIL%
    ) else (
        @echo Doing cmake configuration, generation for simgear...
    )
	@IF EXIST CMakeCache.txt @DEL CMakeCache.txt 2>nul
	CALL "%CMAKE_EXE%" ..\..\simgear %TMPOPTS% %BLDLOG%
    @if ERRORLEVEL 1 (
        @echo cmake configuration, generation for simgear FAILED!
        @exit /b 1
    )
    @echo Done cmake configuration, generation for simgear...
)
IF %COMPILE% EQU 1 (
    @REM Do the COMPILE - Debug AND Release
    @IF %DEBUGBLD% EQU 1 (
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config Debug' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Debug %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Compile of DEBUG simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config RelWithDebInfo' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config RelWithDebInfo %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Compile of RelWithDebInfo simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    ) ELSE (
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config Release' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Release %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Compile of simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    )
    @REM Do the INSTALL
    @REM Install RelWithDebInfo
    @IF %DEBUGBLD% EQU 1 (
        @REM Install Debug
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config Debug --target INSTALL' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Debug --target INSTALL %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Install of simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config RelWithDebInfo --target INSTALL' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config RelWithDebInfo --target INSTALL %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Install of RelWithDebInfo simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    ) ELSE (
        @REM Install Release
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL %CMAKE_EXE%" --build . --config Release --target INSTALL' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo Install of simgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    )
)

cd "%PWD%"
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:flightgear
@echo ##############################
@echo ########  FLIGHTGEAR  ########
@echo ##############################
@IF %HAVELOG% EQU 1 (
@echo ############################## %BLDLOG%
@echo ########  FLIGHTGEAR  ######## %BLDLOG%
@echo ############################## %BLDLOG%
)

IF exist "%PWD%"\flightgear (
	CALL :_gitUpdate flightgear
) ELSE ( 
    echo Cloning %FG_REPO%...
    CALL %GIT_EXE% clone %FG_REPO%
)

cd "%PWD%"\build
IF NOT exist flightgear (mkdir flightgear)
cd flightgear
@echo In flightgear build directory %CD%
@REM		-DCMAKE_BUILD_TYPE="Release"
@REM Wow, this FAILED to find dxguid.lib
@REM if _MSVS GTR 10 goto DN_DXSDK
@REM set LIB=%DXSDK_DIR%Lib\x64;%LIB%
@REM set PATH=%DXSDK_DIR%Lib\x64;%PATH%
@REM echo Add extra LIB PATH '%DXSDK_DIR%Lib\x64'
@REM :DN_DXSDK
@set TMPOPTS=-G "%GENERATOR%" -DWITH_FGPANEL=OFF -DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO" ^
-DMSVC_3RDPARTY_ROOT="%RDPARTY_INSTALL_DIR%" -DBOOST_ROOT="%BOOST_INSTALL_DIR%" ^
-DCMAKE_PREFIX_PATH="%BOOST_INSTALL_DIR%;%OSG_INSTALL_DIR%;%SIMGEAR_INSTALL_DIR%;%RDPARTY_INSTALL_DIR%" ^
-DCMAKE_INSTALL_PREFIX:PATH="%FLIGHTGEAR_INSTALL_DIR%"
IF %CMAKE% EQU 1 (
    @IF %HAVELOG% EQU 1 (
        @ECHO Doing: 'CALL "%CMAKE_EXE%" ..\..\flightgear %TMPOPTS%' output to %LOGFIL% 
    ) else (
        @echo Doing cmake configuration, generation for flightgear...
    )
	DEL CMakeCache.txt 2>nul
	CALL "%CMAKE_EXE%" ..\..\flightgear %TMPOPTS% %BLDLOG%
    @if ERRORLEVEL 1 (
        @echo cmake configuration, generation FAILED!
        @exit /b 1
    )
    @echo Done cmake configuration, generation for flightgear...
)
IF %COMPILE% EQU 1 ( 
    @IF %DEBUGBLD% EQU 1 (
        @REM Compile the Debug
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL "%CMAKE_EXE%" --build . --config Debug' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Debug %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo build of Debug flightgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
        @REM Compile and Install RelWithDebInfo
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL "%CMAKE_EXE%" --build . --config RelWithDebInfo --target INSTALL' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config RelWithDebInfo --target INSTALL %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo build and install of RelWithDebInfo flightgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    ) ELSE (
        @REM Compile and Install Release
        @IF %HAVELOG% EQU 1 (
            @ECHO Doing: 'CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL' output to %LOGFIL% 
        )
        CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL %BLDLOG%
        @IF %HAVELOG% EQU 1 (
            if ERRORLEVEL 1 (
                @echo build and install of Release flightgear FAILED! See %LOGFIL%
                @exit /b 1
            )
        )
    )
)

cd "%PWD%"

xcopy "%OSG_INSTALL_DIR%"\bin\*.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\zlib.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\libpng16.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\OpenAL32.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\CrashRpt1402.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\CrashSender1402.exe "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\crashrpt_lang.ini "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\libcurl.dll "%FLIGHTGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q

REM create an enhanced run_fgfs.bat
echo @echo off > run_fgfs.bat
echo setlocal >> run_fgfs.bat
echo set TMPEXE=%FLIGHTGEAR_INSTALL_DIR%\bin\fgfs.exe >> run_fgfs.bat
echo if NOT EXIST %%TMPEXE%% ( >> run_fgfs.bat
echo echo Error: Can NOT locate %%TMPEXE%%! *** FIX ME *** >> run_fgfs.bat
echo exit /b 1 >> run_fgfs.bat
echo ) >> run_fgfs.bat
echo set TMPRT=%FLIGHTGEAR_INSTALL_DIR%\fgdata >> run_fgfs.bat
echo if NOT EXIST %%TMPRT%% ( >> run_fgfs.bat
echo echo Error: Can NOT locate %%TMPRT%%! *** FIX ME *** >> run_fgfs.bat
echo exit /b 1 >> run_fgfs.bat
echo ) >> run_fgfs.bat
echo set TMPCMD= >> run_fgfs.bat
echo :RPT >> run_fgfs.bat
echo if "%%~1x" == "x" goto GOTCMD >> run_fgfs.bat
echo set TMPCMD=%%TMPCMD%% %%1 >> run_fgfs.bat 
echo shift >> run_fgfs.bat
echo goto RPT >> run_fgfs.bat
echo :GOTCMD >> run_fgfs.bat 
echo for /F "eol=# tokens=*" %%%%G in (fgfsrc) do CALL :concat "%%%%G" >> run_fgfs.bat
echo cd %FLIGHTGEAR_INSTALL_DIR%\bin >> run_fgfs.bat
echo echo in %%CD%% running: fgfs.exe --fg-root=%%TMPRT%% %%ARGUMENTS%% %%TMPCMD%% >> run_fgfs.bat
echo fgfs.exe --fg-root=%%TMPRT%% %%ARGUMENTS%% %%TMPCMD%% >> run_fgfs.bat
echo goto :eof >> run_fgfs.bat
echo :concat >> run_fgfs.bat
echo set "ARGUMENTS=%%ARGUMENTS%% %%~1" >> run_fgfs.bat
echo goto :eof >> run_fgfs.bat
echo REM eof >> run_fgfs.bat

IF NOT exist fgfsrc ( 
	echo # Write one argument per line then run "run_fgfs.bat" > fgfsrc
	echo --console >> fgfsrc
)

echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:terragear
echo ##############################
echo ########  TERRAGEAR  #########
echo ##############################

IF exist "%PWD%"\terragear (
	CALL :_gitUpdate terragear
) ELSE (
    echo Cloning "%TG_REPO%"...
    CALL %GIT_EXE% clone "%TG_REPO%"
    @if ERRORLEVEL 1 (
        @set /A HAD_ERROR+=1
        @echo 'CALL %GIT_EXE% clone "%TG_REPO%"' FAILED!
        goto done_terra
    )
)

@cd "%PWD%"\terragear
@if ERRORLEVEL 1 (
    @set /A HAD_ERROR+=1
    @echo 'cd "%PWD%"\terragear' FAILED!
    goto done_terra
)

@CALL %GIT_EXE% checkout "%TG_BRANCH%"
@if ERRORLEVEL 1 (
    @set /A HAD_ERROR+=1
    @echo 'CALL %GIT_EXE% checkout "%TG_BRANCH%"' FAILED!
    goto done_terra
)

@cd "%PWD%"\build
@if ERRORLEVEL 1 (
    @set /A HAD_ERROR+=1
    @echo 'cd "%PWD%"\build' FAILED!
    goto done_terra
)
IF NOT exist terragear (mkdir terragear)
@cd terragear
@if ERRORLEVEL 1 (
    @set /A HAD_ERROR+=1
    @echo 'cd terragear' FAILED!
    goto done_terra
)

IF %CMAKE% EQU 1 (
	@DEL CMakeCache.txt 2>nul
    @IF %HAVELOG% EQU 1 (
        @ECHO "Doing: 'CALL %CMAKE_EXE% ..\..\terragear -G %GENERATOR% -DCMAKE_BUILD_TYPE="Release" -DBOOST_ROOT=%BOOST_INSTALL_DIR% -DJPEG_LIBRARY=%RDPARTY_INSTALL_DIR%\lib\jpeg.lib -DCMAKE_INSTALL_PREFIX:PATH=%TERRAGEAR_INSTALL_DIR% -DCMAKE_PREFIX_PATH=%SIMGEAR_INSTALL_DIR%;%CGAL_INSTALL_DIR%;%BOOST_INSTALL_DIR%' output to %LOGFIL%" 
    )
	@ECHO "Doing: 'CALL %CMAKE_EXE% ..\..\terragear -G %GENERATOR% -DCMAKE_BUILD_TYPE="Release" -DBOOST_ROOT=%BOOST_INSTALL_DIR% -DJPEG_LIBRARY=%RDPARTY_INSTALL_DIR%\lib\jpeg.lib -DCMAKE_INSTALL_PREFIX:PATH=%TERRAGEAR_INSTALL_DIR% -DCMAKE_PREFIX_PATH=%SIMGEAR_INSTALL_DIR%;%CGAL_INSTALL_DIR%;%BOOST_INSTALL_DIR%'" %BLDLOG% 
	@CALL "%CMAKE_EXE%" ..\..\terragear ^
		-G "%GENERATOR%" ^
		-DCMAKE_BUILD_TYPE="Release" ^
		-DBOOST_ROOT="%BOOST_INSTALL_DIR%" ^
		-DJPEG_LIBRARY="%RDPARTY_INSTALL_DIR%\lib\jpeg.lib" ^
		-DCMAKE_INSTALL_PREFIX:PATH="%TERRAGEAR_INSTALL_DIR%" ^
		-DCMAKE_PREFIX_PATH="%SIMGEAR_INSTALL_DIR%;%CGAL_INSTALL_DIR%;%BOOST_INSTALL_DIR%" %BLDLOG%
    @if ERRORLEVEL 1 (
        @set /A HAD_ERROR+=1
        @echo 'cmake config/gen ...' FAILED!
        goto done_terra
    )
)
@IF %COMPILE% EQU 1 (
	@CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL %BLDLOG%
    @if ERRORLEVEL 1 (
        @set /A HAD_ERROR+=1
        @echo 'CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL' FAILED!
        goto done_terra
    )
)
@cd "%PWD%"

IF /i %RDPARTY_ARCH% EQU x64 (
	xcopy "%RDPARTY_INSTALL_DIR%"\bin\iconv_x64.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
	COPY "%TERRAGEAR_INSTALL_DIR%"\bin\iconv_x64.dll "%TERRAGEAR_INSTALL_DIR%"\bin\iconv.dll
) ELSE (
	xcopy "%RDPARTY_INSTALL_DIR%"\bin\iconv.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
)
IF EXIST "%RDPARTY_INSTALL_DIR%\bin\gdal200.dll" (
ECHO xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal200.dll" to "%TERRAGEAR_INSTALL_DIR%\bin\*"
xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal200.dll" "%TERRAGEAR_INSTALL_DIR%\bin\*" /s /e /i /Y /q
) ELSE (
    IF EXIST "%RDPARTY_INSTALL_DIR%\bin\gdal17.dll" (
ECHO xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal17.dll" "%TERRAGEAR_INSTALL_DIR%\bin\*"
xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal17.dll" "%TERRAGEAR_INSTALL_DIR%\bin\*" /s /e /i /Y /q
    ) ELSE (
        IF EXIST "%RDPARTY_INSTALL_DIR%\bin\gdal111.dll" (
ECHO xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal111.dll" "%TERRAGEAR_INSTALL_DIR%\bin\*"
xcopy "%RDPARTY_INSTALL_DIR%\bin\gdal111.dll" "%TERRAGEAR_INSTALL_DIR%\bin\*" /s /e /i /Y /q
        ) ELSE (
ECHO WARNING: No GDAL DLL found in "%RDPARTY_INSTALL_DIR%\bin"!
            IF %HAVELOG% EQU 1 (
                ECHO WARNING: No GDAL DLL found in "%RDPARTY_INSTALL_DIR%\bin"! %BLDLOG%
            )
        )
    )
)
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\xerces-c_2_8.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\libexpat.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\libpq.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\spatialite.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\proj.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\geos_c.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%RDPARTY_INSTALL_DIR%"\bin\libcurl.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@xcopy "%CGAL_PATH%"\auxiliary\gmp\lib\*.dll "%TERRAGEAR_INSTALL_DIR%"\bin\* /s /e /i /Y /q
@echo Done...
:done_terra

@cd "%PWD%"

@IF %BUILD_ALL% EQU 0 (
    @SHIFT
    @GOTO Parser
)

@REM test exit
@REM GOTO finished

:terrageargui
echo ##############################
echo ######  TERRAGEARGUI  ########
echo ##############################

IF exist "%PWD%"\terrageargui (
	CALL :_gitUpdate terrageargui
) ELSE (
    echo Cloning "%TGGUI_REPO%"...
    CALL %GIT_EXE% clone "%TGGUI_REPO%"
)

cd "%PWD%"\build
IF NOT exist terrageargui (mkdir terrageargui)
cd terrageargui
IF %CMAKE% EQU 1 (
	DEL CMakeCache.txt 2>nul
	CALL "%CMAKE_EXE%" ..\..\terrageargui ^
		-G "%GENERATOR%" ^
		-DCMAKE_BUILD_TYPE="Release" ^
		-DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO" ^
		-DCMAKE_INSTALL_PREFIX:PATH="%TGGUI_INSTALL_DIR%"
)
IF %COMPILE% EQU 1 (
	CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL
)
cd "%PWD%"
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:fgrun
echo ##############################
echo ########     FGRUN    ########
echo ##############################

IF exist "%PWD%"\fgrun (
	CALL :_gitUpdate fgrun
) ELSE ( 
    echo Cloning %FGRUN_REPO%...
    CALL %GIT_EXE% clone %FGRUN_REPO%
)

cd "%PWD%"\build
IF NOT exist fgrun (mkdir fgrun)
cd fgrun
IF %CMAKE% EQU 1 (
	DEL CMakeCache.txt 2>nul
	CALL "%CMAKE_EXE%" ..\..\fgrun ^
		-G "%GENERATOR%" ^
		-DCMAKE_BUILD_TYPE="Release" ^
		-DCMAKE_EXE_LINKER_FLAGS="/SAFESEH:NO" ^
		-DMSVC_3RDPARTY_ROOT="%RDPARTY_INSTALL_DIR%" ^
		-DBOOST_ROOT="%BOOST_INSTALL_DIR%" ^
		-DCMAKE_PREFIX_PATH="%BOOST_INSTALL_DIR%;%OSG_INSTALL_DIR%;%SIMGEAR_INSTALL_DIR%;%RDPARTY_INSTALL_DIR%" ^
		-DCMAKE_INSTALL_PREFIX:PATH="%FGRUN_INSTALL_DIR%"
)
IF %COMPILE% EQU 1 ( 
	CALL "%CMAKE_EXE%" --build . --config Release --target INSTALL
)
cd %PWD%
xcopy "%OSG_INSTALL_DIR%"\bin\*.dll "%FGRUN_INSTALL_DIR%"\bin\* /s /e /i /Y /q
xcopy "%RDPARTY_INSTALL_DIR%"\bin\libintl-8.dll "%FGRUN_INSTALL_DIR%"\bin\* /s /e /i /Y /q

echo @echo off > run_fgrun.bat
echo start /d "%FGRUN_INSTALL_DIR%\bin" fgrun.exe >> run_fgrun.bat
echo Done...

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
) else (
	GOTO finished
)

:fgdata
@echo ##############################
@echo ##########  FGDATA  ##########
@echo ##############################
@REM IF "%FG_ROOT%x" == "x" goto DO_FGDATA
@REM echo.
@REM echo Have a FG_ROOT=%FG_ROOT% - Assume this has been MANUALLY UPDATED
@REM GOTO DN_FGDATA
:DO_FGDATA
IF exist %FGDATA_INSTALL_DIR%\nul (
    @echo Updating install/flightgear/fgdata...
	CALL :_gitUpdate install/flightgear/fgdata
) ELSE (
    echo Cloning %FGDATA_REPO%...
    cd "%FLIGHTGEAR_INSTALL_DIR%"
    CALL %GIT_EXE% clone %FGDATA_REPO% fgdata
)
:DN_FGDATA

IF %BUILD_ALL% EQU 0 (
    SHIFT
    GOTO Parser
)

:finished
IF %HAVELOG% EQU 1 (
    ECHO "See output in %LOGFIL%" 
)
@if %HAD_ERROR% GTR 0 goto HAD_ERRORS
echo #########  F         #########
echo #########   I        #########
echo #########    N       #########
echo #########     I      #########
echo #########      S     #########
echo #########       H    #########
echo #########        E   #########
echo #########         D  #########
:the_end
exit /b 0

@REM ########### ERROR EXISTS ##########
:HAD_ERRORS
@echo Finished with errors %HAD_ERRORS%
@goto ISERR

:NO_MSVC_SEL
@set /A HAD_ERROR+=1
@echo.
@echo Error: Can NOT locate %TMP_MSVC% to setup MSVC environment
@goto ISERR

:ISERR
@endlocal
@exit /b 1

@REM ###########################################################################
@REM give help...
:Usage
echo Usage: 
echo    $0 [ [/P] [/M] [/C] [/D] [/O] [3rdparty] [boost] [osg] [simgear] [flightgear] [fgrun] [fgdata] [terragear] [terrageargui] ]
echo    Options:
echo       /C  : Do not compile
echo       /M  : Do not run cmake
echo       /P  : Do not run git pull
echo       /D  : Also compile Debug configuration
echo       /O  : Use OSG clone. Default uses Jenkin's simpits archive.zip
echo.
echo    Don't forget to edit the top of the script in accordance with your system
exit /b 0

REM ###########################    HELPER FUNCTION    ####################################
:_gitUpdate
    @IF %PULL% EQU 1 (
		@echo Pulling %1...
		@cd "%PWD%"\%1
		@CALL %GIT_EXE% stash save
		REM CALL %GIT_EXE% pull -r - what is this -r???
		@CALL %GIT_EXE% pull
		@CALL %GIT_EXE% stash pop
		@cd "%PWD%"
	) else (
        @echo No update pull configured
    )
@GOTO :EOF

@REM eof

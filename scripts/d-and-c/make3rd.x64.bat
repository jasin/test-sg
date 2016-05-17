@setlocal
@REM ================================================================================
@REM Build 3rdParty components prior to building flightgear
@REM ================================================================================
@REM ################################################################################
@REM 20160513 - v1.0.5 - Use external _selectMSVC.x64 to set some variables for us
@REM 20160511 - v1.0.4 - Add PLIB build, and install, through special PLIB-1.8.5.zip with a CMakeLists.txt
@REM 20160510 - v1.0.3 - Add OpenAL build, and install, through openal-build.bat
@REM 20160509 - v1.0.2 - Massive updates build3rd.x64.bat, including doing Boost
@REM 20140811 - v1.0.1 - Renamed build3rd.x64.bat
@REM ################################################################################
@REM started with from : http://wiki.flightgear.org/Howto:Build_3rdParty_library_for_Windows
@REM ################################################################################
@set TMP_MSVC=_selectMSVC.x64.bat
@set "WORKSPACE=%CD%"
@if EXIST ..\..\.git\nul goto NOT_IN_SRC
@if NOT EXIST %TMP_MSVC% goto NO_MSVC_SEL 
@set TMPDN3RD=make3rd.x64.txt
@if EXIST %TMPDN3RD% (
@echo.
@type %TMPDN3RD%
@echo File %TMPDN3RD% already exists, so this has been run before...
@echo Delete this file to run this batch again
@echo.
@goto EXIT
)
@set HAD_ERROR=0

@REM Switch MSVC Version
@set _MSVS=0
@set _MSNUM=0
@set VS_BAT=
@set GENERATOR=
@call %TMP_MSVC%
@if "%GENERATOR%x" == "x" (
@set /A HAD_ERROR+=1
@echo.
@echo No GENERATOR set! %TMP_MSVC% FAILED! **FIX ME**
@echo.
@goto EXIT
)
@if "%VS_BAT%x" == "x" (
@set /A HAD_ERROR+=1
@echo.
@echo No ENV VS_BAT SET_BAT set! %TMP_MSVC% FAILED! **FIX ME**
@echo.
@goto EXIT
)

@REM MSVC has been setup, do NOT call this a 2nd time
@set VS_BAT=

@set GET_EXE=wget
@set GET_OPT=-O
@set UZ_EXE=7z
@set UZ_OPT=x
@set MOV_CMD=move
@set MOV_OPT=

@set TMP3RD=3rdParty.x64
@set PERL_FIL=%WORKSPACE%\rep32w64.pl
@set LOGFIL=%WORKSPACE%\bldlog-2.txt
@set BLDLOG=
@REM Uncomment this, and add to config/build line, if you can output to a LOG
@set BLDLOG= ^>^> %LOGFIL% 2^>^&1
@set ERRLOG=%WORKSPACE%\error-2.txt
@set ADD_GDAL=0
@set HAVELOG=1

@REM call setupqt64

@echo %0: Begin %DATE% %TIME% in %CD% > %LOGFIL%
@echo # Error log %DATE% %TIME% > %ERRLOG%

@REM #############################################################################
@REM #############################################################################
@REM #### CGAL SETUP - THIS MAY NEED TO BE CHANGED TO WHERE YOU INSTALL CGAL #####
@REM #############################################################################
@REM #### DO NOT USE PATH NAMES WITH SPACES - USE DIR /X TO GET SHORT DIR    #####
@REM #############################################################################
@if "%CGAL_DIR%x" == "x" (
@REM 20160509 - Update to CGAL-4.8
@set CGAL_PATH=D:\FG\CGAL-4.8
@REM set CGAL_PATH=C:\PROGRA~2\CGAL-4.1
) else (
@set "CGAL_PATH=%CGAL_DIR%"
)

@set "GMP_HDR=%CGAL_PATH%\auxiliary\gmp\include\gmp.h"
@set "GMP_DLL=%CGAL_PATH%\auxiliary\gmp\lib\libgmp-10.dll"
@set "GMP_LIB=%CGAL_PATH%\auxiliary\gmp\lib\libgmp-10.lib"
@if NOT EXIST %CGAL_PATH%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Can NOT locate %CGAL_PATH%! *** FIX ME ***
@echo %HAD_ERROR%: Can NOT locate %CGAL_PATH%! *** FIX ME *** >> %ERRLOG%
)
@if NOT EXIST %GMP_DLL% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Can NOT locate %GMP_DLL%! *** FIX ME ***
@echo %HAD_ERROR%: Can NOT locate %GMP_DLL%! *** FIX ME *** >> %ERRLOG%
)
@if NOT EXIST %GMP_LIB% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Can NOT locate %GMP_LIB%! *** FIX ME ***
@echo %HAD_ERROR%: Can NOT locate %GMP_LIB%! *** FIX ME *** >> %ERRLOG%
)

@if NOT %HAD_ERROR% EQU 0 goto END

@REM ######################################################################
@REM ######################################################################
@REM ########### SHOULD NOT NEED TO ALTER ANYTHING BELOW HERE ############# 
@REM ######################################################################

@if NOT EXIST  %WORKSPACE%\%TMP3RD%\nul (
md %WORKSPACE%\%TMP3RD%
)
@if NOT EXIST %WORKSPACE%\%TMP3RD%\bin\nul (
md %WORKSPACE%\%TMP3RD%\bin
)
@if NOT EXIST %WORKSPACE%\%TMP3RD%\lib\nul (
md %WORKSPACE%\%TMP3RD%\lib
)
@if NOT EXIST %WORKSPACE%\%TMP3RD%\include\nul (
md %WORKSPACE%\%TMP3RD%\include
)

@REM Already done... do not repeat... anyway should be VS_BAT BUILD_BITS
@REM CALL %SET_BAT% amd64

@REM TEST JUMP
@REM GOTO DO_CGAL
@REM GOTO DO_GDAL 
@REM GOTO DO_BOOST
@REM GOTO DO_JPEG
@REM GOTO DO_AL
@set _TMP_LIBS=

:DO_ZLIB
@set _TMP_LIBS=%_TMP_LIBS% ZLIB
@echo %0: ############################# Download ^& compile ZLIB %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile ZLIB
)

@set TMP_URL=http://zlib.net/zlib128.zip
@set TMP_ZIP=zlib.zip
@set TMP_SRC=zlib-source
@set TMP_DIR=zlib-1.2.8
@set TMP_BLD=zlib-build

@if NOT EXIST zlib.zip ( 
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
@REM Seems NEED a delay after the UNZIP, else get access denied on the renaming???
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_ZLIB
)

cd %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
md %TMP_BLD%
)

CD %TMP_BLD%

ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\zlib-build\build" %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\zlib-build\build"
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\zlib-build\build" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit config/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit config/gen %TMP_SRC% >> %ERRLOG%
)

ECHO Doing 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'cmake --build . --config Release --target INSTALL'
)
cmake --build . --config Release --target INSTALL
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)
 
xcopy %WORKSPACE%\zlib-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\zlib-build\build\lib\zlib.lib %WORKSPACE%\%TMP3RD%\lib /y /q
xcopy %WORKSPACE%\zlib-build\build\bin\zlib.dll %WORKSPACE%\%TMP3RD%\bin /y /q

:DN_ZLIB
cd %WORKSPACE%

:DO_TIFF
@set _TMP_LIBS=%_TMP_LIBS% TIFF
@echo %0: ############################# Download ^& compile LIBTIFF %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBTIFF to %LOGFIL%
)

@set TMP_URL=http://download.osgeo.org/libtiff/tiff-4.0.3.zip
@set TMP_ZIP=libtiff.zip
@set TMP_SRC=libtiff-source
@set TMP_DIR=tiff-4.0.3

@if NOT EXIST %TMP_ZIP% ( 
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_TIFF
)

cd %TMP_SRC%
ECHO Doing: 'nmake -f makefile.vc' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'nmake -f makefile.vc'
)
nmake -f makefile.vc
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

cd %WORKSPACE%

xcopy %WORKSPACE%\libtiff-source\libtiff\libtiff.lib %WORKSPACE%\%TMP3RD%\lib\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\libtiff_i.lib %WORKSPACE%\%TMP3RD%\lib\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\libtiff.dll %WORKSPACE%\%TMP3RD%\bin\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\tiff.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\tiffconf.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\tiffio.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libtiff-source\libtiff\tiffvers.h %WORKSPACE%\%TMP3RD%\include\ /y /f

:DN_TIFF
cd %WORKSPACE%

:DO_PNG
@set _TMP_LIBS=%_TMP_LIBS% PNG
@echo %0: ############################# Download ^& compile LIBPNG %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBPNG to %LOGFIL%
)

@set TMP_URL=http://download.sourceforge.net/libpng/lpng1610.zip
@set TMP_ZIP=libpng.zip
@set TMP_SRC=libpng-source
@set TMP_DIR=lpng1610
@set TMP_BLD=libpng-build

@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_PNG
)

cd %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
MD %TMP_BLD%
)

CD %TMP_BLD%
ECHO Doing 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libpng-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libpng-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' to %LOGFIL%
)

cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libpng-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake config/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake config/gen %TMP_SRC% >> %ERRLOG%
)
ECHO Doing 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)

cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

xcopy %WORKSPACE%\libpng-build\build\include\*.h %WORKSPACE%\%TMP3RD%\include /y
xcopy %WORKSPACE%\libpng-build\build\lib\libpng16.lib %WORKSPACE%\%TMP3RD%\lib /y
xcopy %WORKSPACE%\libpng-build\build\bin\libpng16.dll %WORKSPACE%\%TMP3RD%\bin /y

:DN_PNG
cd %WORKSPACE%
:DO_JPEG
@set _TMP_LIBS=%_TMP_LIBS% JPEG
@echo %0: ############################# Download ^& compile LIBJPEG %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBJPEG to %LOGFIL%
)

@set TMP_URL=http://www.ijg.org/files/jpegsr9a.zip
@set TMP_ZIP=libjpeg.zip
@set TMP_SRC=libjpeg-source
@set TMP_DIR=jpeg-9a

@REM ### setup a perl script
@if EXIST %PERL_FIL% goto DN_PFIL
@echo Creating %PERL_FIL%...
@echo #!/usr/bin/perl -w >%PERL_FIL%
@echo # rep32w64.pl >>%PERL_FIL%
@echo. >>%PERL_FIL%
@echo if (@ARGV) { >>%PERL_FIL%
@echo   my $file = $ARGV[0]; >>%PERL_FIL%
@echo   if (open(INF,"<$file")) { >>%PERL_FIL%
@echo     my @lines = ^<INF^>; >>%PERL_FIL%
@echo     close INF; >>%PERL_FIL%
@echo     my ($line,$lncnt,$i); >>%PERL_FIL%
@echo     $lncnt = scalar @lines; >>%PERL_FIL%
@echo     for ($i = 0; $i ^< $lncnt; $i++) { >>%PERL_FIL%
@echo 	      $line = $lines[$i]; >>%PERL_FIL%
@echo         $line =~ s/Win32/x64/g; >>%PERL_FIL%
@echo         $lines[$i] = $line; >>%PERL_FIL%
@echo     } >>%PERL_FIL%
@echo     if (open WOF, ">$file") { >>%PERL_FIL%
@echo 	    print WOF join("",@lines)."\n"; >>%PERL_FIL%
@echo 	    close WOF; >>%PERL_FIL%
@echo       exit(0); >>%PERL_FIL%
@echo     } >>%PERL_FIL%
@echo   } >>%PERL_FIL%
@echo } >>%PERL_FIL%
@echo exit(1); >>%PERL_FIL%
@echo # eof >>%PERL_FIL%
:DN_PFIL

@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to FETCH from %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed to FETCH from %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_JPEG
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)
 
@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to setup %TMP_SRC%!
@echo %HAD_ERROR%: Failed to setup %TMP_SRC%! >> %ERRLOG%
@goto DN_JPEG
)

CD %TMP_SRC%

@IF NOT EXIST jconfig.h (
@echo Doing 'nmake -f makefile.vc setup-v10'
nmake -f makefile.vc setup-v10
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit makefile.vc %TMP_SRC%
@echo %HAD_ERROR%: Error exit makefile.vc %TMP_SRC% >> %ERRLOG%
)
)
@REM sed -i "s/Win32/x64/g" jpeg.sln
@REM sed -i "s/Win32/x64/g" jpeg.vcxproj
perl -f %PERL_FIL% jpeg.sln
perl -f %PERL_FIL% jpeg.vcxproj
ECHO Doing 'msbuild jpeg.sln /t:Build /p:Configuration=Release;Platform=x64' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'msbuild jpeg.sln /t:Build /p:Configuration=Release;Platform=x64' to %LOGFIL%
)
msbuild jpeg.sln /t:Build /p:Configuration=Release;Platform=x64 %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit msbuild source %TMP_SRC%
@echo %HAD_ERROR%: Error exit msbuild source %TMP_SRC% >> %ERRLOG%
)

@echo Installing the jpeg built components...
xcopy %WORKSPACE%\libjpeg-source\x64\Release\jpeg.lib %WORKSPACE%\%TMP3RD%\lib /y /s /q
xcopy %WORKSPACE%\libjpeg-source\jconfig.h %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libjpeg-source\jerror.h %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libjpeg-source\jmorecfg.h %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libjpeg-source\jpeglib.h %WORKSPACE%\%TMP3RD%\include /y /s /q

:DN_JPEG
cd %WORKSPACE%

:DO_CURL
@set _TMP_LIBS=%_TMP_LIBS% CURL
@echo %0: ############################# Download ^& compile LIBCURL %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBCURL to %LOGFIL%
)
@set TMP_URL=http://curl.haxx.se/download/curl-7.35.0.zip
@set TMP_ZIP=libcurl.zip
@set TMP_SRC=libcurl-source
@set TMP_DIR=curl-7.35.0
@set TMP_BLD=libcurl-build

@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error failed download from %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Error failed download from %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_CURL
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error failed set up of %TMP_SRC%
@echo %HAD_ERROR%: Error failed set up of %TMP_SRC% >> %ERRLOG%
@goto DN_CURL
) 

cd %WORKSPACE%

if NOT EXIST %TMP_BLD%\nul (
MD %TMP_BLD%
)

CD %TMP_BLD%
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libcurl-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libcurl-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' to %LOGFIL%
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libcurl-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC% >> %ERRLOG%
)
ECHO Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

cd %WORKSPACE%
 
xcopy %WORKSPACE%\libcurl-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libcurl-build\build\lib\libcurl_imp.lib %WORKSPACE%\%TMP3RD%\lib /y /q
xcopy %WORKSPACE%\libcurl-build\build\lib\libcurl.dll %WORKSPACE%\%TMP3RD%\bin /y /q
xcopy %WORKSPACE%\libcurl-build\build\bin\curl.exe %WORKSPACE%\%TMP3RD%\bin /y /q

:DN_CURL
cd %WORKSPACE%
:DO_GDAL 
@if %ADD_GDAL% EQU 0 goto DN_GDAL
@set _TMP_LIBS=%_TMP_LIBS% GDAL
 
@echo %0: ############################# Download ^& compile GDAL %CD% %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile GDAL %CD% to %LOGFIL%
)
@REM set TMP_URL=https://svn.osgeo.org/gdal/trunk/gdal
@REM This SVN source FAILED to link with CGAL
@set TMP_SRC=libgdal-source
@set TMP_URL=http://download.osgeo.org/gdal/1.11.0/gdal1110.zip
@set TMP_ZIP=libgdal.zip
@set TMP_DIR=gdal-1.11.0

@if NOT EXIST %TMP_ZIP% ( 
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_GDAL
)

CD %TMP_SRC%
ECHO Doing: 'nmake -f makefile.vc MSVC_VER=%_MSNUM% GDAL_HOME=%WORKSPACE%/libgdal-source BINDIR=%WORKSPACE%\%TMP3RD%\bin LIBDIR=%WORKSPACE%\%TMP3RD%\lib INCDIR=%WORKSPACE%\%TMP3RD%\include WIN64=YES' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'nmake -f makefile.vc MSVC_VER=%_MSNUM% GDAL_HOME=%WORKSPACE%/libgdal-source BINDIR=%WORKSPACE%\%TMP3RD%\bin LIBDIR=%WORKSPACE%\%TMP3RD%\lib INCDIR=%WORKSPACE%\%TMP3RD%\include WIN64=YES' to %LOGFIL%
)
nmake -f makefile.vc MSVC_VER=%_MSNUM% GDAL_HOME=%WORKSPACE%/libgdal-source BINDIR=%WORKSPACE%\%TMP3RD%\bin LIBDIR=%WORKSPACE%\%TMP3RD%\lib INCDIR=%WORKSPACE%\%TMP3RD%\include WIN64=YES %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit nmake building source %TMP_SRC% in %CD%
@echo %HAD_ERROR%: Error exit nmake building source %TMP_SRC% in %CD% >> %ERRLOG%
)

cd %WORKSPACE%
 
xcopy %WORKSPACE%\libgdal-source\gcore\gdal.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\gcore\gdal_frmts.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\gcore\gdal_proxy.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\gcore\gdal_priv.h %WORKSPACE%\%TMP3RD%\include\ /y /f 
xcopy %WORKSPACE%\libgdal-source\gcore\gdal_version.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\alg\gdal_alg.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\alg\gdalwarper.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\frmts\vrt\gdal_vrt.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\ogr\ogr*.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\ogr\ogrsf_frmts\ogrsf_frmts.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\port\cpl*.h %WORKSPACE%\%TMP3RD%\include\ /y /f
xcopy %WORKSPACE%\libgdal-source\gdal_i.lib %WORKSPACE%\%TMP3RD%\lib\ /y /f
xcopy %WORKSPACE%\libgdal-source\gdal.lib %WORKSPACE%\%TMP3RD%\lib\ /y /f
xcopy %WORKSPACE%\libgdal-source\gdal*.dll %WORKSPACE%\%TMP3RD%\bin\ /y /f

:DN_GDAL
cd %WORKSPACE%
@REM TEST EXIT
@REM GOTO END
:DO_FLTK
@set _TMP_LIBS=%_TMP_LIBS% FLTK
@echo %0: ############################# Download ^& compile LIBFLTK %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBFLTK to %LOGFIL%
)
@set TMP_URL=http://fltk.org/pub/fltk/1.3.2/fltk-1.3.2-source.tar.gz
@set TMP_ZIP=libfltk.tar.gz
@set TMP_TAR=libfltk.tar
@set TMP_SRC=libfltk-source
@set TMP_BLD=libfltk-build
@set TMP_DIR=fltk-1.3.2

@if NOT EXIST %TMP_TAR% (
@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_TAR% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to fetch %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed to fetch %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_FLTK
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_TAR%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_FLTK
)

cd %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
md %TMP_BLD%
)

cd %TMP_BLD%
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libfltk-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libfltk-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%"' to %LOGFIL%
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libfltk-build\build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%\%TMP3RD%" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC% >> %ERRLOG%
)

ECHO Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

cd %WORKSPACE%
 
xcopy %WORKSPACE%\libfltk-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libfltk-build\build\bin\* %WORKSPACE%\%TMP3RD%\bin /y /s /q
xcopy %WORKSPACE%\libfltk-build\build\lib\fltk*.lib %WORKSPACE%\%TMP3RD%\lib /y /s /q

:DN_FLTK
cd %WORKSPACE%

:DO_BOOST
@set _TMP_LIBS=%_TMP_LIBS% BOOST
@echo %0: ############################# Download ^& compile LIBBOOST %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBBOOST to %LOGFIL%
)
@REM check to see if we have a boost installation we can use. Checking %BOOST_ROOT%
@echo Checking for local installation of boost...
@if NOT "%BOOST_ROOT%"=="" GOTO DN_BOOST 
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

@echo Check fo existance of %TMP_ZIP%

@if NOT EXIST %TMP_ZIP% (
@echo Doing 'CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%'
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
@if ERRORLEVEL 1 goto NOBOOST
) else (
@echo Found simpits boost %TMP_ZIP%
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Download from %TMP_URL% to %TMP_ZIP% FAILED! >> %ERRLOG%
@echo %HAD_ERROR%: Download from %TMP_URL% to %TMP_ZIP% FAILED!
@GOTO NOBOOST
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
@GOTO NOBOOST
@REM goto DN_BOOST
)

CD %TMP_SRC%

@if NOT EXIST lib\nul (
@if EXIST lib64\nul (
@REN lib64 lib
)
)

@REM if NOT EXIST include\boost-1_55\nul (
@REM MD include\boost-1_55
@REM )

@REM @if EXIST boost (
@REM MOVE boost include\boost-1_55
@REM )

:DN_BOOST 
@echo %BOOST_ROOT%
cd %WORKSPACE%

:DO_CGAL
@set _TMP_LIBS=%_TMP_LIBS% CGAL
@call :SET_BOOST

@echo %0: ############################# Download ^& compile CGAL %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile CGAL to %LOGFIL%
)
@REM set TMP_URL=https://gforge.inria.fr/frs/download.php/32996/CGAL-4.3.zip
@REM set TMP_URL=https://gforge.inria.fr/frs/download.php/file/33527/CGAL-4.4.zip
@REM set TMP_URL=http://github.com/CGAL/cgal/releases/download/releases%2FCGAL-4.8/CGAL-4.8.zip
@set TMP_URL=http://geoffair.org/tmp/CGAL-4.8.zip
@set TMP_ZIP=libcgal.zip
@set TMP_SRC=libcgal-source
@set TMP_BLD=libcgal-build
@set TMP_DIR=CGAL-4.8
@set TMP_PRE=%WORKSPACE%\cgal-source\auxiliary\gmp;%WORKSPACE%\Boost;%WORKSPACE%\install\Boost;%WORKSPACE%\%TMP3RD%

@if NOT EXIST %TMP_ZIP% (
@echo Moment, doing 'CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%'
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
@if ERRORLEVEL 1 goto NOCGALZIP
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_CGAL
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
@if ERRORLEVEL 1 goto NOCGALUZ
@echo Done UNZIP: CALL '%UZ_EXE% %UZ_OPT% %TMP_ZIP%'
)
CALL :SLEEP1
)

@if NOT EXIST %TMP_SRC%\nul (
@if EXIST %TMP_DIR%\nul (
CALL :SLEEP1
@REN %TMP_DIR% %TMP_SRC%
@if ERRORLEVEL 1 goto NOCGALREN
)
)

@set _TMP_GMP=%WORKSPACE%\libcgal-source\auxiliary\gmp
@if EXIST %_TMP_GMP%\include\gmp.h (
@echo Could avoided update of GMP headers...
)
@xcopy "%CGAL_PATH%"\auxiliary\gmp\include\* %_TMP_GMP%\include /s /y /i
@xcopy "%CGAL_PATH%"\auxiliary\gmp\lib64\* %_TMP_GMP%\lib /s /y /i
@xcopy "%CGAL_PATH%"\auxiliary\gmp\lib\* %_TMP_GMP%\lib /s /y /i
 
CD %WORKSPACE%

@if NOT EXIST %TMP_SRC%\nul (
@echo Creation of %TMP_SRC% FAILED!
@goto ISERR
)

@if NOT EXIST %TMP_BLD%\nul (
@MD %TMP_BLD%
@if ERRORLEVEL 1 goto NOCGALBLD
)

CD %TMP_BLD%
@if ERRORLEVEL 1 goto NOCGALBLD

@if NOT EXIST ..\%TMP_SRC%\CMakeLists.txt goto NOCGALCMAKE

@if EXIST CMakeCache.txt (
@REM This ia a BIG search - do NOT repeat it every time...
@REM del CMakeCache.txt >nul
)

@REM -DZLIB_LIBRARY="%WORKSPACE%\%TMP3RD%\lib\zlib.lib" -DZLIB_INCLUDE_DIR="%WORKSPACE%\%TMP3RD%\include" 
@set TMP_OPS=-G "%GENERATOR%" -DCMAKE_PREFIX_PATH="%TMP_PRE%" -DCGAL_Boost_USE_STATIC_LIBS:BOOL=ON -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libcgal-build\build"

@ECHO Doing: 'cmake ..\%TMP_SRC% %TMP_OPS% %BLDLOG%
IF %HAVELOG% EQU 1 (
@ECHO Doing: 'cmake ..\%TMP_SRC% %TMP_OPS% to %LOGFIL%
)

@REM Make a build-me.bat
@ECHO @REM Just to be able to repeat the individual build >build-me.bat
@ECHO cmake ..\%TMP_SRC% %TMP_OPS% >>build-me.bat

cmake ..\%TMP_SRC% %TMP_OPS% %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Config/Gen FAILED %TMP_SRC%
@echo %HAD_ERROR%: Config/Gen FAILED %TMP_SRC% >> %ERRLOG%
@goto NOCGAL1
@REM goto DN_CGAL
)
ECHO Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
@ECHO cmake --build . --config Release --target INSTALL >>build-me.bat
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Build FAILED %TMP_SRC%
@echo %HAD_ERROR%: Build FAILED %TMP_SRC% >> %ERRLOG%
@goto NOCGAL2
@REM goto DN_CGAL
)
 
cd %WORKSPACE%

@echo Doing: xcopy %WORKSPACE%\libcgal-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\libcgal-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
@echo Doing: xcopy %WORKSPACE%\libcgal-build\build\bin\*.dll %WORKSPACE%\%TMP3RD%\bin /y /s /q
xcopy %WORKSPACE%\libcgal-build\build\bin\*.dll %WORKSPACE%\%TMP3RD%\bin /y /s /q
@echo Doing: xcopy %WORKSPACE%\libcgal-build\build\lib\*.lib %WORKSPACE%\%TMP3RD%\lib /y /s /q
xcopy %WORKSPACE%\libcgal-build\build\lib\*.lib %WORKSPACE%\%TMP3RD%\lib /y /s /q
@echo Doing: xcopy %WORKSPACE%\libcgal-source\auxiliary\gmp\lib\*.dll %WORKSPACE%\%TMP3RD%\bin /s /y /q
xcopy %WORKSPACE%\libcgal-source\auxiliary\gmp\lib\*.dll %WORKSPACE%\%TMP3RD%\bin /s /y /q
@echo Doing: xcopy %WORKSPACE%\libcgal-source\auxiliary\gmp\lib\*.lib %WORKSPACE%\%TMP3RD%\lib /s /y /q
xcopy %WORKSPACE%\libcgal-source\auxiliary\gmp\lib\*.lib %WORKSPACE%\%TMP3RD%\lib /s /y /q
 
:DN_CGAL
cd %WORKSPACE%
@REM TEST EXIT
@REM GOTO END

:DO_FREETYPE
@set _TMP_LIBS=%_TMP_LIBS% FREETYPE
@call :SET_BOOST
 
@echo %0: ############################# Download ^& compile FREETYPE %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile FREETYPE to %LOGFIL%
)

@set TMP_URL=http://sourceforge.net/projects/freetype/files/freetype2/2.5.3/ft253.zip/download
@set TMP_ZIP=freetype.zip
@set TMP_SRC=freetype-source
@set TMP_BLD=freetype-build
@set TMP_DIR=freetype-2.5.3

@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to download %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed to download %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_FREETYPE
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_FREETYPE
)

CD %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
MD %TMP_BLD%
)

CD %TMP_BLD%
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%/freetype-build/build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%/%TMP3RD%"' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%/freetype-build/build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%/%TMP3RD%"' to %LOGFIL%
) 
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%/freetype-build/build" -DCMAKE_PREFIX_PATH:PATH="%WORKSPACE%/%TMP3RD%"
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC% >> %ERRLOG%
)

ECHO Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

CD %WORKSPACE%
 
xcopy %WORKSPACE%\freetype-build\build\* %WORKSPACE%\%TMP3RD% /y /s /q

:DN_FREETYPE

cd %WORKSPACE%

:DO_PROJ
@set _TMP_LIBS=%_TMP_LIBS% Proj
@call :SET_BOOST
@echo %0: ############################# Download ^& compile LIBPROJ %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBPROJ to %LOGFIL%
)
@set TMP_URL=http://download.osgeo.org/proj/proj-4.8.0.zip
@set TMP_ZIP=libproj.zip
@set TMP_SRC=libproj-source
@set TMP_DIR=proj-4.8.0

@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
) 
@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed download %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed download %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_PROJ
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to setup %TMP_SRC%
@echo %HAD_ERROR%: Failed to setup %TMP_SRC% >> %ERRLOG%
@goto DN_PROJ
)

CD %TMP_SRC%
@echo Doing:  'nmake -f makefile.vc' %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo Doing:  'nmake -f makefile.vc' to %LOGFIL%
)
nmake -f makefile.vc %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit nmake makefile.vc %TMP_SRC%
@echo %HAD_ERROR%: Error exit nmake maekfile.vc %TMP_SRC% >> %ERRLOG%
)

CD %WORKSPACE%
 
xcopy %WORKSPACE%\libproj-source\src\*.lib %WORKSPACE%\%TMP3RD%\lib /s /y /q
xcopy %WORKSPACE%\libproj-source\src\*.dll %WORKSPACE%\%TMP3RD%\bin /s /y /q
xcopy %WORKSPACE%\libproj-source\src\proj_api.h %WORKSPACE%\%TMP3RD%\include /s /y /q

:DN_PROJ
cd %WORKSPACE%
 
:DO_GEOS 
@set _TMP_LIBS=%_TMP_LIBS% GEOS
@call :SET_BOOST
  
@echo %0: ############################# Download ^& compile LIBGEOS %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBGEOS to %LOGFIL%
)
@set TMP_URL=http://download.osgeo.org/geos/geos-3.4.2.tar.bz2
@set TMP_ZIP=libgeos.tar.bz2
@set TMP_TAR=libgeos.tar
@set TMP_SRC=libgeos-source
@set TMP_BLD=libgeos-build
@set TMP_DIR=geos-3.4.2

@if NOT EXIST %TMP_TAR% (
@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1 
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_GEOS
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_TAR% (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL %UZ_EXE% %UZ_OPT% %TMP_TAR%
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_GEOS
)

cd %WORKSPACE%
@if NOT EXIST %TMP_BLD%\nul (
md %TMP_BLD%
)

cd %TMP_BLD%
@echo Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libgeos-build\build"' %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libgeos-build\build"' to %LOGFIL%
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libgeos-build\build" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC% >> %ERRLOG%
)

@ECHO Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
@ECHO Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)

cd %WORKSPACE%
 
xcopy %WORKSPACE%\libgeos-build\build\bin\geos_c.dll %WORKSPACE%\%TMP3RD%\bin /s /y /q
xcopy %WORKSPACE%\libgeos-build\build\lib\geos_c.lib %WORKSPACE%\%TMP3RD%\lib /s /y /q
xcopy %WORKSPACE%\libgeos-build\build\include\geos_c.h %WORKSPACE%\%TMP3RD%\include /s /y /q

:DN_GEOS
cd %WORKSPACE%

:DO_EXPAT
@set _TMP_LIBS=%_TMP_LIBS% EXPAT
@call :SET_BOOST
@echo %0: ############################# Download ^& compile LIBEXPAT %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile LIBEXPAT to %LOGFIL%
)
@set TMP_URL=http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download
@set TMP_TAR=libexpat.tar
@set TMP_ZIP=libexpat.tar.gz
@set TMP_SRC=libexpat-source
@set TMP_BLD=libexpat-build
@set TMP_DIR=expat-2.1.0

@if NOT EXIST %TMP_TAR% (
@if NOT EXIST %TMP_ZIP% (
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_ZIP% (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP%
@echo %HAD_ERROR%: Failed download from %TMP_URL% to %TMP_ZIP% >> %ERRLOG%
@goto DN_EXPAT
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_TAR% (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
CALL %UZ_EXE% %UZ_OPT% %TMP_TAR%
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_EXPAT
)
 
cd %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
md %TMP_BLD%
)

cd %TMP_BLD%
@echo Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libexpat-build\build"' %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libexpat-build\build"' to %LOGFIL%
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\libexpat-build\build" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit cmake conf/gen %TMP_SRC% >> %ERRLOG%
)

@echo Doing: 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo Doing: 'cmake --build . --config Release --target INSTALL' to %LOGFIL%
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)
 
xcopy %WORKSPACE%\libexpat-build\build\bin\expat.dll %WORKSPACE%\%TMP3RD%\bin /s /y /q
xcopy %WORKSPACE%\libexpat-build\build\lib\expat.lib %WORKSPACE%\%TMP3RD%\lib /s /y /q
xcopy %WORKSPACE%\libexpat-build\build\include\* %WORKSPACE%\%TMP3RD%\include /s /y /q
 
:DN_EXPAT
cd %WORKSPACE%

:DO_PLIB
@set _TMP_LIBS=%_TMP_LIBS% PLIB
@call :SET_BOOST
@echo %0: ############################# Download ^& compile PLIB %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo %0: ############################# Download ^& compile PLIB to %LOGFIL%
)

@set TMP_DIR=PLIB-1.8.5
@set TMP_ZIP=%TMP_DIR%.zip
@set TMP_URL=http://geoffair.org/tmp/%TMP_ZIP%
@set TMP_SRC=plib-source
@set TMP_BLD=plib-build

@if NOT EXIST %TMP_ZIP% ( 
CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%
)

@if NOT EXIST %TMP_SRC%\nul (
@if NOT EXIST %TMP_DIR%\nul (
CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%
)
@REM Seems NEED a delay after the UNZIP, else get access denied on the renaming???
CALL :SLEEP1
REN %TMP_DIR% %TMP_SRC%
)

@if NOT EXIST %TMP_SRC%\nul (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Failed to set up %TMP_SRC%
@echo %HAD_ERROR%: Failed to set up %TMP_SRC% >> %ERRLOG%
@goto DN_PLIB
)

cd %WORKSPACE%

@if NOT EXIST %TMP_BLD%\nul (
md %TMP_BLD%
)

CD %TMP_BLD%

ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\plib-build\build" %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing: 'cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\plib-build\build"
)
cmake ..\%TMP_SRC% -G "%GENERATOR%" -DCMAKE_INSTALL_PREFIX:PATH="%WORKSPACE%\plib-build\build" %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit config/gen %TMP_SRC%
@echo %HAD_ERROR%: Error exit config/gen %TMP_SRC% >> %ERRLOG%
)

ECHO Doing 'cmake --build . --config Debug --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'cmake --build . --config Debug --target INSTALL'
)
cmake --build . --config Debug --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit debug building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit debug building source %TMP_SRC% >> %ERRLOG%
)

ECHO Doing 'cmake --build . --config Release --target INSTALL' %BLDLOG%
IF %HAVELOG% EQU 1 (
ECHO Doing 'cmake --build . --config Release --target INSTALL'
)
cmake --build . --config Release --target INSTALL %BLDLOG%
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@echo %HAD_ERROR%: Error exit building source %TMP_SRC%
@echo %HAD_ERROR%: Error exit building source %TMP_SRC% >> %ERRLOG%
)
 
xcopy %WORKSPACE%\plib-build\build\include\* %WORKSPACE%\%TMP3RD%\include /y /s /q
xcopy %WORKSPACE%\plib-build\build\lib\*.lib %WORKSPACE%\%TMP3RD%\lib /y /q
@REM xcopy %WORKSPACE%\plib-build\build\bin\zlib.dll %WORKSPACE%\%TMP3RD%\bin /y /q
@echo Done PLIB...
:DN_PLIB

@REM external builds
:DO_AL
@REM Avoid re-doing OpenAL if it already appears installed
@if EXIST "%WORKSPACE%\%TMP3RD%\include\AL\al.h" goto DN_AL
@if EXIST openal-build.bat (
@echo Doing an OpenAL build and install...
@call openal-build.bat
@if ERRORLEVEL 1 (
@set /A HAD_ERROR+=1
@set _TMP_BLD_FAIL=%_TMP_BLD_FAIL% OpenAL
)
@set _TMP_LIBS=%_TMP_LIBS% OpenAL
)
:DN_AL

:END
cd %WORKSPACE%

@if NOT %HAD_ERROR% EQU 0 goto ISERR
@echo =================================== %BLDLOG%
@echo Appears a fully successful build... %BLDLOG%
@echo Add deps %_TMP_LIBS% to %TMP3RD% %BLDLOG%
IF %HAVELOG% EQU 1 (
@echo.
@echo Appears a fully successful build... to %LOGFIL%
@echo Add deps %_TMP_LIBS% to %TMP3RD%
)

@REM Create the already done file...
@echo Done 3rdParty build %DATE% %TIME% > %TMPDN3RD%
@echo End: Created file %DATE% %TIME% %CD%\%TMPDN3RD%
@echo.
:EXIT
@endlocal
@exit /b 0

:NOBOOST
@set /A HAD_ERROR+=1
@echo.
@if EXIST %TMP_ZIP% @del %TMP_ZIP%
@echo Did 'CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP%' and got ERROR
@goto ISERR

:NOCGALZIP
@set /A HAD_ERROR+=1
@echo.
@echo CALL %GET_EXE% %TMP_URL% %GET_OPT% %TMP_ZIP% yielded error!
@if EXIST %TMP_ZIP% @del %TMP_ZIP%
@goto ISERR

:NOCGALCMAKE
@set /A HAD_ERROR+=1
@echo.
@echo Error: In %CD%: Can NOT locate ..\%TMP_SRC%\CMakeLists.txt
@goto ISERR

:NOCGAL1
@set /A HAD_ERROR+=1
@echo.
@echo CGAL CMake config, gen FAILED!
@goto ISERR

:NOCGAL2
@set /A HAD_ERROR+=1
@echo.
@echo CGAL build FAILED!
@goto ISERR

:NOCGALREN
@set /A HAD_ERROR+=1
@echo.
@echo FAILED to do REN %TMP_DIR% %TMP_SRC%
@goto ISERR

:NOCGALUZ
@set /A HAD_ERROR+=1
@echo.
@echo Failed 'CALL %UZ_EXE% %UZ_OPT% %TMP_ZIP%'
@goto ISERR

:NOCGALBLD
@set /A HAD_ERROR+=1
@echo.
@echo Error: from MD %TMP_BLD%!!!
@goto ISERR

:NOT_IN_SRC
@set /A HAD_ERROR+=1
@echo.
@echo Error: Do NOT do a build in the repo source! %CD%
@goto ISERR

:NO_MSVC_SEL
@set /A HAD_ERROR+=1
@echo.
@echo Error: Can NOT locate %TMP_MSVC% to setup MSVC environment
@goto ISERR

:ISERR
@REM echo.
@REM type %ERRLOG%
@echo.
@echo Note: Had %HAD_ERROR% ERRORS during the build...
@echo Perhaps above %ERRLOG% output may have details...
@endlocal
@exit /b %HAD_ERROR% 

:SLEEP1
@timeout /t 1 >nul 2>&1
@goto :EOF

:SET_BOOST
@set Boost_DIR=%WORKSPACE%\Boost
@echo Set ENV Boost_DIR=%Boost_DIR% %BLDLOG%
@REM could also use BOOST_ROOT and BOOSTROOT to find Boost.
@goto :EOF

REM eof

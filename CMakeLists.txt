# 17:18 22/01/2016 - Some simgear library tests
# CMakeLists.txt, generated gencmake.pl, on 2016/01/22 17:04:57
cmake_minimum_required( VERSION 2.8.8 )

include (CheckLibraryExists)    # needed for unix, in FindSimGear.cmake

# CMakeScripts or use the ones that come by default with CMake.
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMakeModules)

project( test-sg )

# The version number.
# ### NOTE: *** Adjust version.txt when required ***
# read 'version' file into a variable (stripping any newlines or spaces)
# NOTE: Both version and date MUST be DOT separated, in two lines.
file(READ version.txt versionFile)
if (NOT versionFile)
    message(FATAL_ERROR "Unable to determine project version. version.txt file is missing.")
endif()
string(STRIP "${versionFile}" VERSION_TEXT)
string(REGEX REPLACE "(.*)[\r\n|\n](.*)" "\\1" TEST_SG_VERSION ${VERSION_TEXT})
string(REGEX REPLACE "(.*)[\r\n|\n](.*)" "\\2" TEST_SG_DATE ${VERSION_TEXT})
# establish version number
if (TEST_SG_VERSION)
    string(REPLACE "." ";" VERSION_LIST ${TEST_SG_VERSION})
    list(GET VERSION_LIST 0 TEST_MAJOR_VERSION)
    list(GET VERSION_LIST 1 TEST_MINOR_VERSION)
    list(GET VERSION_LIST 2 TEST_POINT_VERSION)
else ()
    message(FATAL_ERROR "*** FAILED to get a VERSION from version.txt!")
endif ()    
# establish version date
if (TEST_SG_DATE)
    string(REPLACE "." ";" DATE_LIST ${TEST_SG_DATE})
    list(GET DATE_LIST 0 test_YEAR)
    list(GET DATE_LIST 1 test_MONTH)
    list(GET DATE_LIST 2 test_DAY)
else ()
    message(FATAL_ERROR "*** FAILED to get a DATE from version.txt!")
endif ()

set( TEST_VERSION "${TEST_MAJOR_VERSION}.${TEST_MINOR_VERSION}.${TEST_POINT_VERSION}" )
set( TEST_DATE "$(test_YEAR}.${test_MONTH}.${test_DAY}" )

message(STATUS "*** Building version ${TEST_VERSION}, date ${TEST_DATE}")

# Allow developer to select is Dynamic or static library built
set( LIB_TYPE STATIC )  # set default static
option( BUILD_SHARED_LIB "Set ON to build shared Library (DLL)" OFF )

if(CMAKE_COMPILER_IS_GNUCXX)
    set( WARNING_FLAGS -Wall )
endif(CMAKE_COMPILER_IS_GNUCXX)

if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang") 
   set( WARNING_FLAGS "-Wall -Wno-overloaded-virtual" )
endif() 

if(WIN32 AND MSVC)
    # turn off various warnings - none needed in this compile
    set(WARNING_FLAGS "${WARNING_FLAGS} /wd4996")
    # foreach(warning 4244 4251 4267 4275 4290 4786 4305)
    #     set(WARNING_FLAGS "${WARNING_FLAGS} /wd${warning}")
    # endforeach(warning)
    set( MSVC_FLAGS "-DNOMINMAX -D_USE_MATH_DEFINES -D_CRT_SECURE_NO_WARNINGS -D_SCL_SECURE_NO_WARNINGS -D__CRT_NONSTDC_NO_WARNINGS" )
    # if (${MSVC_VERSION} EQUAL 1600)
    #    set( MSVC_LD_FLAGS "/FORCE:MULTIPLE" )
    # endif (${MSVC_VERSION} EQUAL 1600)
    #set( NOMINMAX 1 )
    # to distinguish between debug and release libs
    set( CMAKE_DEBUG_POSTFIX "d" )
else()
    # items for unix
    set(WARNING_FLAGS "${WARNING_FLAGS} -Wno-unused-variable -Wno-unused-but-set-variable")
endif()

set( CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${WARNING_FLAGS} ${MSVC_FLAGS} -D_REENTRANT" )
set( CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${MSVC_LD_FLAGS}" )

set (SGDIR $ENV{SIMGEAR_DIR})
if (SGDIR)
    message(STATUS "*** User ENV SIMGEAR_DIR=${SGDIR}")
    # file(READ ${SGDIR}/include/simgear/version.h SG_VER)
    if (EXISTS "${SGDIR}/include/simgear/version.h")
        message(STATUS "*** Found simgear/version.h - looks good...")
    else ()    
        message(WARNING "*** Unable to locate ${SGDIR}/include/simgear/version.h!")
    endif ()
else ()
    message(STATUS "*** NO User SIMGEAR_DIR set in ENV.")
endif ()

# SIMGEAR_CORE_LIBRARIES, a list of the core static libraries
# SIMGEAR_LIBRARIES, a list of all the static libraries (core + scene)
# SIMGEAR_FOUND, if false, do not try to link to SimGear
# SIMGEAR_INCLUDE_DIRS, where to find the headers
find_package( SimGear )
if (SIMGEAR_FOUND)
    message(STATUS, "*** SimGear found. lib ${SIMGEAR_CORE_LIBRARIES} inc ${SIMGEAR_INCLUDE_DIRS}")
    list(APPEND add_LIBS ${SIMGEAR_CORE_LIBRARIES})
    include_directories( ${SIMGEAR_INCLUDE_DIRS} )
    if (NOT WIN32)
        find_package(Threads REQUIRED)
        # The following variables are set
        #  CMAKE_THREAD_LIBS_INIT     - the thread library
        #  CMAKE_USE_SPROC_INIT       - are we using sproc?
        #  CMAKE_USE_WIN32_THREADS_INIT - using WIN32 threads?
        #  CMAKE_USE_PTHREADS_INIT    - are we using pthreads
        #  CMAKE_HP_PTHREADS_INIT     - are we using hp pthreads
        #  Threads_FOUND
        if (Threads_FOUND)
            message(STATUS "*** Threads found lib ${CMAKE_THREAD_LIBS_INIT}")
            list(APPEND add_LIBS ${CMAKE_THREAD_LIBS_INIT})
        endif ()
    endif ()
else ()
    message(FATAL_ERROR, "SimGear NOT found!")
endif ()

#   ZLIB_INCLUDE_DIRS   - where to find zlib.h, etc.
#   ZLIB_LIBRARIES      - List of libraries when using zlib.
#   ZLIB_FOUND          - True if zlib found.
find_package( ZLIB )
if (ZLIB_FOUND)
    message(STATUS "*** Found ZLIB inc ${ZLIB_INCLUDE_DIRS}, lib ${ZLIB_LIBRARIES}")
    list(APPEND add_LIBS ${ZLIB_LIBRARIES})
    include_directories( ${ZLIB_INCLUDE_DIRS} )
    add_definitions( -DADD_ZLIB_TEST )
else ()
    message(STATUS "*** ZLIB not found!")
endif ()

# configuration file, if needed
# configure_file( ${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h )
# add_definitions( -DHAVE_CONFIG_H )
# include_directories( ${CMAKE_BINARY_DIR} )

if(BUILD_SHARED_LIB)
   set(LIB_TYPE SHARED)
   message(STATUS "*** Building DLL library ${LIB_TYPE}")
else()
   message(STATUS "*** Option BUILD_SHARED_LIB is OFF ${LIB_TYPE}")
endif()
# Total libs 0, exes 1
#################################################
##### LIBRARIES 0 #####
#################################################
#list(APPEND add_LIBS ${name})
# deal with install, if any...
#install( TARGETS ${name}
#    RUNTIME DESTINATION bin
#    LIBRARY DESTINATION lib
#    ARCHIVE DESTINATION lib )
#install(FILES ${${name}_HDRS} DESTINATION include)
#################################################
##### EXECUTABLE 1 #####
#################################################

# test-sg EXECUTABLE from [src],
# have 1 C/C++ sources, 0 headers
set(name test-sg)
set(dir src)
set(${name}_SRCS
    ${dir}/test-sg.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

set(name SGPath_test)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

set(name parseCache)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )

set(name sg_dir_test)
set(dir src)
set(${name}_SRCS
    ${dir}/${name}.cxx
    )
add_executable( ${name} ${${name}_SRCS} )
if (add_LIBS)
    target_link_libraries( ${name} ${add_LIBS} )
endif ()
if (MSVC)
    set_target_properties( ${name} PROPERTIES DEBUG_POSTFIX d )
endif ()
# deal with install, if any...
#install( TARGETS ${name} DESTINATION bin )
# eof

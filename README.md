# Test SimGear 20160416

Small personal set of SimGear library tests, particularly recently SG_PATH code, in Windows...

### Prerequisites

 - installed SimGear library
 - cmake
 - optional: MSVC
 
Is a cmake projects, so mantra is -

 - cd test-sg/build
 - cmake ..
 - cmake --build . --config Release

The default build is done using an X: drive for all header, library dependencies. That is the total FG build is on the X: drive, so uses -

 - Set ENV SIMGEAR_DIR=X:\install\msvc100\simgear
 - cmake .. -DCMAKE_INSTALL_PREFIX=X:\3rdParty
 
The outline of this build is more or less per the [FG Wiki](http://wiki.flightgear.org/Building_using_CMake_-_Windows). That whole build is all in this [repo](https://gitlab.com/fgtools/fg-win). While the repo itself is not so large, be aware a total build marches into the 40 plus giga bytes...

You should be able to adjust this simple **test-sg** build to use where ever you built and installed SimGear, and all its dependencies...

However, so far this testing of the sg_path, used by the in-built terrasync download utility, has yielded no difinitive solution.

Enjoy,  
Geoff.

; 20160416 eof

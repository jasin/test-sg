# Boost Setup - 20160518

**A WIP**

How to setup Boost to use with download-and-compile?

 1. Use Jenkin's simpits 1.55 archive zip download
 2. Clone from the boost.org repository
 3. Use an already installed Boost
 4. Some other way?
 
Boost is quite a large package. It does not need to be updated that often.

#### 1. Use Jenkin's simpits archive zip download

This is a simple 200MB archive.zip download from the Boost-Win atifacts...

It expands to 10,074 Files,  2,033,539,285 bytes, 2,555 Dirs. It contains all the version 1.55 headers, and the 32 and 64 bit libraries, release and debug, for MSVC10 (vc100), about 30 pairs in each.

Now while these static libraries remain compatible with later versions of MSVC, this is an easy install into the 'Boost' folder.

THe last build of this was # 18 Feb 20, 2015 3:03 PM

#### 2. Clone from the boost.org repository

At present this capability is only in d-and-c. This should be moved to make3rd...

Maybe there should be a separate _setupBoost.x64.bat

#### 3. Use an already installed Boost

At present, there is no easy way to communicate this across batch files...

Until Boost installing is unified, this is not really possible, except by modifying the scripts...

; eof

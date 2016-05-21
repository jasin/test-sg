# Boost Setup - 20160518

**A WIP**

How to setup Boost to use with download-and-compile?

 1. Use Jenkin's simpits 1.55 archive zip download
 2. Clone from the boost.org repository
 3. Use an already installed Boost
 4. Some other way?

Boost is quite a large package. It does not need to be updated that often.

#### Progress

20160521: 

After getting the method 2. to work, I found, with MSVC10, that CGAL now has an unresolved external, so it seems for that version need to use the simpits binary download...

In the process of making this choice `switchable`... maybe it is just good enough to have -

````
@if %_MSVS% GTR 10 goto DO_BOOST_BUILD
:DO_BOOST_SP
````

BUT, still to be done is to likewise switch make3rd.x64 - **STILL TO BE DONE**

#### 1. Use Jenkin's simpits archive zip download

This is a simple 200MB archive.zip download from the Boost-Win atifacts...

It expands to 10,074 Files,  2,033,539,285 bytes, 2,555 Dirs. It contains all the version 1.55 headers, and the 32 and 64 bit libraries, release and debug, for MSVC10 (vc100), about 30 pairs in each.

Now while these static libraries remain compatible with later versions of MSVC, this is an easy install into the 'Boost' folder.

The last simpits build of this was # 18 Feb 20, 2015 3:03 PM

#### 2. Clone from the boost.org repository

Originally, this capability was only in d-and-c, and later moved to make3rd...

Now moved to a build-boost.x64.bat, to be called from _setupBoost.x64.bat, ... see #13

The 'boost' branch begins to explore this... please check it out, and give it a try - the simple test procedure is -

````
$ cd test-sg\scripts\d-and-c
$ md tempb
$ cd tempb
$ copy ..\*.bat .
$ _setupBoost.x64
$ # take a break
````

Report problems... thanks...

#### 3. Use an already installed Boost

At present, there is no easy way to communicate this across batch files...

Until Boost installing is unified, this is not really possible, except by modifying the scripts...

; eof

#!/bin/sh
#< build-me.sh - test-sg project - 20160422
BN=`basename $0`
TMPSG="/media/Disk2/FG/fg23/install/simgear"
TMPFIL="$TMPSG/include/simgear/version.h"

if [ ! -d "$TMPSG" ]; then
    echo "$BN: Can NOT locate '$TMPSG'! *** FIX ME ***"
    echo "$BN: This has to be set to the 'install' directory of 'simgear'!"
    exit 1
fi

if [ ! -f "$TMPFIL" ]; then
    echo "$BN: Can NOT locate '$TMPFIL'! *** FIX ME ***"
    echo "$BN: This file should be in the 'install' directory of 'simgear'!"
    exit 1
fi

echo ""
cat $TMPFIL
echo ""
echo "$BN: Aove is version of SimGear bing used..."
echo ""
echo "$BN: Some suggested cmake options to use for debug..."
echo "  -DCMAKE_VERBOSE_MAKEFILE=TRUE - use a verbose Makefile good to see flags. switches, libraries, etc..."
echo "  -DCMAKE_BUILD_TYPE=DEBUG - to add symbols for gdb use (add -g compiler switch)"
echo "  Then run gdb with '\$ gdb --args test-sg'"
echo "$BN: If no options will add -DCMAKE_INSTALL_PREFIX:PATH=$HOME"
echo ""

TMPOPTS=""
TMPSRC=..

for arg in $@; do
    TMPOPTS="$TMPOPTS $arg"
done
if [ -z "$TMPOPTS" ]; then
    TMPOPTS="-DCMAKE_INSTALL_PREFIX:PATH=$HOME"
fi

TMPOPTS="$TMPOPTS -DCMAKE_PREFIX_PATH=$TMPSG"


echo "$BN: Doing 'cmake $TMPSRC $TMPOPTS'..."
cmake $TMPSRC $TMPOPTS
if [ ! "$?" = "0" ]; then
    echo "$BN: Have configuration, generation error"
    exit 1
fi

echo ""
echo "$BN: Doing 'make'"
make
if [ ! "$?" = "0" ]; then
    echo "$BN: Have compile, link error"
    exit 1
fi

echo ""
echo "$BN: appears successful... maybe '[sudo] make install' next? To install $HOME/bin"
echo ""

# eof


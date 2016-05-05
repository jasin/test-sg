/*\
 * sg_dir_test.cxx
 *
 * Copyright (c) 2015 - Geoff R. McLane
 * Licence: GNU GPL version 2
 *
 * Given an input directory, like '.' for current work directory, show a list of entries
 *
 * Written solely for Jasin's on going education...
 *
\*/

#include <stdio.h>
#include <string.h> // for strdup(), ...
#include <string>
#include <vector>
#include <iostream>		     // std::cin, std::cout, etc.
#include <simgear/misc/sg_path.hxx>  // SGPath
#include <simgear/misc/sg_dir.hxx>  // simgear::Dir
#include <simgear/io/iochannel.hxx>  // enum SGProtocolDir (SG_IO_OUT, etc.)
#include <simgear/io/sg_file.hxx>    // SGFile
#include <simgear/misc/strutils.hxx>

static const char *module = "sg_dir_test";

static const char *usr_input = 0;

void give_help( char *name )
{
    printf("%s: usage: [options] usr_input\n", module);
    printf("Options:\n");
    printf(" --help  (-h or -?) = This help and exit(0)\n");

    // TODO: More help
}

int parse_args( int argc, char **argv )
{
    int i,i2,c;
    char *arg, *sarg;
    for (i = 1; i < argc; i++) {
        arg = argv[i];
        i2 = i + 1;
        if (*arg == '-') {
            sarg = &arg[1];
            while (*sarg == '-')
                sarg++;
            c = *sarg;
            switch (c) {
            case 'h':
            case '?':
                give_help(argv[0]);
                return 2;
                break;
            // TODO: Other arguments
            default:
                printf("%s: Unknown argument '%s'. Try -? for help...\n", module, arg);
                return 1;
            }
        } else {
            // bear argument
            if (usr_input) {
                printf("%s: Already have input '%s'! What is this '%s'?\n", module, usr_input, arg );
                return 1;
            }
            usr_input = strdup(arg);
        }
    }
    if (!usr_input) {
        printf("%s: No user input found in command!\n", module);
        return 1;
    }
    return 0;
}

/////////////////////////////////////////////////////////////////
// Just read an display the user's input directory, using SG
/////////////////////////////////////////////////////////////////
int sg_dir_test()
{
    size_t len;
    std::string str(usr_input);
    simgear::Dir d(str);
    simgear::PathList list;
    simgear::PathList::const_iterator it;

    std::cout << "List 1: Call dir.children(), ie with types = 0" << std::endl;
    list = d.children();
    len = list.size();
    std::cout << "Returned " << len << " items..." << std::endl;
    it = list.begin();
    for (; it != list.end(); ++it) {
        std::cout << "Child: '" << it->str() << "', isDir=" << it->isDir() << std::endl;
    }

    std::cout << std::endl;
    std::cout << "List 2: Call dir.children(TYPE_DIR), ie with types = " << simgear::Dir::TYPE_DIR << std::endl;
    list = d.children(simgear::Dir::TYPE_DIR);
    len = list.size();
    std::cout << "Returned " << len << " items..." << std::endl;
    it = list.begin();
    for (; it != list.end(); ++it) {
        std::cout << "Child: '" << it->str() << "', isDir=" << it->isDir() << std::endl;
    }
    std::cout << "NOTE WELL: The above list INCLUDES the so called dot and double dot!" << std::endl;
    std::cout << std::endl;

    std::cout << "List 3: Call dir.children(TYPE_FILE), ie with types = " << simgear::Dir::TYPE_FILE << std::endl;
    list = d.children(simgear::Dir::TYPE_FILE);
    len = list.size();
    std::cout << "Returned " << len << " items..." << std::endl;
    it = list.begin();
    for (; it != list.end(); ++it) {
        std::cout << "Child: '" << it->str() << "', isDir=" << it->isDir() << std::endl;
    }
    std::cout << std::endl;
    std::cout << "Jasin, WHERE IS THE PROBLEM?" << std::endl;

    return 0;
}

// main() OS entry
int main( int argc, char **argv )
{
    int iret = 0;
    iret = parse_args(argc,argv);
    if (iret) {
        if (iret == 2)
            iret = 0;
        return iret;
    }

    iret = sg_dir_test();  // actions of app

    return iret;
}


// eof = sg_dir_test.cxx

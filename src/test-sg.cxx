/*\
 * test-sg.cxx
 *
 * Copyright (c) 2015 - Geoff R. McLane
 * Licence: GNU GPL version 2
 *
\*/

#include <sys/stat.h>
#include <sys/types.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h> // for strdup(), ...
#include <string>
#ifdef WIN32
#include <direct.h>
#include <io.h>
#endif
#include <errno.h>
#include <simgear/compiler.h>
#include <simgear/misc/sg_path.hxx>
#include <simgear/misc/sg_dir.hxx>
#include <simgear/io/sg_file.hxx>
#include <simgear/debug/logstream.hxx>
// other includes
// API DOCS: http://api-docs.freeflightsim.org/simgear/classSGPath.html (3.5.0)
#ifdef WIN32
#define getcwd _getcwd
#endif

static const char *module = "test-sg";

static const char *usr_input = 0;

void give_help( char *name )
{
    printf("%s: usage: [options] usr_input\n", module);
    printf("Options:\n");
    printf(" --help  (-h or -?) = This help and exit(2)\n");
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
    //if (!usr_input) {
    //    printf("%s: No user input found in command!\n", module);
    //    return 1;
    //}
    return 0;
}

///////////////////////////////////////////////////////////////////////
#ifdef _WIN32

typedef int mode_t;

/// @Note If STRICT_UGO_PERMISSIONS is not defined, then setting Read for any
///       of User, Group, or Other will set Read for User and setting Write
///       will set Write for User.  Otherwise, Read and Write for Group and
///       Other are ignored.
///
/// @Note For the POSIX modes that do not have a Windows equivalent, the modes
///       defined here use the POSIX values left shifted 16 bits.

static const mode_t S_ISUID      = 0x08000000;           ///< does nothing
static const mode_t S_ISGID      = 0x04000000;           ///< does nothing
static const mode_t S_ISVTX      = 0x02000000;           ///< does nothing
static const mode_t S_IRUSR      = mode_t(_S_IREAD);     ///< read by user
static const mode_t S_IWUSR      = mode_t(_S_IWRITE);    ///< write by user
static const mode_t S_IXUSR      = 0x00400000;           ///< does nothing
#   ifndef STRICT_UGO_PERMISSIONS
static const mode_t S_IRGRP      = mode_t(_S_IREAD);     ///< read by *USER*
static const mode_t S_IWGRP      = mode_t(_S_IWRITE);    ///< write by *USER*
static const mode_t S_IXGRP      = 0x00080000;           ///< does nothing
static const mode_t S_IROTH      = mode_t(_S_IREAD);     ///< read by *USER*
static const mode_t S_IWOTH      = mode_t(_S_IWRITE);    ///< write by *USER*
static const mode_t S_IXOTH      = 0x00010000;           ///< does nothing
#   else
static const mode_t S_IRGRP      = 0x00200000;           ///< does nothing
static const mode_t S_IWGRP      = 0x00100000;           ///< does nothing
static const mode_t S_IXGRP      = 0x00080000;           ///< does nothing
static const mode_t S_IROTH      = 0x00040000;           ///< does nothing
static const mode_t S_IWOTH      = 0x00020000;           ///< does nothing
static const mode_t S_IXOTH      = 0x00010000;           ///< does nothing
#   endif
static const mode_t MS_MODE_MASK = 0x0000ffff;           ///< low word

static inline int my_chmod(const char * path, mode_t mode)
{
    int result = _chmod(path, (mode & MS_MODE_MASK));

    if (result != 0)
    {
        result = errno;
    }

    return (result);
}
#else
static inline int my_chmod(const char * path, mode_t mode)
{
    int result = chmod(path, mode);

    if (result != 0)
    {
        result = errno;
    }

    return (result);
}
#endif

#ifdef _MSC_VER
#define M_IS_DIR _S_IFDIR
#else // !_MSC_VER
#define M_IS_DIR S_IFDIR
#endif
enum DiskType {
    MDT_NONE,
    MDT_DIR,
    MDT_FILE
};

//////////////////////////////////////////////////////////////////////
static struct stat _s_buf;
DiskType is_file_or_directory ( const char * path )
{
    if (!path || (*path == 0))
        return MDT_NONE;    // oops, nothing is nothing!
	if (stat(path,&_s_buf) == 0)
	{
		if (_s_buf.st_mode & M_IS_DIR)
			return MDT_DIR;
		else
			return MDT_FILE;
	}
	return MDT_NONE;
}

//////////////////////////////////////////////////////////////////////
int sg_path_tests()
{
    bool keep_file = false;
    int iret = 0;
    char tmp[264];
    struct stat buf;
    int test_num = 0;
    mode_t mode = ( S_IRUSR |  S_IWUSR );
    std::string path;
    std::string file("tempfile.txt");
    std::string file2("tempfile2.txt");
    if (usr_input)
        path = usr_input;
    else
        path = "temp";
    if (getcwd(tmp, sizeof(tmp)) != NULL)
       fprintf(stdout, "%s: Test setup: Current working dir: %s\n", module, tmp);
    else {
       fprintf(stderr, "%s: Failed to get Current working dir!\n", module);
       return 1;
    }
    SGPath cwd(tmp);
    if (!cwd.exists()) {
       fprintf(stderr, "%s: What! Current working dir %s does not exist!\n", module, cwd.str().c_str());
       return 1;
    }
    ////////////////////////////////////////////////////////////////////
    cwd.append(path);
    path = cwd.str();
    SGPath cwd2(path);   // keep a second copy
    fprintf(stderr, "%s: Built a new path to use '%s'...\n", module, path.c_str());
    if (stat(path.c_str(),&buf) == 0) {
        int r2;
        fprintf(stderr, "%s: New path to use '%s' exists... attempting deletion...\n", module, path.c_str());
        if (buf.st_mode && M_IS_DIR) {
            r2 = rmdir(path.c_str());
        } else {
            r2 = unlink(path.c_str());
        }
        if (r2) {
           fprintf(stderr, "%s: Failed to delete dir %s! %s (%d)\n", module, path.c_str(), strerror(errno), errno);
        }
    } else {
        fprintf(stderr, "%s: New path '%s' does not yet exist...\n", module, path.c_str());
    }
    ///////////////////////////////////////////////////////////////////
    if (!cwd.exists()) {
        SGPath tmp2(cwd);
        tmp2.append(file);
        fprintf(stderr, "%s: Attempting to create new path '%s'\n         NOTE: have appended a file name for SG!\n", module, tmp2.str().c_str());
        if (tmp2.create_dir()) {
           fprintf(stderr, "%s: Failed to create dir %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
           return 1;
        } else {
           fprintf(stderr, "%s: New path '%s' created...\n", module, cwd.str().c_str());
        }
    }
    // Create a FILE
    cwd.append(file);
    //SGFile sgf(cwd.str());
    test_num++;
    fprintf(stderr, "\n%s: Test %d - Write a file and attempt a delete. First with handle open, then after closed...\n", module, test_num);
    FILE *fp = fopen( cwd.str().c_str(),"w");
    if (!fp) {
        fprintf(stderr, "%s: Failed to create file %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
        iret = 1;
    } else {
        size_t res = fwrite(cwd.str().c_str(), 1, cwd.str().size(), fp);
        if (res == cwd.str().size()) {
            fprintf(stderr, "%s: Written file '%s', %d bytes.\n", module, cwd.str().c_str(), (int)res);
        } else {
            fprintf(stderr, "%s: Failed to write to file %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
            iret = 1;
        }
        fprintf(stderr, "%s: Attempting to remove file %s, WITH an open handle!\n", module, cwd.str().c_str());
        if (!cwd.remove()) {
            fprintf(stderr, "%s: Failed to remove file %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
            iret = 1;
        } else {
            fprintf(stderr, "%s: What! That succeeded!\n", module);
        }
        ///////////////////////////////////////////////////////
        fclose(fp); // *** CLOSE THE HANDLE ***
         fprintf(stderr, "%s: Closed handle...\n", module);
        ///////////////////////////////////////////////////////
        cwd2.append(file2); // get a new name
        test_num++;
        fprintf(stderr, "\n%s: Test %d - Attempt to rename the file...\n", module, test_num);
        if (cwd.rename(cwd2)) {
            fprintf(stderr, "%s: File renamed to '%s'.\n", module, cwd2.str().c_str());
            cwd = cwd2;
        } else {
            fprintf(stderr, "%s: Failed renamed to '%s'! %s (%d)\n", module, cwd2.str().c_str(), strerror(errno), errno);
        }

        if (!keep_file) {
            fprintf(stderr, "%s: Try removal again of '%s'...\n", module, cwd.str().c_str());
            if (!cwd.remove()) {
                fprintf(stderr, "%s: Failed to remove file %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
                iret = 1;
            } else {
                fprintf(stderr, "%s: That succeeded, as expected...\n", module);
            }
        }
    }
    //if (iret)
    //    return iret;



    cwd = path;

    //if ( my_chmod( path.c_str(), mode) ) {
    //    fprintf(stderr, "%s: Failed to reset path %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
    //    iret = 1;
    //}

    bool dir_deleted = false;
    test_num++;
    fprintf(stderr, "\n%s: Test %d - Removal of path '%s'... now empty, with SGPath::remove... should fail...\n", module, test_num, path.c_str());
    // ERROR: SGPath::remove is to ONLY remove files!
    // See: http://api-docs.freeflightsim.org/simgear/classSGPath.html#ae05c94f36fe03aad063adeca84077695
    // so this should fail
    if (cwd.remove()) {
        fprintf(stderr, "%s: WHAT!, SGPath.remove(), REMOVED a path %s!\n", module, cwd.str().c_str() );
        dir_deleted = true;
    } else {
        fprintf(stderr, "%s: AS EXPECTED, using SGPath.remove(), failed to remove path %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
    }
    // so how to remove a directory?
    // AH: http://api-docs.freeflightsim.org/simgear/classsimgear_1_1Dir.html#a62f4d9c069adcd2c29950e40e1db265e
    if (!dir_deleted) {
        simgear::Dir d = path;  // cast string path into a SG DIRECTORY
        test_num++;
        fprintf(stderr, "\n%s: Test %d - Removal of path '%s', with simgear::Dir::remove...\n", module, test_num, path.c_str());
        // this is an EMPTY directory, so do not need to set 'recursive',
        // but another test would be to populate it with files AND directories, and test 'true'... another day...
        // NOTE: This is used in SVNDirectory.cxx, which is what I think 'terrasync' uses
        // See: http://api-docs.freeflightsim.org/simgear/SVNDirectory_8cxx_source.html#l00238
        if (d.remove(false)) {
            fprintf(stderr, "%s: That succeeded, as expected...\n", module);
        } else {
            fprintf(stderr, "%s: using simgear::Dir::remove(), failed to remove path %s! %s (%d)\n", module, cwd.str().c_str(), strerror(errno), errno);
        }
    }

    return iret;
}

// main() OS entry
int main( int argc, char **argv )
{
    int iret = 0;
    iret = parse_args(argc,argv);
    if (iret)
        return iret;

    sglog().setLogLevels( SG_ALL, SG_ALERT );

    iret = sg_path_tests();    // actions of app

    return iret;
}


// eof = test-sg.cxx

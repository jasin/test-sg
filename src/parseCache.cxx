/*\
 * parseCache.cxx
 *
 * Copyright (c) 2015 - Geoff R. McLane
 * Licence: GNU GPL version 2
 *
\*/

#include <stdio.h>
#include <string.h> // for strdup(), ...
#include <fstream>
#include <string>
#include <vector>
#include <assert.h>
#include <simgear/compiler.h>
#include <simgear/misc/sg_path.hxx>
#include <simgear/misc/sg_dir.hxx>
#include <simgear/io/sg_file.hxx>
#include <simgear/debug/logstream.hxx>
#include <simgear/misc/strutils.hxx>

using namespace std;

static const char *module = "parseCache";

static const char *usr_input = 0;

void give_help( char *name )
{
    printf("%s: usage: [options] usr_input\n", module);
    printf("Options:\n");
    printf(" --help  (-h or -?) = This help and exit(2)\n");
    // TODO: More help
}

const char* DAV_CACHE_NAME = ".terrasync_cache";
const char* CACHE_VERSION_4_TOKEN = "terrasync-cache-4";

enum LineState
{
  LINESTATE_HREF = 0,
  LINESTATE_VERSIONNAME
};

//void SVNDirectory::parseCache()
void parseCache(const char *localPath)
{
    int line = 0;
  SGPath p(localPath);
  p.append(DAV_CACHE_NAME);
  if (!p.exists()) {
    return;
  }
    
  char href[1024];
  char versionName[128];
  LineState lineState = LINESTATE_HREF;
  std::ifstream file(p.c_str());
    if (!file.is_open()) {
        SG_LOG(SG_TERRASYNC, SG_WARN, "unable to open cache file for reading:" << p);
        return;
    }
  bool doneSelf = false;
    
  file.getline(href, 1024);
  line++;
  printf("Line %d: '%s'\n", line, href);

  if (strcmp(CACHE_VERSION_4_TOKEN, href)) {
    SG_LOG(SG_TERRASYNC, SG_WARN, "invalid cache file [missing header token]:" << p << " '" << href << "'");
    return;
  }
    
    std::string vccUrl;
    file.getline(href, 1024);
    vccUrl = href;

  line++;
  printf("Line %d: '%s'\n", line, href);  

  while (!file.eof()) {
    if (lineState == LINESTATE_HREF) {
      file.getline(href, 1024);
      lineState = LINESTATE_VERSIONNAME;
      line++;
      printf("Line %d: '%s' set lineState=LINESTATE_VERSIONNAME\n", line, href);  
    } else {
      assert(lineState == LINESTATE_VERSIONNAME);
      file.getline(versionName, 1024);
      lineState = LINESTATE_HREF;
      char* hrefPtr = href;
      line++;
      printf("Line %d: '%s' set lineState=LINESTATE_HREF\n", line, href);  

      if (!doneSelf) {
#if 0 // 00000000000000000000000000000000000000
        if (!dav) {
          dav = new DAVCollection(hrefPtr);
          dav->setVersionName(versionName);
        } else {
          assert(string(hrefPtr) == dav->url());
        }
        
        if (!vccUrl.empty()) {
            dav->setVersionControlledConfiguration(vccUrl);
        }
        _cachedRevision = versionName;
#endif // 0000000000000000000000000000000000        
        doneSelf = true;
      } else {
          //DAVResource* child = addChildDirectory(hrefPtr)->collection();
          //string s = strutils::strip(versionName);
          std::string s = simgear::strutils::strip(versionName);
          if (!s.empty()) {
              //child->setVersionName(versionName);
          }
      } // of done self test
    } // of line-state switching 
  } // of file get-line loop
}


void parseCache2(const char *localPath)
{
  SGPath p(localPath);
  p.append(DAV_CACHE_NAME);
  if (!p.exists()) {
    return;
  }
    
  char href[1024];
  char versionName[128];
  LineState lineState = LINESTATE_HREF;
  std::ifstream file(p.c_str());
    if (!file.is_open()) {
        SG_LOG(SG_TERRASYNC, SG_WARN, "unable to open cache file for reading:" << p);
        return;
    }
  bool doneSelf = false;
    
  file.getline(href, 1024);
  if (strcmp(CACHE_VERSION_4_TOKEN, href)) {
    SG_LOG(SG_TERRASYNC, SG_WARN, "invalid cache file [missing header token]:" << p << " '" << href << "'");
    return;
  }
    
    std::string vccUrl;
    file.getline(href, 1024);
    vccUrl = href;

  std::vector<std::string> cache;
  while (!file.eof()) {
      file.getline(href, 1024);
      cache.push_back(href);
  }
  file.close(); // done with the file

  std::vector<std::string>::iterator it = cache.begin();
  for ( ; it != cache.end(); it++) {
    if (lineState == LINESTATE_HREF) {
      strcpy(href, (*it).c_str());
      lineState = LINESTATE_VERSIONNAME;
    } else {
      assert(lineState == LINESTATE_VERSIONNAME);
      strcpy(versionName, (*it).c_str());
      lineState = LINESTATE_HREF;
      char* hrefPtr = href;

      if (!doneSelf) {
#if 0 // 00000000000000000000000000000000000000
        if (!dav) {
          dav = new DAVCollection(hrefPtr);
          dav->setVersionName(versionName);
        } else {
          assert(string(hrefPtr) == dav->url());
        }
        
        if (!vccUrl.empty()) {
            dav->setVersionControlledConfiguration(vccUrl);
        }
        _cachedRevision = versionName;
#endif // 0000000000000000000000000000000000        
        doneSelf = true;
      } else {
          //DAVResource* child = addChildDirectory(hrefPtr)->collection();
          //string s = strutils::strip(versionName);
          std::string s = simgear::strutils::strip(versionName);
          if (!s.empty()) {
              //child->setVersionName(versionName);
          }
      } // of done self test
    } // of line-state switching 
  } // of lines in string vector
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
#ifndef NDEBUG
    if (!usr_input)
        usr_input = "D:\\FG\\terrasync\\Terrain\\e110n20\\e114n22";
#endif
    if (!usr_input) {
        printf("%s: No user input found in command!\n", module);
        return 1;
    }
    return 0;
}

// main() OS entry
int main( int argc, char **argv )
{
    int iret = 0;
    iret = parse_args(argc,argv);
    if (iret)
        return iret;

    parseCache(usr_input); // actions of app

    return iret;
}


// eof = parseCache.cxx

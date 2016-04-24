/* 
   Test only
 */

#include <iostream>		     // std::cin, std::cout, etc.

#include <simgear/misc/sg_path.hxx>  // SGPath
#include <simgear/io/iochannel.hxx>  // enum SGProtocolDir (SG_IO_OUT, etc.)
#include <simgear/io/sg_file.hxx>    // SGFile
#ifdef ADD_ZLIB_TEST
#include <simgear/misc/sgstream.hxx> // sg_gzifstream
#endif
#include <vector>
#include <string>

#ifdef WIN32
#define DEF_FIX_DAT "D:\\FG\\xplane\\20160424\\earth_fix.dat"
#else
#define DEF_FIX_DAT "/home/flo/flightgear/X-Plane data/earth_fix.dat"
#endif

typedef std::vector<std::string> vSTG;

void playWithSGPathAndSGFile()
{
    SGPath dir("/tmp/this/is/a/deep/test/dir");
    SGPath fullPath = dir;
    fullPath.append("test file.txt");

    if (dir.exists()) {
        std::cerr << dir << (" already exists, doing nothing "
			     "(which we are pretty good at!)")
		  << std::endl;
    } else {
	if (!fullPath.create_dir())
	    std::cerr << "Created directory '" << dir.str() << "'" <<
		std::endl;

	SGFile file(fullPath.str());
	if (file.open(SG_IO_OUT)) {
	    std::cerr << "Created file '" << fullPath.str() << "'" <<
		std::endl;
	    file.writestring("bla bla.\r\n");
	    file.close();

	    std::cerr << "File '" << fullPath.str() << "' " <<
		(fullPath.canRead() ? "can": "can't") << " be read" << std::endl;
	    std::cerr << "File '" << fullPath.str() << "' " <<
		(fullPath.canWrite() ? "can": "can't") << " be written" <<
		std::endl;
	}
    }
}

#ifdef ADD_ZLIB_TEST

// just a convenient DEBUG trap
int check_me()
{
    int i;
    i = 0;
    return i;
}

typedef struct tagDUPES {
    double lat,lon;
    std::string id;
    unsigned int lnn;
}DUPES, *PDUPES;

typedef std::vector<DUPES> vDUP;

PDUPES ident_is_dupe( vDUP &vID, std::string &id )
{
    PDUPES pd;
    size_t ii, len = vID.size();
    for (ii = 0; ii < len; ii++) {
        pd = &vID[ii];
        if (id == pd->id)
            return pd;
    }
    return NULL;
}


int fixDatParsing(const std::string &fixDat)
{
    SGPath path(fixDat);

    sg_gzifstream in( path.str() );
    if ( !in.is_open() ) {
        std::cerr << "Cannot open file: " << path << std::endl;
        return 1;
    }

    vDUP vIDS;
    vDUP vDupes;
    PDUPES pd;

    unsigned int lineNumber = 1;
    // toss the first three lines of the file
    for (int i=0; i < 3; i++, lineNumber++)
        in >> skipeol;


    // read in each remaining line of the file
    double lat, lon;
    std::string ident;  // get string creation/destruction out of loop
    DUPES dupe;
    while ( ! in.eof() ) {
        in >> lat >> lon >> ident;

        if (ident == "EL")
            check_me();

        if (lat > 95) break; // this should be before testing fail, and output

        std::cerr << "Line " << lineNumber << ": lat " << lat << ", " <<
            "lon: " << lon << ", ident: '" << ident << "'" << std::endl;

        dupe.id = ident;
        dupe.lat = lat;
        dupe.lon = lon;
        dupe.lnn = lineNumber + 1;
        // keep a quick list of duplicates
        if (pd = ident_is_dupe( vIDS, ident)) {
            if (!ident_is_dupe( vDupes, ident )) {
                vDupes.push_back(*pd);
            }
            vDupes.push_back(dupe);
        }
        vIDS.push_back(dupe);

        if (in.fail()) {
            std::cerr << "Input stream fail()ed. Aborting." << std::endl;
            return 2;   // now this does not happen...
        }

        // in >> skipcomment;
        in >> skipeol;  // there are no # comment in fix.dat, use skipeol
        lineNumber++;
    }

    // show the DUPES
    size_t ii, len = vDupes.size();
    ident = "";
    if (len) {
        std::cerr << "Have " << len << " duplicate idents..." << std::endl;
        for (ii = 0; ii < len; ii++) {
            pd = &vDupes[ii];
            if (pd->id != ident) {
                ident = pd->id;
                std::cerr << std::endl;
                if (ident == "EL")
                    check_me();
            }
            std::cerr << "Line " << pd->lnn << ": lat " << pd->lat << ", " <<
            "lon: " << pd->lon << ", ident: '" << pd->id << "'" << std::endl;
        }
    }

    return 0;
}

#endif // #ifdef ADD_ZLIB_TEST


int main(int argc, char **argv) 
{
    playWithSGPathAndSGFile();

#ifdef ADD_ZLIB_TEST
    // earth_fix.dat.gz is automatically used if earth_fix.dat doesn't exist
    const std::string fixDat(DEF_FIX_DAT);  // "/home/flo/flightgear/X-Plane data/earth_fix.dat"

    std::cerr << std::endl << "Now reading '" << fixDat << "'..." << std::endl;

    return fixDatParsing(fixDat);
#else // !#ifdef ADD_ZLIB_TEST
    return 0;
#endif

}

// eof

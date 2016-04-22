#include <iostream>		     // std::cin, std::cout, etc.

#include <simgear/misc/sg_path.hxx>  // SGPath
#include <simgear/io/iochannel.hxx>  // enum SGProtocolDir (SG_IO_OUT, etc.)
#include <simgear/io/sg_file.hxx>    // SGFile
#ifdef ADD_ZLIB_TEST
#include <simgear/misc/sgstream.hxx> // sg_gzifstream
#endif

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
int fixDatParsing(const std::string &fixDat)
{
    SGPath path(fixDat);

    sg_gzifstream in( path.str() );
    if ( !in.is_open() ) {
        std::cerr << "Cannot open file: " << path << std::endl;
        return 1;
    }

    unsigned int lineNumber = 1;
    // toss the first three lines of the file
    for (int i=0; i < 3; i++, lineNumber++)
        in >> skipeol;


    // read in each remaining line of the file
    while ( ! in.eof() ) {
        double lat, lon;
        std::string ident;
        in >> lat >> lon >> ident;
        std::cerr << "Line " << lineNumber << ": lat " << lat << ", " <<
            "lon: " << lon << ", ident: '" << ident << "'" << std::endl;

        if (in.fail()) {
            std::cerr << "Input stream fail()ed. Aborting." << std::endl;
            return 2;
        }

        if (lat > 95) break;

        in >> skipcomment;
        lineNumber++;
    }

    return 0;
}

#endif // #ifdef ADD_ZLIB_TEST


int main(int argc, char **argv) 
{
    playWithSGPathAndSGFile();

#ifdef ADD_ZLIB_TEST
    // earth_fix.dat.gz is automatically used if earth_fix.dat doesn't exist
    const std::string fixDat(
	"/home/flo/flightgear/X-Plane data/earth_fix.dat");
    std::cerr << std::endl << "Now reading '" << fixDat << "'..." << std::endl;

    return fixDatParsing(fixDat);
#else // !#ifdef ADD_ZLIB_TEST
    return 0;
#endif

}

// eof

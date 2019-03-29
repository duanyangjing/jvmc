#ifndef _DRIVER_
#define _DRIVER_

#include <fstream>
#include "scanner.hh"
#include "parser.tab.hh"

namespace Front {
  class Driver {
  public:
    Driver(std::istream& in);
    void parse();
    ~Driver();
  private:
    Front::Scanner* scanner;
    Front::Parser* parser;
  };
}


#endif

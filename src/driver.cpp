#include "driver.hh"
#include <fstream>

Front::Driver::Driver(std::istream& in) {	  
  scanner = new Front::Scanner(in);
  parser = new Front::Parser(scanner);
}

void Front::Driver::parse() {
  parser->parse();
}

Front::Driver::~Driver() {
  delete scanner;
  delete parser;
}


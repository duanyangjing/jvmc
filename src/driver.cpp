#include "driver.hh"
#include <fstream>

Front::Driver(std::istream& in) {
  scanner = new Front::Scanner(in);
  parser = new Front::Parser(scanner);
}
void Front::Driver::parse() {
  parser->parse();
  return;
}

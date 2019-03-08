#include "driver.hh"
#include "parser.tab.hh"
#include <fstream>

int main(int argc, char** argv) {
  std::ifstream in(argv[1]);
  Front::Driver driver(in);
  driver.parse();
  return 0;
}

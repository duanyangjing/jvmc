#include "driver.hh"
#include "parser.tab.hh"
#include "ast.hh"
#include <fstream>
#include <iostream>

StmtList* ast;

int main(int argc, char** argv) {
  std::ifstream in(argv[1]);
  Front::Driver driver(in);

  ast = new std::vector<Stmt*>();
  driver.parse();

  std::cout << ast;
  return 0;
}

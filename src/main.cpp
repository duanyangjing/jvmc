#include "common.hh"
#include "parser.tab.hh"

int main() {
  Front::Parser::parse("../test/simplefun.c");
  return 0;
}

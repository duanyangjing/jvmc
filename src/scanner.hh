#ifndef _SCANNER_
#define _SCANNER_

#include <fstream>
#include <iostream>

// fix found from
// https://stackoverflow.com/questions/40663527/how-to-inherit-from-yyflexlexer
#if !defined(yyFlexLexerOnce)
#include <FlexLexer.h>
#endif

#include "location.hh"
#include "parser.tab.hh"

namespace Front {
  // yyFlexLexer defined in FlexLexer.h
  class Scanner: public yyFlexLexer {
  public:
    Scanner(std::istream& in):yyFlexLexer(in, std::cout) {
      // actually a location class in location.hh
      loc = new Front::Parser::location_type();
    }
    ~Scanner(){}

    int yylex(Front::Parser::semantic_type* lval,
	      Front::Parser::location_type* location);

  private:
    Front::Parser::semantic_type* yylval;
    Front::Parser::location_type* loc;
  };

    
    
}

#endif

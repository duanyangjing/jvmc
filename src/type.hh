#ifndef _TYPE_
#define _TYPE_

#include "ast.hh"
#include <vector>
#include "common.hh"
#include <string>

// I - int
// C - char
// F - float
// V - void
// E - error
enum BASETYPE {I, C, F, V, E, STRUCT};

class Type {
private:
  BASETYPE baseType;
  std::string* structName = nullptr; // null if not a struct
  ExprList* dimensions; // null if not an array
public:
  Type(BASETYPE baseType);

  Type(std::string* structName);

  Type(BASETYPE baseType, ExprList* dimensions);

  // for array of structs
  Type(std::string* structName, ExprList* dimensions);

  void setDimensions(ExprList* dimensions);
       
};


#endif

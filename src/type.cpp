#include "type.hh"

Type::Type(BASETYPE baseType): baseType(baseType) {}

Type::Type(std::string* structName): baseType(STRUCT), structName(structName) {}

Type::Type(BASETYPE baseType, ExprList* dimensions):
  baseType(baseType), dimensions(dimensions) {}

  // for array of structs
Type::Type(std::string* structName, ExprList* dimensions):
  baseType(STRUCT), structName(structName), dimensions(dimensions) {}

void Type::setDimensions(ExprList* dimensions) {
  this->dimensions = dimensions;
}

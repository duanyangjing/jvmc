#ifndef _TYPE_
#define _TYPE_

#include "ast.hh"
#include <vector>
#include "common.hh"

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
        ExpressionList* dimensions; // null if not an array
    public:
        Type(BASETYPE baseType):
            baseType(baseType) {}

        Type(std::string* structName):
            baseType(STRUCT), structName(structName) {}

        Type(BASETYPE baseType, ExpressionList* dimensions):
            baseType(baseType), dimensions(dimensions) {}

        // for array of structs
        Type(std::string* structName, ExpressionList* dimensions):
            baseType(STRUCT), structName(structName), dimensions(dimensions) {}

        void setDimensions(ExpressionList* dimensions) {
            this->dimensions = dimensions;
        }
       
};


#endif
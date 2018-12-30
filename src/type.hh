#ifndef _TY_
#define _TY_
#include "ast.hh"
#include <stdbool.h>
#include <stdlib.h>
#include <vector>
#include "common.h"


enum BASETYPE {TY_INT, TY_CHAR, TY_FLOAT, TY_STRUCT, TY_ERR, TY_VOID};

struct TY_type;
typedef struct TY_type *type;
// struct S {int x, struct {} y;};
// S is saved in symbol table, second field is given arbitrary name and saved in
// symbol table
struct structtype {
    // annoymous struct has no name
    char structname[MAX_ID_LEN];
	// list of structfields (vardec)
	struct list *fields;
};

// type and dimension, handles base types and their arrays, no tydef and fun.
// all typedefs will eventually reduce to actual type, functions are handled
// in symbol table.
struct TY_type {
    enum BASETYPE basetype;
// name of the struct if this is a struct type, struct types are distinguished
// by names. Two structs with identical structure but different names are
// considered different.
    struct structtype *structinfo;
	struct list *dim_exprs;
};

// two types are the same -- same base type and same dimensions
bool TY_sametype(type t1, type t2);
// a given type is an array
bool TY_isArray(type t);
// type check an absyn expr
type TY_check(expr e, int scope);

bool TY_isInt(type t);

bool TY_isFloat(type t);

bool TY_isErr(type t);
char *TY_getStructname(type t);
type TY_mkInt();
type TY_mkFloat();
type TY_mkVoid();
// set the dimension information of a type
type TY_setDim(type t, struct list *dim_exprs);
type TY_mkErr();
type TY_mkStruct();


#endif
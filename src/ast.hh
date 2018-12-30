#ifndef _AST_
#define _AST_
#include "common.hh"
#include <vector>
#include "type.hh"

class Expression {
    
}

class Statement {

}

//------------------------expressions--------------------
enum UOperator {UMINUS, NOT}
enum BOperator {OR, AND, EQ, NE, LT, LE, GT, GE, ADD, SUB, MULT, DIV}
// unary operation
class Uop : Expression {
    UOperator operator;
    Expression* operand;
}

// binary operation
class Bop : Expression {
    BOperator operator;
    Expression* left;
    Expression* right;
} 

class IntConstant : Expression {
    int val;
}

class CharConstant : Expression {
    char val;
}

class FloatConsant : Expression {
    float val;
}

class StrConstant : Expression {
    char *val;
}

// lvalue: struct, array, var access
class LValue : Expression {

}

class StructAccess : LValue {
    Expression* base;
    char field[MAX_ID_LEN]; 
}

class ArrayAccess : LValue {
    Expression* base;
    Expression* index;
}

class VariableAccess : LValue {
    char name[MAX_ID_LEN];
}

// non void function call
class FunctionCall : Expression {
    char fname[MAX_ID_LEN];
    vector<Expression*> actuals;
}

// make assignment an expression, e.g. x = (y = 1) here y = 1 evaluates to 1
class Assignment : Expression {
    LValue* lvalue;       
    Expression* rvalue;
}

class Error : Expression {

}

//------------------------statements---------------------------
// declarations are not included in the ast, they are in the symbol table
class StatementBlock : Statement {
    vector<Statement*> statements;
}

//  if then else
class Ite : Statement {
    Expression* condition;
    Statement* ifBranch;
    Statement* elseBranch;
}
 
class While : Statement {
    Expression* condition;
    Statement* body;
}

class For : Statement {
    Statement* init;
    Statement* condition;
    Statement* increment;
}

class VoidFunctionCall : Statement {
    char fname[MAX_ID_LEN];
    vector<Expression*> actuals;
}

class Return : Statement {
    Expression* exp; // null if it is a void return
}


#endif
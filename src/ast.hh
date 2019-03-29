#ifndef _AST_
#define _AST_

#include "common.hh"
#include <vector>

#include <string>
#include <iostream>

class Stmt;
class Expr;
class VarDecl;
class Type;

typedef std::vector<Stmt*> StmtList;
typedef std::vector<Expr*> ExprList;
typedef std::vector<VarDecl*> VarDeclList;
// TODO: better ways to avoid circular dependency?
#include "type.hh"

// root of the ast, populated by parser

class Stmt {};

// expr is a valued stmt, same as clang treatment
class Expr : public Stmt {};
//------------------------exprs--------------------
enum UnaryOperator {OP_UMINUS, OP_NOT};
enum BinaryOperator {OP_OR, OP_AND, OP_EQ, OP_NE, OP_LT, OP_LE, OP_GT, OP_GE, 
		     OP_PLUS, OP_MINUS, OP_TIMES, OP_DIVIDE, OP_ASSIGN};
    
std::string uopToString(UnaryOperator o);
std::string bopToString(BinaryOperator o); 

// unary operation
class UnaryOperation : public Expr {
public:
  UnaryOperator op;
  Expr* e;
  UnaryOperation(UnaryOperator, Expr*);
};

// binary operation
class BinaryOperation : public Expr {
public:
  BinaryOperator op;
  Expr* left;
  Expr* right;
  BinaryOperation(BinaryOperator, Expr*, Expr*);
}; 

class IntConstant : public Expr {
public:
  int val;
  IntConstant(int);
};

class CharConstant : public Expr {
public:
  char val;
  CharConstant(char);
};

class FloatConstant : public Expr {
public:
  float val;
  FloatConstant(float);
};

class StrConstant : public Expr {
public:
  std::string* val;
  StrConstant(std::string*);
};

// lvalue: struct, array, var access

class StructAccess : public Expr {
public:
  Expr* base;
  std::string* field;
  StructAccess(Expr*, std::string*);
};

class ArrayAccess : public Expr {
public:
  Expr* base;
  Expr* index;
  ArrayAccess(Expr*, Expr*);
};

class VarAccess : public Expr {
public:
  std::string* name;
  VarAccess(std::string*);
};

// function call
class FunCall : public Expr {
public:
  std::string* name;
  ExprList* actuals;
  FunCall(std::string*, ExprList*);
};

// both an expr and stmt, e.g. x = (y = 1) here y = 1 evaluates to 1
class Assignment : public Expr {
public:
  Expr* lvalue; // must be an lvalue
  Expr* r;
  Assignment(Expr*, Expr*);
};


//------------------------stmts---------------------------
// Use block to indicate the need to enter a scope.. So fundecl, for, while
// all take a block stmt
class Block : public Stmt {
public:
  StmtList* stmts;
  Block(StmtList*);
};

//  if then else
class Ite : public Stmt {
public:
  Expr* condition;
  Stmt* t; // could be a single stmt, or a block stmt that contains stmts
  Stmt* f;
  Ite(Expr*, Stmt*, Stmt*);
};
 
class While : public Stmt {
public:
  Expr* condition;
  Stmt* body;
  While(Expr*, Stmt*);
};

class For : public Stmt {
public:
  Stmt* init;
  Expr* cond;
  Stmt* inc;
  Stmt* body;
  For(Stmt*, Expr*, Stmt*, Stmt*);
};

class Return : public Stmt {
public:
  Expr* exp; // null if it is a void return
  Return(Expr*);
};


//---------------------------declarations----------------------------
class VarDecl : public Stmt {
public:
  std::string* name;
  Type* type;
  Expr* initValue;
  VarDecl(std::string*, Type*, Expr*);
};

class FunDecl : public Stmt {
public:
  std::string* name;
  VarDeclList* formals;
  Type* returnType;
  Stmt* body;
  FunDecl(std::string*, VarDeclList*, Type*, Stmt*);
};

class StructDecl: public Stmt {
public:
  std::string* name;
  VarDeclList* fields;
  StructDecl(std::string*, VarDeclList*);
};


#endif

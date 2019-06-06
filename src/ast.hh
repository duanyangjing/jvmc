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

using StmtList = std::vector<Stmt*>;
using ExprList = std::vector<Expr*>;
using VarDeclList = std::vector<VarDecl*>;
// TODO: better ways to avoid circular dependency?
#include "type.hh"
#include "visitor.hh"
// root of the ast as global var, populated by parser
extern StmtList* ast;


class Stmt : public VisitableNode {};

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
  void accept(Visitor*);
};

// binary operation
class BinaryOperation : public Expr {
public:
  BinaryOperator op;
  Expr* left;
  Expr* right;
  BinaryOperation(BinaryOperator, Expr*, Expr*);
  void accept(Visitor*);
}; 

class IntConstant : public Expr {
public:
  int val;
  IntConstant(int);
  void accept(Visitor*);
};

class CharConstant : public Expr {
public:
  char val;
  CharConstant(char);
  void accept(Visitor*);
};

class FloatConstant : public Expr {
public:
  float val;
  FloatConstant(float);
  void accept(Visitor*);
};

class StrConstant : public Expr {
public:
  std::string* val;
  StrConstant(std::string*);
  void accept(Visitor*);
};

// lvalue: struct, array, var access

class StructAccess : public Expr {
public:
  Expr* base;
  std::string* field;
  StructAccess(Expr*, std::string*);
  void accept(Visitor*);
};

class ArrayAccess : public Expr {
public:
  Expr* base;
  Expr* index;
  ArrayAccess(Expr*, Expr*);
  void accept(Visitor*);
};

class VarAccess : public Expr {
public:
  std::string* name;
  VarAccess(std::string*);
  void accept(Visitor*);
};

// function call
class FunCall : public Expr {
public:
  std::string* name;
  ExprList* actuals;
  FunCall(std::string*, ExprList*);
  void accept(Visitor*);
};

// both an expr and stmt, e.g. x = (y = 1) here y = 1 evaluates to 1
class Assignment : public Expr {
public:
  Expr* lvalue; // must be an lvalue
  Expr* r;
  Assignment(Expr*, Expr*);
  void accept(Visitor*);
};


//------------------------stmts---------------------------
// Use block to indicate the need to enter a scope.. So fundecl, for, while
// all take a block stmt
class Block : public Stmt {
public:
  StmtList* stmts;
  Block(StmtList*);
  void accept(Visitor*);
};

//  if then else
class Ite : public Stmt {
public:
  Expr* condition;
  Stmt* t; // could be a single stmt, or a block stmt that contains stmts
  Stmt* f;
  Ite(Expr*, Stmt*, Stmt*);
  void accept(Visitor*);
};
 
class While : public Stmt {
public:
  Expr* condition;
  Stmt* body;
  While(Expr*, Stmt*);
  void accept(Visitor*);
};

class For : public Stmt {
public:
  Stmt* init;
  Expr* cond;
  Stmt* inc;
  Stmt* body;
  For(Stmt*, Expr*, Stmt*, Stmt*);
  void accept(Visitor*);
};

class Return : public Stmt {
public:
  Expr* exp; // null if it is a void return
  Return(Expr*);
  void accept(Visitor*);
};


//---------------------------declarations----------------------------
class VarDecl : public Stmt {
public:
  std::string* name;
  Type* type;
  Expr* initValue;
  VarDecl(std::string*, Type*, Expr*);
  void accept(Visitor*);
};

class FunDecl : public Stmt {
public:
  std::string* name;
  VarDeclList* formals;
  Type* returnType;
  Stmt* body;
  FunDecl(std::string*, VarDeclList*, Type*, Stmt*);
  void accept(Visitor*);
};

class StructDecl: public Stmt {
public:
  std::string* name;
  VarDeclList* fields;
  StructDecl(std::string*, VarDeclList*);
  void accept(Visitor*);
};


#endif

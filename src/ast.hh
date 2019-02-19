#ifndef _AST_
#define _AST_

#include "common.hh"
#include <vector>
#include "type.hh"
#include <string>

class Statement;
class Expression;
class VariableDeclaration;

typedef std::vector<Statement*> StatementList;
typedef std::vector<Expression*> ExpressionList;
typedef std::vector<VariableDeclaration*> VarDeclList;

// root of the ast, populated by parser
StatementList* ast;

class Expression {};

class Statement {};

//------------------------expressions--------------------
enum UnaryOperator {OP_UMINUS, OP_NOT};
enum BinaryOperator {OP_OR, OP_AND, OP_EQ, OP_NE, OP_LT, OP_LE, OP_GT, OP_GE, 
		     OP_PLUS, OP_MINUS, OP_TIMES, OP_DIVIDE};
    
std::string uopToString(UnaryOperator o);
std::string bopToString(BinaryOperator o); 

// unary operation
class UnaryOperation : public Expression {
public:
  UnaryOperator op;
  Expression* e;
  UnaryOperation(UnaryOperator op, Expression* e);
  std::ostream& operator << (std::ostream& outs, const UnaryOperation& uop);
};

// binary operation
class BinaryOperation : public Expression {
public:
  BinaryOperator op;
  Expression* left;
  Expression* right;
  BinaryOperation(BinaryOperator op, Expression* l, Expression* r):
    op(op), left(l), right(r) {}
}; 

class IntConstant : public Expression {
public:
  int val;
  IntConstant(int v): val(v) {}
};

class CharConstant : public Expression {
public:
  char val;
  CharConstant(char c): val(c) {}
};

class FloatConstant : public Expression {
public:
  float val;
  FloatConstant(float f): val(f) {}
};

class StrConstant : public Expression {
public:
  std::string* val;
  StrConstant(std::string* s): val(s) {}
};

// lvalue: struct, array, var access
class LValue : public Expression {};

class StructAccess : public LValue {
public:
  Expression* base;
  std::string* field; 
  StructAccess(Expression* base, std::string* field): 
    base(base), field(field) {}
};

class ArrayAccess : public LValue {
public:
  Expression* base;
  Expression* index;
  ArrayAccess(Expression* base, Expression* index): 
    base(base), index(index) {}
};

class VariableAccess : public LValue {
public:
  std::string* name;
  VariableAccess(std::string* name): name(name) {}
};

// function call
class FunctionCall : public Expression {
public:
  std::string* name;
  ExpressionList* actuals;
  FunctionCall(std::string* name, ExpressionList* actuals):
    name(name), actuals(actuals) {}
};

// both an expression and statement, e.g. x = (y = 1) here y = 1 evaluates to 1
class Assignment : public Expression, public Statement {
public:
  LValue* lvalue;       
  Expression* r;
  Assignment(LValue* lv, Expression* r): lvalue(lv), r(r) {}
};

class Error : public Expression {};

//------------------------statements---------------------------
class Block : public Statement {
public:
  StatementList* statements;
  Block(StatementList* statements): statements(statements) {}
};

//  if then else
class Ite : public Statement {
public:
  Expression* condition;
  Statement* t; // could be a single statement, or a block statement that contains stmts
  Statement* f;
  Ite(Expression* condition, Statement* t, Statement* f):
    condition(condition), t(t), f(f) {}
};
 
class While : public Statement {
public:
  Expression* condition;
  Statement* body;
  While(Expression* condition, Statement* body): 
    condition(condition), body(body) {}
};

class For : public Statement {
public:
  Statement* init;
  Expression* condition;
  Statement* increment;
  Statement* body;
  For(Statement* init, Expression* condition, Statement* increment, Statement* body):
    init(init), condition(condition), increment(increment), body(body) {}
};

class Return : public Statement {
public:
  Expression* exp; // null if it is a void return
  Return(Expression* e): exp(e) {}
};


//---------------------------declarations----------------------------
class VariableDeclaration : public Statement {
public:
  std::string* name;
  Type* type;
  VariableDeclaration(std::string* name, Type* type):
    name(name), type(type) {}
};

class FunctionDeclaration : public Statement {
public:
  std::string* name;
  VarDeclList* formals;
  Type* returnType;
  StatementList* body;
  FunctionDeclaration(std::string* name, VarDeclList* formals, Type* returnType, StatementList* body):
    name(name), formals(formals), returnType(returnType), body(body) {}
};

class StructDeclaration: public Statement {
public:
  std::string* name;
  VarDeclList* fields;
  StructDeclaration(std::string* name, VarDeclList* fields):
    name(name), fields(fields) {}
}


#endif

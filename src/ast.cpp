#include "ast.hh"
#include <string>
#include <iostream>

std::string UopString[] = {"MINUS", "NOT"};
std::string BopString[] = {"OR", "AND", "EQ", "NE", "LT", "LE", "GT", "GE", "PLUS", "MINUS", "TIMES", "DIV"}; 

std::string uopToString(UnaryOperator o) {
  return UopString[o];
}

std::string bopToString(BinaryOperator o) {
  return BopString[o];
} 

UnaryOperation::UnaryOperation(UnaryOperator op, Expression* e): op(op), e(e) {}
std::ostream& operator << (std::ostream& os, const UnaryOperation& uop) {
  return os << uopToString(uop.op) << "(" << uop.e << ")";
}

BinaryOperation::BinaryOperation(BinaryOperator op, Expression* l, Expression* r):
  op(op), left(l), right(r) {}
std::ostream& operator << (std::ostream& os, const BinaryOperation& bop) {
  return os << bopToString(bop.op) << "(" << bop.left << ", " << bop.right << ")";
}

IntConstant::IntConstant(int val): val(val) {}
std::ostream& operator << (std::ostream& os, const IntConstant& c) {
  return os << "Int(" << c.val << ")";
}

CharConstant::CharConstant(char val): val(val) {}
std::ostream& operator << (std::ostream& os, const CharConstant& c) {
  return os << "Char(" << c.val << ")";
}

FloatConstant::FloatConstant(float val): val(val) {}
std::ostream& operator << (std::ostream& os, const FloatConstant& c) {
  return os << "Float(" << c.val << ")";
}

StrConstant::StrConstant(std::string* val): val(val) {}
std::ostream& operator << (std::ostream& os, const StrConstant& c) {
  return os << "Char(" << c.val << ")";
}

StructAccess::StructAccess(Expression* base, std::string* field): 
  base(base), field(field) {}
std::ostream& operator << (std::ostream& os, const StructAccess& e) {
  return os << "StructAccess(" << e.base << "," << e.field << ")";
}

ArrayAccess::ArrayAccess(Expression* base, Expression* index): 
  base(base), index(index) {}
std::ostream& operator << (std::ostream& os, const ArrayAccess& e) {
  return os << "ArrayAccess(" << e.base << "," << e.index << ")";
}

VariableAccess::VariableAccess(std::string* name): name(name) {}
std::ostream& operator << (std::ostream& os, const VariableAccess& e) {
  return os << "VariableAccess(" << e.name << ")";
}

FunctionCall::FunctionCall(std::string* name, ExpressionList* actuals):
  name(name), actuals(actuals) {}
std::ostream& operator << (std::ostream& os, const FunctionCall& e) {
  os << "FunctionCall(";
  for (auto actual : *e.actuals) {
    os << actual << ",";
  }
}

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
};

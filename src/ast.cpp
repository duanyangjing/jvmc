#include "ast.hh"
#include <string>
#include <iostream>

std::string UopString[] = {"MINUS", "NOT"};
std::string BopString[] = {"OR", "AND", "EQ", "NE", "LT", "LE", "GT", "GE", "PLUS", "MINUS", "TIMES", "DIV", "ASSIGN"}; 

std::string uopToString(UnaryOperator o) {
  return UopString[o];
}

std::string bopToString(BinaryOperator o) {
  return BopString[o];
} 

UnaryOperation::UnaryOperation(UnaryOperator op, Expr* e): op(op), e(e) {}
void UnaryOperation::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const UnaryOperation& uop) {
  return os << uopToString(uop.op) << "(" << uop.e << ")";
}


BinaryOperation::BinaryOperation(BinaryOperator op, Expr* l, Expr* r):
  op(op), left(l), right(r) {}
void BinaryOperation::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const BinaryOperation& bop) {
  return os << bopToString(bop.op) << "(" << bop.left << ", " << bop.right << ")";
}


IntConstant::IntConstant(int val): val(val) {}
void IntConstant::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const IntConstant& c) {
  return os << "Int(" << c.val << ")";
}


CharConstant::CharConstant(char val): val(val) {}
void CharConstant::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const CharConstant& c) {
  return os << "Char(" << c.val << ")";
}


FloatConstant::FloatConstant(float val): val(val) {}
void FloatConstant::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const FloatConstant& c) {
  return os << "Float(" << c.val << ")";
}


StrConstant::StrConstant(std::string* val): val(val) {}
void StrConstant::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const StrConstant& c) {
  return os << "Char(" << c.val << ")";
}


StructAccess::StructAccess(Expr* base, std::string* field): 
  base(base), field(field) {}
void StructAccess::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const StructAccess& e) {
  return os << "StructAccess(" << e.base << "," << e.field << ")";
}


ArrayAccess::ArrayAccess(Expr* base, Expr* index): 
  base(base), index(index) {}
void ArrayAccess::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const ArrayAccess& e) {
  return os << "ArrayAccess(" << e.base << "," << e.index << ")";
}


VarAccess::VarAccess(std::string* name): name(name) {}
void VarAccess::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const VarAccess& e) {
  return os << "VarAccess(" << e.name << ")";
}


FunCall::FunCall(std::string* name, ExprList* actuals):
  name(name), actuals(actuals) {}
void FunCall::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const FunCall& e) {
  os << "FunctionCall(";
  for (auto actual : *e.actuals) {
    os << actual << ",";
  }

  return os;
}


Assignment::Assignment(Expr* lv, Expr* r):
  lvalue(lv), r(r) {}
void Assignment::accept(Visitor* v) {
  v->visit(this);
}


//------------------------stmts---------------------------
Block::Block(StmtList* stmts): stmts(stmts) {}
void Block::accept(Visitor* v) {
  v->visit(this);
}


Ite::Ite(Expr* condition, Stmt* t, Stmt* f):
  condition(condition), t(t), f(f) {}
void Ite::accept(Visitor* v) {
  v->visit(this);
}


While::While(Expr* condition, Stmt* body): 
  condition(condition), body(body) {}
void While::accept(Visitor* v) {
  v->visit(this);
}


For::For(Stmt* init, Expr* cond, Stmt* inc, Stmt* body):
  init(init), cond(cond), inc(inc), body(body) {}
void For::accept(Visitor* v) {
  v->visit(this);
}


Return::Return(Expr* e): exp(e) {}
void Return::accept(Visitor* v) {
  v->visit(this);
}


// std::ostream& operator << (std::ostream& os, const Return& s) {
//   return os << "Return(" << *(s.exp) << ")";
// }

//---------------------------declarations----------------------------
VarDecl::VarDecl(std::string* name, Type* type, Expr* initValue):
    name(name), type(type), initValue(initValue) {}
void VarDecl::accept(Visitor* v) {
  v->visit(this);
}
std::ostream& operator << (std::ostream& os, const VarDecl& s) {
  return os << "VarDecl(" << *(s.name) << ")";
}


FunDecl::FunDecl(std::string* name, VarDeclList* formals, Type* returnType, Stmt* body):
  name(name), formals(formals), returnType(returnType), body(body) {}
void FunDecl::accept(Visitor* v) {
  v->visit(this);
}
// std::ostream& operator << (std::ostream& os, const FunDecl& s) {
//   return os << "FunDecl(" << *(s.name) << ")";
// }


StructDecl::StructDecl(std::string* name, VarDeclList* fields):
  name(name), fields(fields) {}
void StructDecl::accept(Visitor* v) {
  v->visit(this);
}

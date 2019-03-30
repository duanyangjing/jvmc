#ifndef _VISITOR_
#define _VISITOR_

class Visitor;

// forward declarations from ast.hh, used to avoid circular dependency
class UnaryOperation;
class BinaryOperation;
class IntConstant;
class CharConstant;
class FloatConstant;
class StrConstant;
class StructAccess;
class ArrayAccess;
class VarAccess;
class FunCall;
class Assignment;
class Block;
class Ite;
class While;
class For;
class Return;
class VarDecl;
class FunDecl;
class StructDecl;

class VisitableNode {
public:
  // cannot accept Visitor as argument, because it's abstract and cannot be
  // instantiated, but can accept pointer/ref to an abstract class because
  // pointer/ref to derived class are compatible with p/r to base class,
  // thus achieving polymorphism.
  virtual void accept(Visitor*) = 0;
};


class Visitor {
public:
  virtual void visit(UnaryOperation*) = 0;
  virtual void visit(BinaryOperation*) = 0;
  virtual void visit(IntConstant*) = 0;
  virtual void visit(CharConstant*) = 0;
  virtual void visit(FloatConstant*) = 0;
  virtual void visit(StrConstant*) = 0;
  virtual void visit(StructAccess*) = 0;
  virtual void visit(ArrayAccess*) = 0;
  virtual void visit(VarAccess*) = 0;
  virtual void visit(FunCall*) = 0;
  virtual void visit(Assignment*) = 0;
  virtual void visit(Block*) = 0;
  virtual void visit(Ite*) = 0;
  virtual void visit(While*) = 0;
  virtual void visit(For*) = 0;
  virtual void visit(Return*) = 0;
  virtual void visit(VarDecl*) = 0;
  virtual void visit(FunDecl*) = 0;
  virtual void visit(StructDecl*) = 0;
};

  
#endif

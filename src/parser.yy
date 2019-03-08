/* ===== Definition Section ===== */

%skeleton "lalr1.cc" /* -*- C++ -*- */
%defines

/* TODO: api.value.type variant gives type-safe union based on variant might worth refactoring later
%define api.token.constructor
%define api.value.type variant
%define parse.assert 
*/
%define api.namespace {Front}
%define parser_class_name {Parser}


%locations
/* Dependencies of the types defined in union must be included/defined in this section*/
%code requires {
    #include "type.hh"
    namespace Front {
	class Scanner;
	class Parser;
    }
}

%parse-param {Scanner* scanner}

%code {
    #include <string>
    #include "ast.hh"
    #include "type.hh"
    #include "parser.tab.hh"
    #include "driver.hh"

}

/*			%define api.token.prefix {TOK_} */
		       
%union {
    std::string* string;
    Expression* expr;
    ExpressionList* exprs;
    Statement* stmt;
    StatementList* stmts;
    Type* type;
    VarDeclList* vdecs;
    VariableDeclaration* vdec;
}

/* terminal symbols. Type represents the object the lexer/parser builds for the token */

%token <string> ID INTCONST FLTCONST CHRCONST STRCONST
%token VOID INT CHAR FLOAT
%token IF ELSE WHILE FOR
%token STRUCT
%token ASSIGN
%token OR AND NOT EQ NE GT LT GE LE PLUS MINUS TIMES DIVIDE
%token LB RB LPAREN RPAREN LBRACE RBRACE
%token COMMA SEMICOLON DOT
%token ERROR
%token RETURN


/* non-terminals, type represents the object parser builds for this non-terminal */
%type <expr> const var_ref function_call
%type <expr> init_array_dim init_expr init_expr1 init_expr2 init_expr3
%type <expr> funparam_array_dim_first
%type <expr> expr expr1 expr2 expr3 expr4 expr5 expr6 expr7 expr8

%type <stmts> stmts program global_decl_list 
%type <stmt> global_decl var_decl var_decl_init struct_decl function_decl
%type <stmt> stmt ite_stmt loop_stmt assign_stmt return_stmt stmt_block

%type <type> primitive_type compound_type

%type <vdecs> var_decl_list fun_decl_params
%type <exprs> init_array_dims fun_call_params funparam_array_dims funparam_array_dim_rest

%type <vdec> fun_decl_param
			
%start program

%%

program: global_decl_list {ast = $1;}
       ;

global_decl_list: global_decl {$$ = new std::vector<Statement*>(); $$->push_back($1);}
                | global_decl_list global_decl {$1->push_back($2); $$ = $1;}
                ;

global_decl: var_decl {$$ = $1;}
           | var_decl_init {$$ = $1;} /* treated as statement list, decl followed by assignment */
           | struct_decl {$$ = $1;}
           | function_decl {$$ = $1;}
           ;

/* no multiple declarations like int x,y,z */
var_decl: primitive_type ID SEMICOLON {$$ = new VariableDeclaration($2, $1);}
        | compound_type ID SEMICOLON {$$ = new VariableDeclaration($2, $1);}
        | primitive_type ID init_array_dims SEMICOLON 
          {
              $1.setDimensions($3);
              $$ = new VariableDeclaration($2, $1);
          }
        | compound_type ID init_array_dims SEMICOLON 
          {
              $1.setDimensions($3);
              $$ = new VariableDeclaration($2, $1);
          }
        ;
        
/* no init for compound var declarations*/
var_decl_init: primitive_type ID ASSIGN const
  {
      Statement* decl = new VariableDeclaration($2, $1);
      Statement* assign = new Assignment(new VariableAccess($2), $4);
      /* TODO: dynamic or stack allocation? */
      StatementList* block = new std::vector<Statement*>(2);
      block->push_back(decl);
      block->push_back(assign); 
      $$ = new Block(block);
  }

const: INTCONST {$$ = new IntConstant(std::stoi($1));} 
     | FLTCONST {$$ = new FloatConstant(std::stof($1));}
     | CHRCONST {$$ = new CharConstant($1[0]);}
     | STRCONST {$$ = new StrConstant($1);}
     ;

primitive_type: INT {$$ = new Type(I);} 
              | FLOAT {$$ = new Type(F);}
              | CHAR {$$ = new Type(C);}
              ;

/* struct and union 
   struct S name; 
   
   no struct definition followed by id
   struct S {
     int x;
   } s 
   
   no syntactic sugar like above for now */
compound_type: STRUCT ID {$$ = new Type($2);}
             ;

/* No annoymous struct for now */
struct_decl: STRUCT ID LBRACE var_decl_list RBRACE SEMICOLON 
             {
                 $$ = new StructDeclaration($2, $4);
             }
           ;

var_decl_list: var_decl 
               {
                   $$ = new std::vector<VariableDeclaration*>(1);
                   $$->push_back($1);
               }
             | var_decl_list var_decl {$1->push_back($2);$$ = $1;}
             ;


init_array_dims: init_array_dims init_array_dim
                 {
                     $1->push_back($2);
                     $$ = $1;
                 }
               | init_array_dim 
                 {
                     $$ = new vector<Expression*>();
                     $$->push_back($1);
                 }
               ;

init_array_dim: LB init_expr RB {$$ = $2;}

/* exprs that can be evaluated at compile time, needed for array dim initialization */
init_expr: init_expr1 {$$ = $1;}
         ;
init_expr1: init_expr1 PLUS init_expr2 {$$ = new BinaryOperation(OP_PLUS, $1, $3);}
          | init_expr1 MINUS init_expr2 {$$ = new BinaryOperation(OP_MINUS, $1, $3);;}
          | init_expr2 {$$ = $1;}
          ;
init_expr2: init_expr2 TIMES init_expr3 {$$ = new BinaryOperation(OP_TIMES, $1, $3);;}
          | init_expr2 DIVIDE init_expr3 {$$ = new BinaryOperation(OP_DIVIDE, $1, $3);;}
          | init_expr3 {$$ = $1;}
          ;
/* size of array has to be constant, cannot be var_ref or funtion call */
init_expr3: LPAREN init_expr RPAREN {$$ = $2;}
          | const {$$ = $1;}
          ;

/* lvalue
   x = 1;              var
   x[10] = 1;          arr
   x[10].y = 1;        struct arr, var field
   (x[10].y)[10] = 1;  struct arr, arr field */
var_ref: ID {$$ = new VariableAccess($1);}
       | var_ref LB expr RB {$$ = new ArrayAccess($1, $3);}
       | var_ref DOT ID {$$ = new StructAccess($1, $3);}
       ;

/* all possible exprs */
expr: expr ASSIGN expr1 
    | expr1 {$$ = $1;}
    ;
expr1: expr1 OR expr2 {$$ = new BinaryOperation(OP_OR, $1, $3);}
     | expr2 {$$ = $1;}
     ;
expr2: expr2 AND expr3 {$$ = new BinaryOperation(OP_AND, $1, $3);} 
     | expr3 {$$ = $1;}
     ;
expr3: expr3 EQ expr4 {$$ = new BinaryOperation(OP_EQ, $1, $3);}
     | expr3 NE expr4 {$$ = new BinaryOperation(OP_NE, $1, $3);}
     | expr4 {$$ = $1;}
     ;
expr4: expr4 LE expr5 {$$ = new BinaryOperation(OP_LE, $1, $3);}
     | expr4 GE expr5 {$$ = new BinaryOperation(OP_GE, $1, $3);}
     | expr4 LT expr5 {$$ = new BinaryOperation(OP_LT, $1, $3);}
     | expr4 GT expr5 {$$ = new BinaryOperation(OP_GT, $1, $3);}
     | expr5 {$$ = $1;}
     ;
expr5: expr5 PLUS expr6 {$$ = new BinaryOperation(OP_PLUS, $1, $3);}
     | expr5 MINUS expr6 {$$ = new BinaryOperation(OP_MINUS, $1, $3);}
     | expr6 {$$ = $1;}
     ;
expr6: expr6 TIMES expr7 {$$ = new BinaryOperation(OP_TIMES, $1, $3);}
     | expr6 DIVIDE expr7 {$$ = new BinaryOperation(OP_DIVIDE, $1, $3);}
     | expr7 {$$ = $1;}
     ;
expr7: NOT expr8 {$$ = new UnaryOperation(OP_NOT, $2);}
     | MINUS expr8 {$$ = new UnaryOperation(OP_MINUS, $2);}
     | expr8 {$$ = $1;}
     ;
/* expr can be anything */
expr8: LPAREN expr RPAREN {$$ = $2;}
     | const {$$ = $1;}
     | var_ref {$$ = $1;}
     | function_call {$$ = $1;}
     ;

function_call: ID LPAREN RPAREN {$$ = new FunctionCall($1, nullptr);}
             | ID LPAREN fun_call_params RPAREN {$$ = new FunctionCall($1, $3);}
             ;

/* fun param can be any expr, static or dynamic */
fun_call_params: expr {$$ = new std::vector<Expression*>(); $$->push_back($1);}
               | fun_call_params COMMA expr {$1->push_back($3); $$ = $1;}
               ; 

function_decl: primitive_type ID LPAREN fun_decl_params RPAREN SEMICOLON 
               {
                   $$ = new FunctionDeclaration($2, $4, $1, nullptr);
               }
             | primitive_type ID LPAREN fun_decl_params RPAREN LBRACE stmts RBRACE
               {
                   $$ = new FunctionDeclaration($2, $4, $1, $7);
               }
             | VOID ID LPAREN fun_decl_params RPAREN SEMICOLON
               {
                   $$ = new FunctionDeclaration($2, $4, new Type(V), nullptr);
               }
             | VOID ID LPAREN fun_decl_params RPAREN LBRACE stmts RBRACE
               {
                   $$ = new FunctionDeclaration($2, $4, new Type(V), $7);
               }
             | VOID ID LPAREN fun_decl_params RPAREN LBRACE RBRACE {}
             ;

/* int foo(int x, int y)
   int foo(int x[10])
   int foo(int x[][10]*/
fun_decl_params: {$$ = new std::vector<VariableDeclaration*>();}
               | fun_decl_params COMMA fun_decl_param {$$->push_back($3); $$ = $1;}
               | fun_decl_param 
                 {
                     $$ = new std::vector<VariableDeclaration*>(); 
                     $$->push_back($1);
                 }
               ;

fun_decl_param: primitive_type ID {$$ = new VariableDeclaration($2, $1);}
              | primitive_type ID funparam_array_dims 
                {
                    $1->setDimensions($3);
                    $$ = new VariableDeclaration($2, $1);
                }
              ;

/* first row dimension can be empty */
funparam_array_dims: funparam_array_dim_first funparam_array_dim_rest {$2->push_front($1); $$ = $2;}
                   ;

funparam_array_dim_first: LB RB {$$ = nullptr;}
                        | LB init_expr RB {$$ = $2;}
                        ;

funparam_array_dim_rest: LB init_expr RB {$$ = new std::vector<Expression*>(); $$->push_back($2);}
                       | funparam_array_dim_rest LB init_expr RB {$1->push_back($3); $$ = $1;}
                       | {$$ = new std::vector<Expression*>();}
                       ;

/* statements might be grouped by arbitrary blocks */
stmts: stmts stmt {$1->push_back($2); $$ = $1;}
     | stmt {$$ = std::vector<Statement*>(); $$->push_back($1);}
     ;

stmt: assign_stmt {$$ = $1;}
    | function_call SEMICOLON {$$ = $1;}
    | ite_stmt {$$ = $1;}
    | loop_stmt {$$ = $1;}
    | return_stmt {$$ = $1;}
    | var_decl {$$ = $1;}/* TODO: are decls statements? */
    | struct_decl {$$ = $1;}
    | SEMICOLON {$$ = nullptr;} /* empty stmt */
    | LBRACE stmts RBRACE {$$ = new Block($2);} /* arbitrary braces */
    ;

/* no fancy assignments like 
   x += 1; x++; x=y=z*/
assign_stmt: var_ref ASSIGN expr SEMICOLON {$$ = new Assignment($1, $3);}
           ; 

/* no if...else if... according to specification */
/* TODO: need to support single statement if else body*/
ite_stmt: IF LPAREN expr RPAREN stmt_block {$$ = new Ite($3, $5, nullptr);}
        | IF LPAREN expr RPAREN stmt_block ELSE stmt_block {$$ = new Ite($3, $5, $7);}
        ;

stmt_block: LBRACE stmts RBRACE {$$ = new Block($2);}
	  ;

/* looks like C allows anything in these places, even statements in for_cond */
loop_stmt: FOR LPAREN stmt SEMICOLON expr SEMICOLON stmt RPAREN stmt_block
           {
               $$ = new For($3, $5, $7, $9);
           }
         | WHILE LPAREN expr RPAREN stmt_block {$$ = new While($3, $5);}
         ;

return_stmt: RETURN SEMICOLON {$$ = new Return(nullptr);}
           | RETURN expr SEMICOLON {$$ = new Return($2);}
	   ;

%%

void
Front::Parser::error (const location_type& l, const std::string& m)
{
    std::cerr << l << " Error: " << m << '\n';
}

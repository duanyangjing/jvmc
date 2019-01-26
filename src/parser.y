/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static int linenumber = 1;
%}


%token ID
%token CONST
%token VOID
%token INT
%token CHAR
%token FLOAT
%token IF
%token ELSE
%token WHILE
%token FOR
%token STRUCT
%token ASSIGN
%token OR
%token AND
%token NOT
%token EQ
%token NE
%token GT
%token LT
%token GE
%token LE
%token PLUS
%token MINUS
%token TIMES
%token DIVIDE
%token LB
%token RB
%token LPAREN
%token RPAREN
%token LBRACE
%token RBRACE
%token COMMA
%token SEMICOLON
%token DOT
%token ERROR
%token RETURN

%start program

%%

/* ==== Grammar Section ==== */

/* Productions */               /* Semantic actions */
program: global_decl_list
       ;

global_decl_list: global_decl_list global_decl
                | 
                ;

global_decl: var_decl
           | var_decl_init
           | struct_decl
           | function_decl
           ;

/* no multiple declarations like: int x,y,z */
var_decl: primitive_type ID SEMICOLON
        | compound_type ID SEMICOLON
        | primitive_type ID init_array_dims SEMICOLON
        | compound_type ID init_array_dims SEMICOLON
        ;
        
/* no init for compound var declarations*/
var_decl_init: primitive_type ID ASSIGN CONST;

primitive_type: INT | FLOAT | CHAR;

/* struct and union 
   struct S name; 
   
   no struct definition followed by id
   struct S {
     int x;
   } s 
   
   no syntactic sugar like above for now */
compound_type: STRUCT ID;

/* No annoymous struct for now */
struct_decl: STRUCT ID LBRACE struct_body RBRACE SEMICOLON;

/* struct fields cannot be initialized together with decl */
struct_body: var_decl;

init_array_dims: init_array_dims init_array_dim
               | init_array_dim
               ;

init_array_dim: LB init_expr RB;

/* exprs that can be evaluated at compile time, needed for array dim initialization */
init_expr: init_expr OR init_expr1 | init_expr1;
init_expr1: init_expr1 AND init_expr2 | init_expr2;
init_expr2: init_expr2 EQ init_expr3
          | init_expr2 NE init_expr3
          | init_expr3
          ;
init_expr3: init_expr3 LE init_expr4
          | init_expr3 GE init_expr4
          | init_expr3 LT init_expr4
          | init_expr3 GT init_expr4
          | init_expr4
          ;
init_expr4: init_expr4 PLUS init_expr5
          | init_expr4 MINUS init_expr5
          | init_expr5
          ;
init_expr5: init_expr5 TIMES init_expr6
          | init_expr5 DIVIDE init_expr6
          | init_expr6
          ;
init_expr6: NOT init_expr7 | MINUS init_expr7 | init_expr7;
/* size of array has to be constant, cannot be var_ref or funtion call */
init_expr7: LPAREN init_expr RPAREN
          | CONST
          ;

/* lvalue
   x = 1;              var
   x[10] = 1;          arr
   x[10].y = 1;        struct arr, var field
   (x[10].y)[10] = 1;  struct arr, arr field */
var_ref: ID
       | var_ref varref_array_dims
       | var_ref DOT ID
       ;

varref_array_dims: varref_array_dims varref_array_dim
                 | varref_array_dim
                 ;

varref_array_dim: LB expr RB;

/* all possible exprs */
expr: expr ASSIGN expr1 | expr1;
expr1: expr1 OR expr2 | expr2;
expr2: expr2 AND expr3 | expr3;
expr3: expr3 EQ expr4
     | expr3 NE expr4
     | expr4
     ;
expr4: expr4 LE expr5
     | expr4 GE expr5
     | expr4 LT expr5
     | expr4 GT expr5
     | expr5
     ;
expr5: expr5 PLUS expr6
     | expr5 MINUS expr6
     | expr6
     ;
expr6: expr6 TIMES expr7
     | expr6 DIVIDE expr7
     | expr7
     ;
expr7: NOT expr8 | MINUS expr8 | expr8;
/* expr can be anything */
expr8: LPAREN expr RPAREN
     | CONST
     | var_ref
     | function_call
     ;

function_call: ID LPAREN RPAREN
             | ID LPAREN fun_call_params RPAREN
             ;

/* fun param can be any expr, static or dynamic */
fun_call_params: expr
               | 
               | fun_call_params COMMA expr
               ; 

function_decl: primitive_type ID LPAREN fun_decl_params RPAREN SEMICOLON
             | primitive_type ID LPAREN fun_decl_params RPAREN LBRACE stmts RBRACE
             | VOID ID LPAREN fun_decl_params RPAREN SEMICOLON /* no function body */
             | VOID ID LPAREN fun_decl_params RPAREN LBRACE stmts RBRACE
             | VOID ID LPAREN fun_decl_params RPAREN LBRACE RBRACE /* empty function body*/
             ;

/* int foo(int x, int y)
   int foo(int x[10])
   int foo(int x[][10]*/
fun_decl_params:
               | fun_decl_params COMMA fun_decl_param 
               | fun_decl_param
               ;

fun_decl_param: primitive_type ID
              | primitive_type ID funparam_array_dims
              ;

/* first row dimension can be empty */
funparam_array_dims: funparam_array_dim_first funparam_array_dim_rest
                   ;

funparam_array_dim_first: LB RB
                        | LB init_expr RB 
                        ;

funparam_array_dim_rest: LB init_expr RB
                       | funparam_array_dim_rest LB init_expr RB
                       |
                       ;

/* statements might be grouped by arbitrary blocks */
stmts: stmts stmt
     | stmt
     ;

stmt: assign_stmt
    | function_call SEMICOLON
    | ite_stmt 
    | loop_stmt
    | return_stmt
    | var_decl /* TODO: are decls statements? */
    | struct_decl
    | SEMICOLON /* empty stmt */
    | LBRACE stmt RBRACE /* arbitrary braces */
    ;

/* no fancy assignments like 
   x += 1; x++; x=y=z*/
assign_stmt: var_ref OP_ASSIGN expr SEMICOLON; 

/* no if...else if... according to specification */
ite_stmt: IF LPAREN expr RPAREN stmt_block
        | IF LPAREN expr RPAREN stmt_block ELSE stmt_block
        ;

stmt_block: stmt
          | LBRACE stmts RBRACE
		      ;

loop_stmt: FOR LPAREN for_init SEMICOLON for_cond SEMICOLON for_inc RPAREN stmt_block
         | WHILE LPAREN expr RPAREN stmt_block
         ;

/* looks like C allows anything in these places, even statements in for_cond */
for_init: expr;
for_cond: expr;
for_inc: expr;

return_stmt: RETURN SEMICOLON
           | RETURN expr SEMICOLON
		       ;

%%

#include "lex.yy.c"
main (argc, argv)
int argc;
char *argv[];
{
	yyin = fopen(argv[1],"r");
	yyparse();
	printf("%s\n", "Parsing completed. No errors found.");
} 


yyerror (mesg)
char *mesg;
{
    printf("%s\t%d\t%s\t%s\n", "Error found in Line ", linenumber, "next token: ", yytext );
    printf("%s\n", mesg);
      //exit(1);
}
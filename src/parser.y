/* ===== Definition Section ===== */

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "type.h"
#include "absyn.h"
#include "symboltable.h"
#include "util/list.h"
#include "parser.h"
#include "stdbool.h"

static int linenumber = 1;
static int tokens = 0;
int scope = 0;
int err = 0;
// if a scope is a struct block
// when lexer sees a struct at a scope, next scope is set to a struct block
bool structblock[MAX_SCOPE];
bool temperr = false;
 
%}

%union {
	struct ABS_expr *expr;
	struct ABS_stmt *stmt;
	struct TY_type *type;
	char str[32];
	// list<init_id>
	struct list *idlist;
	// list<expr>
	struct list *dimlist;
	// list<vardec>
	struct list *vardeclist;
	// list<vardec>
	struct list *paramlist;
	// list<stmt>
	struct list *stmtlist;
	struct init_id *init_id;
	struct structtype *structtype;
	struct vardec *param;
	// list<expr>
	struct list *exprlist;
}

%type <expr> mcexpr cexpr cfactor var_ref expr term factor relop_expr relop_term
             relop_factor assign_expr expr_null
%type <type> type tag struct_type
%type <idlist> init_id_list id_list
%type <dimlist> dim_decl dim_fn dimfn1
%type <init_id> init_id id
%type <vardeclist> var_decl decl decl_list
%type <paramlist> param_list
%type <param> param 
%type <stmt> stmt
%type <stmtlist> stmt_list block
%type <exprlist> relop_expr_list nonempty_relop_expr_list


%token <str> ID
%token <expr> CONST
%token VOID    
%token INT     
%token FLOAT   
%token IF      
%token ELSE    
%token WHILE   
%token FOR
%token STRUCT  
%token TYPEDEF 
%token OP_ASSIGN  
%token OP_OR   
%token OP_AND  
%token OP_NOT  
%token OP_EQ   
%token OP_NE   
%token OP_GT   
%token OP_LT   
%token OP_GE   
%token OP_LE   
%token OP_PLUS 
%token OP_MINUS        
%token OP_TIMES        
%token OP_DIVIDE       
%token MK_LB 
%token MK_RB 
%token MK_LPAREN       
%token MK_RPAREN       
%token MK_LBRACE       
%token MK_RBRACE       
%token MK_COMMA        
%token MK_SEMICOLON    
%token MK_DOT  
%token ERROR
%token RETURN

%start program

%%

/* ==== Grammar Section ==== */

/* Productions */               /* Semantic actions */
program		: global_decl_list
		;

global_decl_list: global_decl_list global_decl
                |
		;

global_decl	: decl_list function_decl
		| function_decl
		;

function_decl : type ID MK_LPAREN param_list MK_RPAREN MK_LBRACE block MK_RBRACE
                {
				    checkfunret($1, $7, scope + 1);
				    enterfundec($2, $1, $4);
					ST_cleanSymtab(scope + 1);
				}
		/* | Other function_decl productions */
                /*Empty parameter list.*/
		      | type ID MK_LPAREN MK_RPAREN MK_LBRACE block MK_RBRACE
		        {
					checkfunret($1, $6, scope + 1);
			        enterfundec($2, $1, NULL);
					ST_cleanSymtab(scope + 1);
		        }
                /*Function declarations. The above ones are function definitions*/
		      | type ID MK_LPAREN param_list MK_RPAREN MK_SEMICOLON
		        {
					enterfundec($2, $1, $4);
		        }
              | type ID MK_LPAREN MK_RPAREN MK_SEMICOLON
			    {
					enterfundec($2, $1, NULL);
				}
		      ;

param_list : param_list MK_COMMA param {LST_add($1, (void *)$3); $$ = $1;}
           | param {$$ = LST_init(); LST_add($$, (void *)$1);}
		   ;

param : type ID {$$ = vardec($1, $2); ST_mkVardec($2, scope + 1, $1);}
	  | struct_type ID {$$ = vardec($1, $2); ST_mkVardec($2, scope + 1, $1);}
	  | type ID dim_fn {TY_setDim($1, $3); $$ = vardec($1, $2); ST_mkVardec($2, scope + 1, $1);}
	  | struct_type ID dim_fn {TY_setDim($1, $3); $$ = vardec($1, $2); ST_mkVardec($2, scope + 1, $1);}
	  ;

/* dimfn1 could be NULL, in that case dim_fn is null, list add directly returns*/
dim_fn : MK_LB expr_null MK_RB dimfn1
         {
			 // add at head so that first dim is at front
			 LST_addfront($4, (void *)$2);
			 $$ = $4;
		 }
       ; 

dimfn1 : dimfn1 MK_LB expr MK_RB {LST_add($1, (void *)$3); $$ = $1;}
/*       | MK_LB expr MK_RB {$$ = LST_init(); LST_add($$, (void *)$2);}*/
       | {$$ = LST_init();}
	   ;

expr_null : expr {$$ = $1;}
          | {$$ = NULL;}
		  ;

block : decl_list stmt_list {$$ = $2;} 
      | stmt_list {$$ = $1;}
      | decl_list
      |
      ;
 
decl_list : decl_list decl
            {
				if (structblock[scope]) {					
					// merge two list
					struct lnode *n = $2->dummy->next;
					for (int i = 0; i < LST_size($2); i++) {
						LST_add($1, (void *)((struct vardec *)n->data));
						n = n->next;
					}
					$$ = $1;
				} else {
					$$ = NULL;
				}
			}
          | decl
		    {
				// decl is already a list
				if (structblock[scope]) {
					$$ = LST_init();
					struct lnode *n = $1->dummy->next;
					for (int i = 0; i < LST_size($1); i++) {
						LST_add($$, (void *)((struct vardec *)n->data));
						n = n->next;
					}
				}
				else $$ = NULL;
			}
		  ;

decl : type_decl
     | var_decl {$$ = $1;}
	 ;

type_decl : TYPEDEF type id_list MK_SEMICOLON
		  | TYPEDEF VOID id_list MK_SEMICOLON
		  | TYPEDEF struct_type id_list MK_SEMICOLON
          | struct_type MK_SEMICOLON
            {
				ST_mkStruct($1->structinfo->structname, scope, $1);
            }
		  ;

var_decl : type init_id_list MK_SEMICOLON
           {
			   if (structblock[scope]) {
				   // check duplicates when later all the struct fields are collected.
				   $$ = initidlist_to_vardeclist($2, $1);
			   } else {
				   initidlist_to_symtab($2, $1, scope);
				   $$ = NULL;
			   }
		   }
		 | struct_type id_list MK_SEMICOLON
		   {
			   if (structblock[scope]) {
				   // TODO: Does a struct S inside a struct need to be saved?
				   
				   $$ = initidlist_to_vardeclist($2, $1); 
			   } else {
				   ST_mkStruct($1->structinfo->structname, scope, $1);
				   initidlist_to_symtab($2, $1, scope);
				   $$ = NULL;
			   }
				   
		   }
		 | ID id_list MK_SEMICOLON 
		 ;

/* Suppported types. */
type	: INT {$$ = TY_mkInt();}
        | FLOAT {$$ = TY_mkFloat();}
        | VOID {$$ = TY_mkVoid();}
        | error
		;

struct_type	: STRUCT tag {$$ = $2;}
		    ;

/* Struct variable body. */
tag : ID MK_LBRACE decl_list MK_RBRACE
      {
		  check_structdecl($1, $3);
		  $$ = TY_mkStruct($1, $3);
		  // when reducing to this rule, have parsed everything till rbrace
		  // scope has already be decremented, reset the scope inside the brace to
		  // non-structblock for future use.
		  structblock[scope + 1] = false;
	  }
    | MK_LBRACE decl_list MK_RBRACE
	  {
		  check_structdecl("", $2);
		  $$ = TY_mkStruct("", $2);
		  structblock[scope + 1] = false;
	  }
    | ID MK_LBRACE MK_RBRACE
    | MK_LBRACE MK_RBRACE
    | ID
	  {
		  // some other struct before, need to query symtab, but
		  // TODO: it's possible that the parent struct is not constructed yet.
		  if (structblock[scope]) {
			  $$ = TY_mkStruct($1, NULL);
		  } else {
			  ST_symnodeptr n = ST_lookup($1, scope, STRUCTURE);
			  if (n == NULL) {
				  yyerror("");
				  printf("Structure '%s' not defined.\n", $1);
			  } else {
				  $$ = n->type.structtype;
			  }
			  
		  }
		  
	  }
    ;


id_list	: ID
          {
			  $$ = LST_init();
			  LST_add($$, (void *)initid($1, NULL));
          }
		| id_list MK_COMMA ID
		  {
			  LST_add($1, (void *)initid($3, NULL));
			  $$ = $1;
		  }
		| id_list MK_COMMA ID dim_decl
		  {
			  LST_add($1, (void *)initid($3, $4));
			  $$ = $1;
		  }
		| ID dim_decl
		  {
			  $$ = LST_init();
			  LST_add($$, (void *)initid($1, $2));
		  }	 
		;

dim_decl: MK_LB cexpr MK_RB
		  {
			  if (!TY_isInt(TY_check($2, scope))) {
				  yyerror("");
				  printf("Array subscript is not an integer.\n");
				  $$ = NULL;
			  }
			  $$ = LST_init();
			  LST_add($$, (void *)$2);
		  }
		| dim_decl MK_LB cexpr MK_RB
		  {
			  LST_add($1, (void *)$3);
			  $$ = $1;
		  }
		;
cexpr : cexpr OP_PLUS mcexpr
        {
			if ($1 != NULL && $3 != NULL) {
				if ($1->type == LVAL_VAR && $3->type == LVAL_VAR) {
					type ltype = TY_check($1, scope);
					type rtype = TY_check($3, scope);
					if (ltype->basetype == TY_STRUCT || rtype->basetype == TY_STRUCT) {
						yyerror("");
						printf("Invalid operands to +\n");
					}
			   
				}
			}
			$$ = ABS_mkBinop($1, $3, ADD);
		}
      | cexpr OP_MINUS mcexpr {$$ = ABS_mkBinop($1, $3, SUB);}
      | mcexpr {$$ = $1;}
	  ;  
mcexpr : mcexpr OP_TIMES cfactor {$$ = ABS_mkBinop($1, $3, MULT);}
       | mcexpr OP_DIVIDE cfactor {$$ = ABS_mkBinop($1, $3, DIV);}
       | cfactor {$$ = $1;}
	   ;

cfactor : CONST {$$ = $1;}
        | MK_LPAREN cexpr MK_RPAREN {$$ = $2;}
		;

init_id_list : init_id
               {
				   // int x, y[10], z[10][10]
				   $$ = LST_init();
				   LST_add($$, (void *)$1);
			   }
             | init_id_list MK_COMMA init_id
			   {
				   LST_add($1, (void *)$3);
				   $$ = $1;
			   }
		     ;

init_id	: ID
          {
	      // init_id_info stores the name and dimension info, dimension is used later
 	      // to distinguish a symbol table entry is an array
	          $$ = initid($1, NULL);
          }
		| ID dim_decl
          {
			  $$ = initid($1, $2);
	
          }
		| ID OP_ASSIGN relop_expr
		  {
			  $$ = initid($1, NULL);
		  }
		;

stmt_list : stmt_list stmt
            {
				if ($2 != NULL) LST_add($1, (void *)$2);
				$$ = $1;
			}
          | stmt
		    {
				$$ = LST_init();
				if ($1 != NULL) LST_add($$, (void *)$1);
			}
		  ;

stmt : MK_LBRACE block MK_RBRACE {$$ = NULL;}
	 /* | While Statement here */
	 | WHILE MK_LPAREN relop_expr_list MK_RPAREN stmt {$$ = NULL;}
	 | FOR MK_LPAREN assign_expr_list MK_SEMICOLON relop_expr_list MK_SEMICOLON assign_expr_list MK_RPAREN stmt {$$ = NULL;}
	 /* | If then else here */ 
	 | IF MK_LPAREN relop_expr MK_RPAREN stmt ELSE stmt {$$ = NULL;}
	 /* | If statement here */ 
	 | IF MK_LPAREN relop_expr MK_RPAREN stmt {$$ = NULL;}
	 /* | read and write library function calls -- note that read/write are not keywords */ 
	 | ID MK_LPAREN relop_expr_list MK_RPAREN
	   {
		   checkfunargs($1, $3, scope);
		   $$ = NULL;
	   }
	 | var_ref OP_ASSIGN relop_expr MK_SEMICOLON 
       {
		   expr e1= $1; expr e3 = $3;
		   if ($1 != NULL && $3 != NULL) {
			   if ($1->type == LVAL_VAR && $3->type == LVAL_VAR) {
				   type ltype = TY_check($1, scope);
				   type rtype = TY_check($3, scope);
				   if (strcmp(TY_getStructname(ltype), TY_getStructname(rtype)) != 0) {
					   yyerror("");
					   printf("Incompatiable type\n");
				   }
			   }
		   }
		   check_arraydim($1, scope);
		   check_structref($1, scope, &temperr);
		   $$ = NULL;
	   }
	 | relop_expr_list MK_SEMICOLON {$$ = NULL;}
	 | MK_SEMICOLON {$$ = NULL;}
	 | RETURN MK_SEMICOLON {$$ = ABS_mkRet(NULL);}
     | RETURN relop_expr MK_SEMICOLON {$$ = ABS_mkRet($2);}
	 ;
/* only used in for loop */
assign_expr_list : nonempty_assign_expr_list
                 |
                 ;

nonempty_assign_expr_list        : nonempty_assign_expr_list MK_COMMA assign_expr
                | assign_expr

assign_expr     : ID OP_ASSIGN relop_expr  {$$ = ABS_mkBinop($1, $3, ASSIGN);} 
                | relop_expr  {$$ = $1;}

relop_expr : relop_term {$$ = $1;}
           | relop_expr OP_OR relop_term {$$ = ABS_mkBinop($1, $3, OR);}
		   ;

relop_term : relop_factor {$$ = $1;}
           | relop_term OP_AND relop_factor {$$ = ABS_mkBinop($1, $3, AND);}
		   ;

relop_factor : expr {$$ = $1;}
             | expr OP_LT expr {$$ = ABS_mkBinop($1, $3, LT);}
             | expr OP_LE expr {$$ = ABS_mkBinop($1, $3, LE);}
             | expr OP_GT expr {$$ = ABS_mkBinop($1, $3, GT);}
             | expr OP_GE expr {$$ = ABS_mkBinop($1, $3, GE);}
             | expr OP_EQ expr {$$ = ABS_mkBinop($1, $3, EQ);}
             | expr OP_NE expr {$$ = ABS_mkBinop($1, $3, NE);}
		     ;

relop_expr_list	: nonempty_relop_expr_list {$$ = $1;} 
                | {$$ = NULL;}
		        ;

nonempty_relop_expr_list : nonempty_relop_expr_list MK_COMMA relop_expr
                           {LST_add($1, (void *)$3); $$ = $1;}
                         | relop_expr {$$ = LST_init(); LST_add($$, $1);}
		                 ;

expr : expr OP_PLUS term
       {
		   if ($1 != NULL && $3 != NULL) {   
			   if ($1->type == LVAL_VAR && $3->type == LVAL_VAR) {
				   type ltype = TY_check($1, scope);
				   type rtype = TY_check($3, scope);
				   if (ltype->basetype == TY_STRUCT || rtype->basetype == TY_STRUCT) {
					   yyerror("");
					   printf("Invalid operands to +\n");
				   }
			   
			   }
		   }
		   $$ = ABS_mkBinop($1, $3, ADD);
	   }
     | expr OP_MINUS term {$$ = ABS_mkBinop($1, $3, SUB);}
	 | term {$$ = $1;}
	 ;

term : term OP_TIMES factor {$$ = ABS_mkBinop($1, $3, MULT);}
     | term OP_DIVIDE factor {$$ = ABS_mkBinop($1, $3, DIV);}
	 | factor {$$ = $1;}
	 ;

factor : MK_LPAREN relop_expr MK_RPAREN {$$ = $2;}
	   /* | -(<relop_expr>) */ 
       | OP_NOT MK_LPAREN relop_expr MK_RPAREN {$$ = ABS_mkUnaryop($3, NOT);}
       /* OP_MINUS condition added as C could have a condition like: "if(-(i < 10))".	*/		
       | OP_MINUS MK_LPAREN relop_expr MK_RPAREN {$$ = ABS_mkUnaryop($3, UMINUS);}
       | CONST {$$ = $1;}
	   /* | - constant, here - is an Unary operator */ 
	   | OP_NOT CONST  {$$ = ABS_mkUnaryop($2, NOT);}
       /*OP_MINUS condition added as C could have a condition like: "if(-10)".	*/		
	   | OP_MINUS CONST {$$ = ABS_mkUnaryop($2, UMINUS);}
       /* Function call */
	   | ID MK_LPAREN relop_expr_list MK_RPAREN
	     {
			 checkfunargs($1, $3, scope);
			 $$ = ABS_mkFuncall($1, $3);
		 }
	   /* | - func ( <relop_expr_list> ) */ 
	   | OP_NOT ID MK_LPAREN relop_expr_list MK_RPAREN
	     {
			 checkfunargs($2, $4, scope);
			 $$ = ABS_mkUnaryop(ABS_mkFuncall($2, $4), NOT);
		 }
       /* OP_MINUS condition added as C could have a condition like: "if(-read(i))".	*/	
	   | OP_MINUS ID MK_LPAREN relop_expr_list MK_RPAREN
	     {
			 checkfunargs($2, $4, scope);
			 $$ = ABS_mkUnaryop(ABS_mkFuncall($2, $4), UMINUS);		   
		 }
		   
	   | var_ref
         {
			 check_arraydim($1, scope);
			 check_structref($1, scope, &temperr);
			 $$ = $1;
		 }
	

	   /* | - var-reference */ 
	   | OP_NOT var_ref  {$$ = ABS_mkUnaryop($2, NOT);}
       /* OP_MINUS condition added as C could have a condition like: "if(-a)".	*/	
	   | OP_MINUS var_ref  {$$ = ABS_mkUnaryop($2, NOT);}
	   ;

var_ref	: ID
          {
			  if (ST_lookup($1, scope, VAR) == NULL) {
				  yyerror("");
				  printf("ID '%s' undeclared.\n", $1);
				  // still need to build the corresponding varref expr
				  $$ = ABS_mkErr();
			  }
			  else $$ = ABS_mkLval_var($1);
		  }
        | var_ref MK_LB expr MK_RB
		  {
			  if (!TY_isInt(TY_check($3, scope))) {
				  yyerror("");
				  printf("Array subscript is not an integer.\n");
			  }
			  $$ = ABS_mkLval_arr($1, $3);
		  }
        | var_ref MK_DOT ID
		  {
			  //check_varref_struct();
			  $$ = ABS_mkLval_struct($1, $3);
		  }
		;

%%
#include "lex.yy.c"

int main (int argc, char *argv[])
{
    init_symtab();
    if(argc>0)
        yyin = fopen(argv[1],"r");
    else
        yyin=stdin;
    yyparse();
    if (err == 0) printf("%s\n", "Parsing completed. No errors found.");
	// symbol table is clearned for every scope
    //cleanup_symtab();
    return 0;
} /* main */


yyerror(mesg)
char *mesg;
{
	err = 1;
    printf("%s\t%d\t%s\t'%s',\t", "Error found in Line ", linenumber, "next token: ", yytext);
	//if (format == NULL) printf(mesg);
    //else printf(format, mesg);
    //exit(1);
}

/*************************** helper functions ********************************/
void check_arraydim(expr varref, int scope) {
	if (varref == NULL) return;
	// y = 0; when y is not declared, no varref expr will be built
	if (varref->type != LVAL_ARR) return;
	char *base = ABS_lvalBaseVar(varref);
	ST_symnodeptr n = ST_lookup(base, scope, VAR);
	if (LST_size(n->type.vartype->dim_exprs) != ABS_lvalRefLength(varref)) {
		yyerror("");
		printf("Incompatible array dimensions.\n");
	}
}

struct list *initidlist_to_vardeclist(struct list *idlist, type t) {
	struct list *vardeclist = LST_init();
	struct lnode *n = idlist->dummy->next;
	for (int i = 0; i < LST_size(idlist); i++) {
		struct vardec *vdec = malloc(sizeof(struct vardec));
		strcpy(vdec->name, ((struct init_id *)(n->data))->id);
		TY_setDim(t, ((struct init_id *)(n->data))->dim_exprs);
		vdec->type = t;
		LST_add(vardeclist, vdec);
	}

	return vardeclist;
}

// int x,y,z
// all ids with type updated entered into symtab
void initidlist_to_symtab(struct list *idlist, type t, int scope) {
	struct list *l = idlist;
	struct lnode *n = l->dummy->next;
	for (int i = 0; i < LST_size(l); i++) {
		char *id = ((struct init_id *)(n->data))->id;
		struct list *dim_exprs = ((struct init_id *)(n->data))->dim_exprs;
		if (ST_lookup_fixscope(id, scope, VAR) != NULL) {
			yyerror("");
			printf("ID '%s' redeclared.\n", id);
		} else {
			// update type for array declaration
			TY_setDim(t, dim_exprs);
		    ST_mkVardec(id, scope, t);
		}
		n = n->next;
	}
} 

// called after all members of a struct are collected. Check for duplicate member.
void check_structdecl(char *structname, struct list *fields) {
	struct lnode *n = fields->dummy->next;
	for (int i = 0; i < LST_size(fields); i++) {
		char *name = ((struct vardec *)n->data)->name;
		type t = ((struct vardec *)n->data)->type;
		// one field is a struct, check if it has the same name of parent
		if (t->basetype == TY_STRUCT && strcmp(structname, t->structinfo->structname) == 0) {
			yyerror("");
			printf("Field '%s' has incomplete type.\n", name);
		}
		// temporaily use symbol table as a set
		if (ST_lookup(name, 100, VAR) == NULL) {
			insert_id(name, 100);
		} else {
			yyerror("");
			printf("Duplicate struct member '%s'.\n", name);
		}
		n = n->next;
	}
	ST_cleanSymtab(100);
}

// find list of fields (vardec), check if the accessed field is in the list
// TODO: probably should write into type.h, as a case of typecheck for varref exprs.
struct list *check_structref(expr varref, int scope, bool *temperr) {
	if (varref == NULL) return NULL;
	expr base;
	struct list* basefields;
	// base case
	if (varref->type == LVAL_VAR) {
		ST_symnodeptr n = ST_lookup(varref->info.lval_var, scope, VAR);
		type t = n->type.vartype;
		if (t->basetype == TY_STRUCT) {
			return t->structinfo->fields;
		} else {
			// base is an scalar or array variable, not a struct
			return NULL;
		}
	} else if (varref->type == LVAL_STRUCT) {
		base = varref->info.lval_struct->base;
		char *field = varref->info.lval_struct->field;
	    basefields = check_structref(base, scope, temperr);
		// err stops error msgs printed out after the point an error is found
		// e.g. s.x.y.z when s has no member x, later no need to print errors
		if (basefields == NULL) {
			// only print error when first time an error is found
			if (!(*temperr)) {
				yyerror("");
				printf("Request for member '%s' in something not a structure or union.\n", field);
				*temperr = true;
			}
			return NULL;
		} else {
			// check if the accessed field is in the list
			struct lnode *n = basefields->dummy->next;
			type found = NULL; // type of the found field
			for (int i = 0; i < LST_size(basefields); i++) {
				char *basefieldname = ((struct vardec *)n->data)->name;
				if (strcmp(basefieldname, field) == 0) {
					// TODO: if there are duplicate field name, the
					// first one is found
					found = ((struct vardec *)n->data)->type;
					break;
				}
				n = n->next;
			}
			if (found == NULL) {
				yyerror("");
				printf("Struct has no member named '%s'.\n", field);
				*temperr = true;
				return NULL;
			} else {
				if (found->basetype == TY_STRUCT) {
					return found->structinfo->fields;
				} else {
					return NULL;
				}
			}
		}
	} else if (varref->type == LVAL_ARR) {
		// could be s[10][11].x.y
		// deference all arrays and find the base var
		base = varref->info.lval_arr->base;
	    return check_structref(base, scope, temperr);
	}

	
	return NULL;
}

struct init_id *initid(char *id, struct list *dim_exprs) {
	struct init_id *i = malloc(sizeof(struct init_id));
	strcpy(i->id, id);
	i->dim_exprs = dim_exprs;
	return i;
}

struct vardec *vardec(type t, char *name) {
	struct vardec * v = malloc(sizeof(struct init_id));
	strcpy(v->name, name);
	v->type = t;
	return v;
}

/* TODO: incorporate fun body for codegen */
void enterfundec(char *fname, type rtype, struct list *params) {
	struct fundec *fdec = malloc(sizeof(struct fundec));
	fdec->rtype = rtype;
	fdec->args = params;
	ST_mkFundec(fname, fdec);
}

// body is a list of stmts
void checkfunret(type rtype, struct list *body, int scope) {
	struct lnode *n = body->dummy->next;
	type ret = NULL;
	for (int i = 0; i < LST_size(body); i++) {
		stmt s = (stmt)(n->data);
		if (s->type == RET) {
			if (s->info.ret->e != NULL) 	
			    ret = TY_check(s->info.ret->e, scope);
			else 
				ret = TY_mkVoid();
		}
		n = n->next;
	}

	// no return statement, has to be in a void function
	if (ret == NULL) {
		if (rtype->basetype != TY_VOID) {
			yyerror("");
			printf("Missing return statement.\n");
		}
	} else {
		// no array, structs as return so just compare base type
		if (ret->basetype != rtype->basetype) {
			yyerror("");
			printf("Incompatible return type.\n");
		}
	}
}

// number of args must be the same
// arr and scalar must match
void checkfunargs(char *fname, struct list *actuals, int scope) {
	// function symbols all have scope of 0.
	ST_symnodeptr n = ST_lookup(fname, 0, FUN);
	if (n == NULL) {
		yyerror("");
		printf("Function '%s' not declared.\n", fname);
		return;
	}
	struct list *formals = n->type.funinfo->args;
	int len = LST_size(formals); // shorter of formals and actuals
	if (LST_size(actuals) < LST_size(formals)) {
		yyerror("");
		printf("Too few arguments passed into function '%s'.\n", fname);
		len = LST_size(actuals);
	} else if (LST_size(actuals) > LST_size(formals)) {
		yyerror("");
		printf("Too many arugments passed into function '%s'.\n", fname);	 
		len = LST_size(formals);
	}

	struct lnode *ftemp = formals->dummy->next;
	struct lnode *atemp = actuals->dummy->next;
	for (int i = 0; i < len; i++) {
		struct vardec *fv = (struct vardec *)ftemp->data;
		type at = TY_check((expr)(atemp->data), scope);
		if (fv->type->dim_exprs != NULL && at->dim_exprs == NULL) {
			yyerror("");
			printf("Scalar passed to array parameter '%s'.\n", fv->name);
		} else if (fv->type->dim_exprs == NULL && at->dim_exprs != NULL) {
			yyerror("");
			printf("Array passed to scalar parameter '%s'.\n", fv->name);
		}
		
		ftemp = ftemp->next;
		atemp = atemp->next;
	}
}
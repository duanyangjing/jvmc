%option noyywrap
%{
	#include "ast.h"
	#include "string.h"
%}
int             "int"
char            "char"
float           "float"
void            "void"
if              "if"
else            "else"
while           "while"
for	            "for"
struct          "struct"
union           "union"
return          "return"

letter          [A-Za-z]
digit           [0-9]

ID              ({letter})({letter}|{digit}|"_")*
assign          "="
or              "||"
and             "&&"
not             "!"
eq              "=="
ne              "!="
lt              "<"
gt              ">"
le              "<="
ge              ">="
plus            "+"
minus           "-"
times           "*"
divide          "/"
int-const       {digit}+
flt-const       {digit}+(("."){digit}+)?
str-const       \"([^"\n])*\"
comment	        "/*"(([^*])|([*]+[^/*]))*("*")+"/"
ws              [ \t]+
newline         "\n"
lparen          "("
rparen          ")"
lbrace          "{"
rbrace          "}"
lbracket        "["
rbracket        "]"
comma           ","
semicolon       ";"
dot             "."
error           .

%%

{ws}            ;   /* do nothing with whitespace */

{comment}	    ;
{int}           {return INT;}
{float}         {return FLOAT;}
{void}	        {return VOID;}
{if}            {return IF;}
{else}          {return ELSE;}
{while}         {return WHILE;}
{for}      	    {return FOR;}  
{struct}	    {structblock[scope+1] = true; return STRUCT;}
{union}	        {structblock[scope+1] = true; return STRUCT;}
{return}        {return RETURN;}

{ID}            {
	strcpy(yylval.str, yytext);
    return ID;
                }
			   
{assign}        {return ASSIGN;}
{and}           {return AND;}
{or}            {return OR;}
{not}           {return NOT;}
{eq}            {return EQ;}
{ne}            {return NE;}
{lt}            {return LT;}
{gt}            {return GT;}
{le}            {return LE;}
{ge}            {return GE;}
{plus}          {return PLUS;}
{minus}         {return MINUS;}
{times}         {return TIMES;}
{divide}        {return DIVIDE;}

{int-const}	    {
	yylval.expr = ABS_mkIntConstant(atoi(yytext));
	return CONST;
		}
{flt-const}	    {
	yylval.expr = ABS_mkFloatConstant(atof(yytext));
	return CONST;
		        }
{str-const}	    {
	yylval.expr = ABS_mkStrConstant(yytext);
	return CONST;
		        }

{lparen}        {return LPAREN;}
{rparen}        {return RPAREN;}
{lbrace}        {scope++;return LBRACE;}
{rbrace}        {scope--;return RBRACE;}
{lbracket}      {return LB;}
{rbracket}      {return RB;}
{comma}         {return COMMA;}
{semicolon}     {return SEMICOLON;}
{dot}	        {return DOT;}
{newline}       {linenumber+=1;}
{error}         return ERROR;
%%
%option noyywrap
%option c++


%{
   // lexer should be isolated from ast module, it just generates tokens
  #include <string>
  #include "parser.tab.hh"

  // YY_DECL has original decl of the yylex signature generate by flex. This is
  // overwritten because we'd like to put Scanner class in Front namespace
  // Code run each time a pattern is matched.
  #define YY_USER_ACTION  loc.columns(yyleng);
  Front::Parser::semantic_type yylval;
  using token = Front::Parser::token;

%}
			

int             "int"
char            "char"
float           "float"
void            "void"
if              "if"
else            "else"
while           "while"
for	        "for"
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
chr-const       \'.\'
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

{ws}            {loc.step();}

{comment}	{}
{int}           {return token::INT;}
{char}          {return token::CHAR;}
{float}         {return token::FLOAT;}
{void}	        {return token::VOID;}
{if}            {return token::IF;}
{else}          {return token::ELSE;}
{while}         {return token::WHILE;}
{for}      	{return token::FOR;}  
{struct}	{return token::STRUCT;}
{union}	        {return token::STRUCT;}
{return}        {return token::RETURN;}

{ID}            {
	yylval.string = new std::string(yytext);
    return token::ID;
                }
			   
{assign}        {return token::ASSIGN;}
{and}           {return token::AND;}
{or}            {return token::OR;}
{not}           {return token::NOT;}
{eq}            {return token::EQ;}
{ne}            {return token::NE;}
{lt}            {return token::LT;}
{gt}            {return token::GT;}
{le}            {return token::LE;}
{ge}            {return token::GE;}
{plus}          {return token::PLUS;}
{minus}         {return token::MINUS;}
{times}         {return token::TIMES;}
{divide}        {return token::DIVIDE;}

{int-const}	    {
	yylval.string = new std::string(yytext);
	return token::INTCONST;
		}
{flt-const}	    {
	yylval.string = new std::string(yytext);
	return token::FLTCONST;
		        }
{chr-const}	    {
	yylval.string = new std::string(yytext);
	return token::CHRCONST;
		        }
{str-const}	    {
	yylval.string = new std::string(yytext);
	return token::STRCONST;
		        }

{lparen}        {return token::LPAREN;}
{rparen}        {return token::RPAREN;}
{lbrace}        {return token::LBRACE;}
{rbrace}        {return token::RBRACE;}
{lbracket}      {return token::LB;}
{rbracket}      {return token::RB;}
{comma}         {return token::COMMA;}
{semicolon}     {return token::SEMICOLON;}
{dot}	        {return token::DOT;}
{newline}       {loc.lines(yyleng); loc.step();}
{error}         {return token::ERROR;}
%%

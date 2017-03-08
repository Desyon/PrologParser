%{
#include "prolog.tab.h"
#define YY_DECL extern "C" int yylex()
int lines = 1;
%}

IS          (is)
CONST       ([a-z][A-Za-z0-9]*)
VAR         ([A-Z][A-Za-z0-9]*)
AVAR      (_[A-Za-z0-9]*)

POPEN       (\()
PCLOSE      (\))
DOT         (\.)
DEF         (:-)
LOPEN       (\[)
LCLOSE      (\])
COM         (\,)
PIPE        (\|)

PLUS        (\+)
MINUS       (-)
MULT        (\*)
DIV         (\/)

SMALLER     (<)
LARGER      (>)
LEQUAL      (>=)
EQUALS      (=<)
EQUAL       (=:=)
UNEQUAL	    (=\\=)

INT         ([0-9]+)
FLOAT       ([0-9]\.[0-9]+)

EOL         (\n)
SPACE       (\s+)

%%

{IS}        {printf("flex: 'is' found.\n"); return IS;}
{CONST}     {printf("flex: Constant found.\n"); return CONST;}
{VAR}       {printf("flex: Variable found.\n"); return VAR;}
{AVAR}      {printf("flex: Anonymus variavle found.\n"); return AVAR;}
{POPEN}     {printf("flex: Opening Paranthesis found.\n"); return POPEN;}
{PCLOSE}    {printf("flex: Closing Paranthesis found.\n"); return PCLOSE;}
{DOT}       {printf("flex: Dor found.\n"); return DOT;}
{DEF}       {printf("flex: Definition sign found.\n"); return DEF;}
{LOPEN}     {printf("flex: List opening found.\n"); return LOPEN;}
{LCLOSE}    {printf("flex: List closing found.\n"); return LCLOSE;}
{COM}       {printf("flex: Comma found.\n"); return COM;}
{PIPE}      {printf("flex: Pipe found.\n"); return PIPE;}
{PLUS}      {printf("flex: Plus found.\n"); return PLUS;}
{MINUS}     {printf("flex: Minus found.\n"); return MINUS;}
{MULT}      {printf("flex: Mult found.\n"); return MULT;}
{DIV}       {printf("flex: Div found.\n"); return DIV;}
{SMALLER}   {printf("flex: Smaller found.\n"); return SMALLER;}
{LARGER}    {printf("flex: Larger found.\n"); return LARGER;}
{LEQUAL}    {printf("flex: Larger/equal found.\n"); return LEQUAL;}
{EQUALS}    {printf("flex: Equal/smaller found.\n"); return EQUALS;}
{EQUAL}     {printf("flex: Equal found.\n"); return EQUAL;}
{UNEQUAL}   {printf("flex: Unequal found.\n"); return UNEQUAL;}
{INT}       {printf("flex: Integer found.\n"); return INT;}
{FLOAT}     {printf("flex: Float found.\n"); return FLOAT;}
{EOL}       {printf("flex: End of line found.\n");}

%%


%%

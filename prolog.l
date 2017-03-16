%{
#include "prolog.tab.h"
#define YY_DECL extern "C" int yylex()
int lines = 1;
%}

IS          (is)
CONST       ([a-z][A-Za-z0-9]*)
VAR         ([A-Z][A-Za-z0-9]*)
AVAR        (_[A-Za-z0-9]*)

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

{IS}        {printf("flex: IS\n"); return IS;}
{CONST}     {printf("flex: CONST\n"); return CONST;}
{VAR}       {printf("flex: VAR\n"); return VAR;}
{AVAR}      {printf("flex: AVAR\n"); return AVAR;}
{POPEN}     {printf("flex: POPEN\n"); return POPEN;}
{PCLOSE}    {printf("flex: PLCOSE\n"); return PCLOSE;}
{DOT}       {printf("flex: DOT\n"); return DOT;}
{DEF}       {printf("flex: DEF\n"); return DEF;}
{LOPEN}     {printf("flex: LOPEN\n"); return LOPEN;}
{LCLOSE}    {printf("flex: LCLOSE\n"); return LCLOSE;}
{COM}       {printf("flex: COM\n"); return COM;}
{PIPE}      {printf("flex: PIPE\n"); return PIPE;}
{PLUS}      {printf("flex: PLUS\n"); return PLUS;}
{MINUS}     {printf("flex: MINUS\n"); return MINUS;}
{MULT}      {printf("flex: MULT\n"); return MULT;}
{DIV}       {printf("flex: DIV\n"); return DIV;}
{SMALLER}   {printf("flex: SMALLER.\n"); return SMALLER;}
{LARGER}    {printf("flex: LARGER\n"); return LARGER;}
{LEQUAL}    {printf("flex: LEQUAL\n"); return LEQUAL;}
{EQUALS}    {printf("flex: EQUALS\n"); return EQUALS;}
{EQUAL}     {printf("flex: EQUAL\n"); return EQUAL;}
{UNEQUAL}   {printf("flex: UNEQUAL\n"); return UNEQUAL;}
{INT}       {printf("flex: INT\n"); return INT;}
{FLOAT}     {printf("flex: FLOAT\n"); return FLOAT;}
{EOL}       {printf("flex: EOL\n"); lines++;}

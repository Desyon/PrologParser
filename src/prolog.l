%{
#include "prolog.tab.h"
#include "debug.h"

#include <string.h>

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
SEQUAL      (=<)
EQUAL       (=:=)
UNEQUAL	    (=\\=)

INT         ([0-9]+)
FLOAT       ([0-9]\.[0-9]+)

EOL         (\n)
SPACE       (\s+)

%%

{IS}        {DEBUG("flex: IS\n"); return IS;}
{CONST}     {DEBUG("flex: CONST\n"); yylval.text = strdup(yytext); return CONST;}
{VAR}       {DEBUG("flex: VAR\n"); yylval.text = strdup(yytext); return VAR;}
{POPEN}     {DEBUG("flex: POPEN\n"); return POPEN;}
{PCLOSE}    {DEBUG("flex: PLCOSE\n"); return PCLOSE;}
{DOT}       {DEBUG("flex: DOT\n"); return DOT;}
{DEF}       {DEBUG("flex: DEF\n"); return DEF;}
{LOPEN}     {DEBUG("flex: LOPEN\n"); return LOPEN;}
{LCLOSE}    {DEBUG("flex: LCLOSE\n"); return LCLOSE;}
{COM}       {DEBUG("flex: COM\n"); return COM;}
{PIPE}      {DEBUG("flex: PIPE\n"); return PIPE;}
{PLUS}      {DEBUG("flex: PLUS\n"); return PLUS;}
{MINUS}     {DEBUG("flex: MINUS\n"); return MINUS;}
{MULT}      {DEBUG("flex: MULT\n"); return MULT;}
{DIV}       {DEBUG("flex: DIV\n"); return DIV;}
{SMALLER}   {DEBUG("flex: SMALLER.\n"); return SMALLER;}
{LARGER}    {DEBUG("flex: LARGER\n"); return LARGER;}
{LEQUAL}    {DEBUG("flex: LEQUAL\n"); return LEQUAL;}
{SEQUAL}    {DEBUG("flex: SEQUAL\n"); return SEQUAL;}
{EQUAL}     {DEBUG("flex: EQUAL\n"); return EQUAL;}
{UNEQUAL}   {DEBUG("flex: UNEQUAL\n"); return UNEQUAL;}
{INT}       {DEBUG("flex: INT\n"); return INT;}
{FLOAT}     {DEBUG("flex: FLOAT\n"); return FLOAT;}
{EOL}       {DEBUG("flex: EOL\n"); lines++;}

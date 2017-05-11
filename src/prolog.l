%{
#include "prolog.tab.h"

#define YY_DECL extern "C" int yylex()
int lines = 1;
%}

DEF     (:-)
DOT     (\.)
COMMA   (,)
POPEN   (\()
PCLOSE  (\))
LOPEN   (\[)
LCLOSE  (])

PIPE      (\|)
PLUS      (\+)
MINUS     (-)
ASTERISK  (\*)
DIV       (\/)
COLON     (:)

SMALLER (\<)
SEQUAL  (\<=)
GREATER (\>)
GEQUAL  (\>=)
EQUAL   (==?)
UNEQUAL (=\\=)

NOT (not)
IS  (is)

NUMBER ([0-9]+|[0-9]+\.[0-9]+)
CONST ([a-z][a-zA-Z0-9]*)
VAR ([A-Z][A-Za-z0-9]*)

NEWLINE (\n)
SPACE (\s+)

%%
{DEF} {return DEF;}
{DOT} {return DOT;}
{COMMA} {return COMMA;}
{POPEN} {return POPEN;}
{PCLOSE} {return PCLOSE;}
{LOPEN} {return LOPEN;}
{LCLOSE} {return LCLOSE;}
{PIPE} {return PIPE;}
{PLUS} {return PLUS;}
{MINUS} {return MINUS;}
{ASTERISK} {return ASTERISK;}
{DIV} {return DIV;}
{COLON} {return COLON;}
{SMALLER} {return SMALLER;}
{SEQUAL} {return SEQUAL;}
{GREATER} {return GREATER;}
{GEQUAL} {return GEQUAL;}
{EQUAL} {return EQUAL;}
{NOT} {return NOT;}
{IS} {return IS;}
{UNEQUAL} {return UNEQUAL;}
{NUMBER} {sscanf(yytext, "%d", &yylval.num); return NUMBER;}
{CONST} {yylval.str = strdup(yytext); return CONST;}
{VAR} {yylval.str = strdup(yytext); return VAR;}
{NEWLINE} {lines++; return NEWLINE;}

%%
int yywrap (void) { return 1;}

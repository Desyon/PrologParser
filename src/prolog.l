%{
#include "prolog.tab.h"
%}

IMPLIES (:-)
DOT     (\.)
COMMA   (\,)
OPEN_PARA (\()
CLOSE_PARA (\))
OPEN_BRA (\[)
CLOSE_BRA (])

PIPE (\|)
PLUS (\+)
MINUS (-)
ASTERIX (\*)
SLASH (\/)
COLON (:)

SMALLER (\<)
SMALLER_EQUALS (\<=)
GREATER (\>)
GREATER_EQUALS (\>=)
EQUALS (==?)
UNEQUALS (=\\=)

NOT (not)
IS (is)

NUMBER ([0-9]+)
CONST_ID ([a-z][a-zA-Z]*)
VAR_ID ([A-Z][A-Za-z]*)

NEW_LINE_FEED (\n|\n\r)

%%
IMPLIES {return IMPLIES;}
DOT {return DOT;}
COMMA {return COMMA;}
OPEN_PARA {return OPEN_PARA;}
CLOSE_PARA {return CLOSE_PARA;}
OPEN_BRA {return OPEN_BRA;}
CLOSE_BRA {return CLOSE_BRA;}
PIPE {return PIPE;}
PLUS {return PLUS;}
MINUS {return MINUS;}
ASTERIX {return ASTERIX;}
SLASH {return SLASH;}
COLON {return COLON;}
SMALLER {return SMALLER;}
SMALLER_EQUALS {return SMALLER_EQUALS;}
GREATER {return GREATER;}
GREATER_EQUALS {return GREATER_EQUALS;}
EQUALS {return EQUALS;}
NOT {return NOT;}
IS {return IS;}
UNEQUALS {return UNEQUALS;}
NUMBER {sscanf(yytext, "%d", &yylval.num); return NUMBER;}
CONST_ID {yylval.str = strdup(yytext); return CONST_ID;}
VAR_ID {yylval.str = strdup(yytext); return VAR_ID;}
NEW_LINE_FEED {return NEW_LINE_FEED;}

%%
int yywrap (void) { return 1;}

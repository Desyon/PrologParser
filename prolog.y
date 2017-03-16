%{
#include <stdlib.h>
#include <stdio.h>

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char* yytext;

void yyerror(const char *s) {
  fprintf (stderr, "Parser error in line %d:\n%s\n", lines, s);
}

%}

%token IS
%token CONST
%token VAR
%token AVAR

%token POPEN
%token PCLOSE
%token DOT
%token DEF
%token LOPEN
%token LCLOSE
%token COM
%token PIPE

%token PLUS
%token MINUS
%token MULT
%token DIV

%token SMALLER
%token LARGER
%token LEQUAL
%token EQUALS
%token EQUAL
%token UNEQUAL

%token INT
%token FLOAT

%%

line:   fact DOT {fprintf(stderr, "\tbison: line:\tfact DOT\n");}
        | rule DOT {fprintf(stderr, "\tbison: line:\trule DOT\n");}
        | line fact DOT {fprintf(stderr, "\tbison: line:\tfact DOT\n");}
        | line rule DOT {fprintf(stderr, "\tbison: line:\trule DOT\n");}
        ;

fact:   CONST POPEN argList PCLOSE {fprintf(stderr, "\tbison: fact:\tCONST POPEN argList PCLOSE\n");}
        | CONST {fprintf(stderr, "\tbison: fact:\tCONST\n");}
        ;

argList:    arg {fprintf(stderr, "\tbison: argList:\targ\n");}
            | arg COM argList {fprintf(stderr, "\tbison: argList:\targ COM argList\n");}
            ;

arg:        fact {fprintf(stderr, "\tbison: arg:\tfact\n");}
            | list {fprintf(stderr, "\tbison: arg:\tfact\n");}
            | rule {fprintf(stderr, "\tbison: arg:\trule\n");}
            | VAR {fprintf(stderr, "\tbison: arg:\tVAR\n");}
            ;

rule:       fact DEF factList {fprintf(stderr, "\tbison: rule:\tfact DEF factList\n");}
            ;

factList:   fact {fprintf(stderr, "\tbison: factList:\tfact\n");}
            | fact COM factList {fprintf(stderr, "\tbison: factList:\tfact COM factList\n");}
            ;

list:       LOPEN lelements LCLOSE {fprintf(stderr, "\tbison: list:\tLOPEN lelement LCLOSE\n");}
            | LOPEN LCLOSE {fprintf(stderr, "\tbison: list:\tLOPEN LCLOSE\n");}
            ;

lelements:    lelement {fprintf(stderr, "\tbison: lelements:\tlelement\n");}
            | lelement COM lelements {fprintf(stderr, "\tbison: list:\tlelement COM lelements\n");}
            | lelement PIPE ltail {fprintf(stderr, "\tbison: list:\tlelement PIPE ltail\n");}
            ;

lelement:   VAR {fprintf(stderr, "\tbison: lelement:\tVAR\n");}
            | CONST {fprintf(stderr, "\tbison: lelement:\tCONST\n");}
            | num {fprintf(stderr, "\tbison: lelement:\tnum\n");}
            | list {fprintf(stderr, "\tbison: lelement:\tlist\n");}
            ;

ltail:      lelement {fprintf(stderr, "\tbison: ltail:\tlelement\n");}
            | lelement COM ltail {fprintf(stderr, "\tbison: ltail:\tlelement COM ltail\n");}
            ;

num:        INT {fprintf(stderr, "\tbison: num:\tINT\n");}
            | FLOAT {fprintf(stderr, "\tbison: num:\tFLOAT\n");}
            | MINUS INT {fprintf(stderr, "\tbison: num:\tMINUS INT\n");}
            | MINUS FLOAT {fprintf(stderr, "\tbison: num:\tMINUS FLOAT\n");}
            ;
%%

int main(int, char**) {
    yyparse();
}

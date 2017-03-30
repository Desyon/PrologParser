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
%token SEQUAL
%token EQUAL
%token UNEQUAL

%token INT
%token FLOAT

%left EQUAL UNEQUAL SMALLER SEQUAL LARGER LEQUAL
%left PLUS MINUS
%left MULT DIV

%right UMINUS

%%

line:   fact DOT {fprintf(stderr, "\tbison: line:\tfact DOT\n");}
        | rule DOT {fprintf(stderr, "\tbison: line:\trule DOT\n");}
        | line fact DOT {fprintf(stderr, "\tbison: line:\tfact DOT\n");}
        | line rule DOT {fprintf(stderr, "\tbison: line:\trule DOT\n");}
        ;

rule:   fact DEF ruleargs {fprintf(stderr, "\tbison: rule:\tfact DEF ruleargs\n");}
        ;

fact:   CONST POPEN args PCLOSE {fprintf(stderr, "\tbison: fact:\tCONST POPEN args PCLOSE\n");}
        | CONST {fprintf(stderr, "\tbison: fact:\tCONST\n");}
        ;

args:   arg {fprintf(stderr, "\tbison: args:\targ\n");}
        | arg COM args {fprintf(stderr, "\tbison: args:\targ COM args\n");}
        ;

arg:    CONST {fprintf(stderr, "\tbison: arg:\tCONST\n");}
        | list {fprintf(stderr, "\tbison: arg:\tfact\n");}
        | mathexpr {fprintf(stderr, "\tbison: arg:\tmathexpr\n");}
        ;

ruleargs:   rulearg {fprintf(stderr, "\tbsion: ruleargs:\trulearg\n");}
            | rulearg COM ruleargs {fprintf(stderr, "\tbsion: ruleargs:\trulearg COM ruleargs\n");}
            ;

rulearg:    fact {fprintf(stderr, "\tbsion: rulearg:\tfact\n");}
            | compexpr {fprintf(stderr, "\tbsion: rulearg:\tcompexpr\n");}
            | isexpr {fprintf(stderr, "\tbsion: rulearg:\tisexpr\n");}
            ;

list:       LOPEN lelements LCLOSE {fprintf(stderr, "\tbison: list:\tLOPEN lelements LCLOSE\n");}
            | LOPEN LCLOSE {fprintf(stderr, "\tbison: list:\tLOPEN LCLOSE\n");}
            ;

lelements:  lelement {fprintf(stderr, "\tbison: lelements:\tlelement\n");}
            | lelement COM lelements {fprintf(stderr, "\tbison: list:\tlelement COM lelements\n");}
            | lelement PIPE ltail {fprintf(stderr, "\tbison: list:\tlelement PIPE ltail\n");}
            ;

lelement:   CONST {fprintf(stderr, "\tbison: lelement:\tCONST\n");}
            | mathexpr {fprintf(stderr, "\tbison: lelement:\tmathexpr\n");}
            | list {fprintf(stderr, "\tbison: lelement:\tlist\n");}
            ;

ltail:      lelement {fprintf(stderr, "\tbison: ltail:\tlelement\n");}
            | lelement COM ltail {fprintf(stderr, "\tbison: ltail:\tlelement COM ltail\n");}
            ;

mathexpr:   num {fprintf(stderr, "\tbison: mathexpr:\tnum\n");}
            | VAR {fprintf(stderr, "\tbison: mathexpr:\tVAR\n");}
            | POPEN mathexpr PCLOSE {fprintf(stderr, "\tbison: mathexpr:\tPOPEN mathexpr PCLOSE\n");}
            | MINUS mathexpr %prec UMINUS {fprintf(stderr, "\tbison: mathexpr:\tMINUS mathexpr\n");}
            | mathexpr operator mathexpr %prec PLUS {fprintf(stderr, "\tbison: mathexpr:\tmathexpr operator mathexpr\n");}
            ;

num:        INT {fprintf(stderr, "\tbison: num:\tINT\n");}
            | FLOAT {fprintf(stderr, "\tbison: num:\tFLOAT\n");}
            ;

operator:   PLUS {fprintf(stderr, "\tbison: operator:\tPLUS\n");}
            | MINUS {fprintf(stderr, "\tbison: operator:\tMINUS\n");}
            | MULT {fprintf(stderr, "\tbison: operator:\tMULT\n");}
            | DIV {fprintf(stderr, "\tbison: operator:\tDIV\n");}
            ;

compexpr:   mathexpr compoperator mathexpr {fprintf(stderr, "\tbison: compexpr:\tmathexpr compoperator mathexpr\n");}

compoperator: EQUAL {fprintf(stderr, "\tbison: compoperator:\tEQUAL\n");}
              | UNEQUAL {fprintf(stderr, "\tbison: compoperator:\tUNEQUAL\n");}
              | SMALLER {fprintf(stderr, "\tbison: compoperator:\tSMALLER\n");}
              | SEQUAL {fprintf(stderr, "\tbison: compoperator:\tSEQUAL\n");}
              | LARGER {fprintf(stderr, "\tbison: compoperator:\tLARGER\n");}
              | LEQUAL {fprintf(stderr, "\tbison: compoperator:\tLEQUAL\n");}
              ;

isexpr:   VAR IS mathexpr {fprintf(stderr, "\tbison: isexpr:\tVAR IS mathexpr\n");}
          ;

%%

int main(int, char**) {
    yyparse();
}

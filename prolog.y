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

start:  cmdList {fprintf(stderr, "\tbison: start:\tcmds\n");}
        ;

cmdList:    cmd cmdList {fprintf(stderr, "\tbison:\tcmd cmdList\n")}
            | cmd DOT {fprintf(stderr, "\tbison:\tcmd DOT\n")}
            ;

cmd:    VAR {fprintf(stderr, "\tbison:\tVAR\n")}
        | CONST {fprintf(stderr, "\tbison:\tCONST\n")}
        ;

%%

int main(int, char**) {
    yyparse();
}

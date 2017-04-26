%{
#include <stdio.h>
#include <iostream>
#include <string>

#include "debug.h"
#include "symbolTable.h"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char* yytext;

void yyerror(const char *s) {
    fprintf (stderr, "Parser error in line %d:\n%s\n", lines, s);
}

int literCount = -1;

%}

%token IS
%token <text>CONST
%token <text>VAR

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

%union {
  char* text;
}
%%

line:   fact DOT {DEBUG("\tbison: line:\tfact DOT");}
        | rule DOT {DEBUG("\tbison: line:\trule DOT");}
        | line fact DOT {DEBUG("\tbison: line:\tfact DOT");}
        | line rule DOT {DEBUG("\tbison: line:\trule DOT");}
        ;

rule:   pred DEF ruleargs {DEBUG("\tbison: rule:\tfact DEF ruleargs\n");}
        ;

fact:   pred {DEBUG("\tbison: fact:\tpred\n");}
        ;

pred:   CONST POPEN args PCLOSE {DEBUG("\tbison: pred:\tCONST POPEN args PCLOSE\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);
          //NamedId* litName = new NamedId;
          //litName->id = ++literCount;
          }
        | CONST {DEBUG("\tbison: pred:\tCONST\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);
        }
        ;

args:   arg {DEBUG("\tbison: args:\targ\n");}
        | arg COM args {DEBUG("\tbison: args:\targ COM args\n");}
        ;

arg:    CONST {DEBUG("\tbison: arg:\tCONST\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);
        }
        | list {DEBUG("\tbison: arg:\tfact\n");}
        | mathexpr {DEBUG("\tbison: arg:\tmathexpr\n");}
        ;

ruleargs:   rulearg {DEBUG("\tbsion: ruleargs:\trulearg\n");}
            | rulearg COM ruleargs {DEBUG("\tbsion: ruleargs:\trulearg COM ruleargs\n");}
            ;

rulearg:    pred {DEBUG("\tbsion: rulearg:\tfact\n");}
            | compexpr {DEBUG("\tbsion: rulearg:\tcompexpr\n");}
            | isexpr {DEBUG("\tbsion: rulearg:\tisexpr\n");}
            ;

list:       LOPEN lelements LCLOSE {DEBUG("\tbison: list:\tLOPEN lelements LCLOSE\n");}
            | LOPEN LCLOSE {DEBUG("\tbison: list:\tLOPEN LCLOSE\n");}
            ;

lelements:  lelement {DEBUG("\tbison: lelements:\tlelement\n");}
            | lelement COM lelements {DEBUG("\tbison: list:\tlelement COM lelements\n");}
            | lelement PIPE ltail {DEBUG("\tbison: list:\tlelement PIPE ltail\n");}
            ;

lelement:   CONST {DEBUG("\tbison: lelement:\tCONST\n");
              std::string symbol($1);
              free($1);
              DEBUG("CONST: " << symbol << std::endl);
            }
            | mathexpr {DEBUG("\tbison: lelement:\tmathexpr\n");}
            | list {DEBUG("\tbison: lelement:\tlist\n");}
            ;

ltail:      lelement {DEBUG("\tbison: ltail:\tlelement\n");}
            | lelement COM ltail {DEBUG("\tbison: ltail:\tlelement COM ltail\n");}
            ;

mathexpr:   num {DEBUG("\tbison: mathexpr:\tnum\n");}
            | VAR {DEBUG("\tbison: mathexpr:\tVAR\n");
              std::string symbol($1);
              free($1);
              DEBUG("VAR: " << symbol << std::endl);
            }
            | POPEN mathexpr PCLOSE {DEBUG("\tbison: mathexpr:\tPOPEN mathexpr PCLOSE\n");}
            | MINUS mathexpr %prec UMINUS {DEBUG("\tbison: mathexpr:\tMINUS mathexpr\n");}
            | mathexpr operator mathexpr %prec PLUS {DEBUG("\tbison: mathexpr:\tmathexpr operator mathexpr\n");}
            ;

num:        INT {DEBUG("\tbison: num:\tINT\n");}
            | FLOAT {DEBUG("\tbison: num:\tFLOAT\n");}
            ;

operator:   PLUS {DEBUG("\tbison: operator:\tPLUS\n");}
            | MINUS {DEBUG("\tbison: operator:\tMINUS\n");}
            | MULT {DEBUG("\tbison: operator:\tMULT\n");}
            | DIV {DEBUG("\tbison: operator:\tDIV\n");}
            ;

compexpr:   mathexpr compoperator mathexpr {DEBUG("\tbison: compexpr:\tmathexpr compoperator mathexpr\n");}

compoperator: EQUAL {DEBUG("\tbison: compoperator:\tEQUAL\n");}
              | UNEQUAL {DEBUG("\tbison: compoperator:\tUNEQUAL\n");}
              | SMALLER {DEBUG("\tbison: compoperator:\tSMALLER\n");}
              | SEQUAL {DEBUG("\tbison: compoperator:\tSEQUAL\n");}
              | LARGER {DEBUG("\tbison: compoperator:\tLARGER\n");}
              | LEQUAL {DEBUG("\tbison: compoperator:\tLEQUAL\n");}
              ;

isexpr:   VAR IS mathexpr {DEBUG("\tbison: isexpr:\tVAR IS mathexpr\n");
            std::string symbol($1);
            free($1);
            DEBUG("VAR: " << symbol << std::endl);
          }
          ;

%%

int main(int, char**) {
    yyparse();
    printSymbolTable();
}

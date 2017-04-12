%{
#include <stdlib.h>
#include <stdio.h>
#include <iostream>
#include <string>
#include <vector>

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

line:   fact DOT {std::cerr << "\tbison: line:\tfact DOT\n";}
        | rule DOT {std::cerr << "\tbison: line:\trule DOT\n";}
        | line fact DOT {std::cerr << "\tbison: line:\tfact DOT\n";}
        | line rule DOT {std::cerr << "\tbison: line:\trule DOT\n";}
        ;

rule:   fact DEF ruleargs {std::cerr << "\tbison: rule:\tfact DEF ruleargs\n";}
        ;

fact:   CONST POPEN args PCLOSE {std::cerr << "\tbison: fact:\tCONST POPEN args PCLOSE\n";
          std::string symbol($1);
          free($1);
          std::cerr << "CONST: " << symbol << std::endl;
          }
        | CONST {std::cerr << "\tbison: fact:\tCONST\n";
          std::string symbol($1);
          free($1);
          std::cerr << "CONST: " << symbol << std::endl;}
        ;

args:   arg {std::cerr << "\tbison: args:\targ\n";}
        | arg COM args {std::cerr << "\tbison: args:\targ COM args\n";}
        ;

arg:    CONST {std::cerr << "\tbison: arg:\tCONST\n";
          std::string symbol($1);
          free($1);
          std::cerr << "CONST: " << symbol << std::endl;
        }
        | list {std::cerr << "\tbison: arg:\tfact\n";}
        | mathexpr {std::cerr << "\tbison: arg:\tmathexpr\n";}
        ;

ruleargs:   rulearg {std::cerr << "\tbsion: ruleargs:\trulearg\n";}
            | rulearg COM ruleargs {std::cerr << "\tbsion: ruleargs:\trulearg COM ruleargs\n";}
            ;

rulearg:    fact {std::cerr << "\tbsion: rulearg:\tfact\n";}
            | compexpr {std::cerr << "\tbsion: rulearg:\tcompexpr\n";}
            | isexpr {std::cerr << "\tbsion: rulearg:\tisexpr\n";}
            ;

list:       LOPEN lelements LCLOSE {std::cerr << "\tbison: list:\tLOPEN lelements LCLOSE\n";}
            | LOPEN LCLOSE {std::cerr << "\tbison: list:\tLOPEN LCLOSE\n";}
            ;

lelements:  lelement {std::cerr << "\tbison: lelements:\tlelement\n";}
            | lelement COM lelements {std::cerr << "\tbison: list:\tlelement COM lelements\n";}
            | lelement PIPE ltail {std::cerr << "\tbison: list:\tlelement PIPE ltail\n";}
            ;

lelement:   CONST {std::cerr << "\tbison: lelement:\tCONST\n";
              std::string symbol($1);
              free($1);
              std::cerr << "CONST: " << symbol << std::endl;
            }
            | mathexpr {std::cerr << "\tbison: lelement:\tmathexpr\n";}
            | list {std::cerr << "\tbison: lelement:\tlist\n";}
            ;

ltail:      lelement {std::cerr << "\tbison: ltail:\tlelement\n";}
            | lelement COM ltail {std::cerr << "\tbison: ltail:\tlelement COM ltail\n";}
            ;

mathexpr:   num {std::cerr << "\tbison: mathexpr:\tnum\n";}
            | VAR {std::cerr << "\tbison: mathexpr:\tVAR\n";
              std::string symbol($1);
              free($1);
              std::cerr << "VAR: " << symbol << std::endl;
            }
            | POPEN mathexpr PCLOSE {std::cerr << "\tbison: mathexpr:\tPOPEN mathexpr PCLOSE\n";}
            | MINUS mathexpr %prec UMINUS {std::cerr << "\tbison: mathexpr:\tMINUS mathexpr\n";}
            | mathexpr operator mathexpr %prec PLUS {std::cerr << "\tbison: mathexpr:\tmathexpr operator mathexpr\n";}
            ;

num:        INT {std::cerr << "\tbison: num:\tINT\n";}
            | FLOAT {std::cerr << "\tbison: num:\tFLOAT\n";}
            ;

operator:   PLUS {std::cerr << "\tbison: operator:\tPLUS\n";}
            | MINUS {std::cerr << "\tbison: operator:\tMINUS\n";}
            | MULT {std::cerr << "\tbison: operator:\tMULT\n";}
            | DIV {std::cerr << "\tbison: operator:\tDIV\n";}
            ;

compexpr:   mathexpr compoperator mathexpr {std::cerr << "\tbison: compexpr:\tmathexpr compoperator mathexpr\n";}

compoperator: EQUAL {std::cerr << "\tbison: compoperator:\tEQUAL\n";}
              | UNEQUAL {std::cerr << "\tbison: compoperator:\tUNEQUAL\n";}
              | SMALLER {std::cerr << "\tbison: compoperator:\tSMALLER\n";}
              | SEQUAL {std::cerr << "\tbison: compoperator:\tSEQUAL\n";}
              | LARGER {std::cerr << "\tbison: compoperator:\tLARGER\n";}
              | LEQUAL {std::cerr << "\tbison: compoperator:\tLEQUAL\n";}
              ;

isexpr:   VAR IS mathexpr {std::cerr << "\tbison: isexpr:\tVAR IS mathexpr\n";
            std::string symbol($1);
            free($1);
            std::cerr << "VAR: " << symbol << std::endl;
          }
          ;

%%

int main(int, char**) {
    yyparse();
}

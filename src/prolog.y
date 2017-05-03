%{
#include <stdio.h>
#include <iostream>
#include <string>

#include "debug.h"
#include "SymbolTable.h"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char* yytext;

void yyerror(const char *s) {
    fprintf (stderr, "Parser error in line %d:\n%s\n", lines, s);
}

int literCount = 0;
int paramCount = 0;

SymbolTable symbolTable;
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

%type<expr> rule
%type<expr> fact
%type<expr> pred
%type<expr> compexpr
%type<expr> isexpr
%type<expr> expressions
%type<expr> expression

%type<literParams> args
%type<literParams> arg
%type<literParams> list
%type<literParams> lelements
%type<literParams> lelement
%type<literParams> mathexpr
%type<literParams> num

%left EQUAL UNEQUAL SMALLER SEQUAL LARGER LEQUAL
%left PLUS MINUS
%left MULT DIV

%right UMINUS

%union {
  char *text;
  LiterParams *literParams;
  ExprT *expr;
}
%%

line:   fact DOT {DEBUG("\tbison: line:\tfact DOT");
          symbolTable.push_back(*$1);
        }
        | rule DOT {DEBUG("\tbison: line:\trule DOT");
          symbolTable.push_back(*$1);
        }
        | line fact DOT {DEBUG("\tbison: line:\tfact DOT");
          symbolTable.push_back(*$2);
        }
        | line rule DOT {DEBUG("\tbison: line:\trule DOT");
          symbolTable.push_back(*$2);
        }
        ;

rule:   pred DEF expressions {DEBUG("\tbison: rule:\tfact DEF expressions\n");
          $1->insert($3->begin(), $3->end());
          delete $3,
          $$ = $1;
        }
        ;

fact:   pred {DEBUG("\tbison: fact:\tpred\n");
          $$ = $1;
        }
        ;

pred:   CONST POPEN args PCLOSE {
          DEBUG("\tbison: pred:\tCONST POPEN args PCLOSE\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);

          ExprT *expr = new ExprT;

          LiterName *liter = new LiterName;
          liter->uId = literCount++;
          liter->name = symbol;

          LiterParams params = *$3;
          expr->insert(LiterT(*liter, params));

          $$ = expr;
        }
        | CONST {
          DEBUG("\tbison: pred:\tCONST\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);

          ExprT *expr = new ExprT;

          LiterName *liter = new LiterName;
          liter->uId = literCount++;
          liter->name = symbol;

          expr->insert(LiterT(*liter, LiterParams()));
        }
        ;

args:   arg {
          DEBUG("\tbison: args:\targ\n");
          $$ = $1;
        }
        | arg COM args {
            DEBUG("\tbison: args:\targ COM args\n");
            $1->insert($3->begin(), $3->end());
            delete $3;
            $$ = $1;
        }
        ;

arg:    CONST {
          DEBUG("\tbison: arg:\tCONST\n");
          std::string symbol($1);
          free($1);
          DEBUG("CONST: " << symbol << std::endl);

          ParamName *param = new ParamName;
          param->uId = paramCount++;
          param->name = symbol;

          LiterParams *params = new LiterParams;
          params->insert(*param);

          $$ = params;
        }
        | VAR {
            DEBUG("\tbison: arg:\tVAR\n");
            std::string symbol($1);
            free($1);
            DEBUG("VAR: " << symbol << std::endl);

            ParamName *param = new ParamName;
            param->uId = paramCount++;
            param->name = symbol;

            LiterParams *params = new LiterParams;
            params->insert(*param);

            $$ = params;
        }
        | list {
            DEBUG("\tbison: arg:\tfact\n");
            $$ = $1;
        }
        | num {
            DEBUG("\tbison: arg:\tnumber\n");
            $$ = $1;
        }
        | MINUS num {
            DEBUG("\tbison: arg:\tMINUS number\n");
            $$ = $2;
        }
        ;

expressions:  expression {
                DEBUG("\tbsion: expressions:\texpression\n");
                $$ = $1;
              }
              | expression COM expressions {
                  DEBUG("\tbsion: expressions:\texpression COM expressions\n");
                  $1->insert($3->begin(), $3->end());
                  delete $3;
                  $$ = $1;
              }
              ;

expression:   pred {
                DEBUG("\tbsion: expression:\tfact\n");
                $$ = $1;
              }
              | compexpr {
                  DEBUG("\tbsion: expression:\tcompexpr\n");
                  $$ = $1;
              }
              | isexpr {
                  DEBUG("\tbsion: expression:\tisexpr\n");
                  $$ = $1;
              }
              ;

list:       LOPEN lelements LCLOSE {
              DEBUG("\tbison: list:\tLOPEN lelements LCLOSE\n");
              $$ = $2;
            }
            | LOPEN lelements PIPE lelements LCLOSE {
                DEBUG("\tbison: list:\tLOPEN lelements PIPE LCLOSE\n");
                $2->insert($4->begin(), $4->end());
                delete $4;
                $$ = $2;
            }
            | LOPEN LCLOSE {
                DEBUG("\tbison: list:\tLOPEN LCLOSE\n");
                ParamName *param = new ParamName;
                param->uId = paramCount++;
                param->name = "EMPTYLIST";

                LiterParams *params = new LiterParams;
                params->insert(*param);

                $$ = params;
            }
            ;

lelements:  lelement {
              DEBUG("\tbison: lelements:\tlelement\n");
              $$ = $1;
            }
            | lelement COM lelements {
                DEBUG("\tbison: list:\tlelement COM lelements\n");
                $1->insert($3->begin(), $3->end());
                delete $3;
                $$ = $1;
            }
            ;

lelement:   CONST {
              DEBUG("\tbison: lelement:\tCONST\n");
              std::string symbol($1);
              free($1);
              DEBUG("CONST: " << symbol << std::endl);

              ParamName *param = new ParamName;
              param->uId = paramCount++;
              param->name = symbol;

              LiterParams *params = new LiterParams;
              params->insert(*param);

              $$ = params;
            }
            | VAR {
                DEBUG("\tbsion: lelement:\tVAR\n");
                std::string symbol($1);
                free($1);
                DEBUG("VAR: " << symbol << std::endl);

                ParamName *param = new ParamName;
                param->uId = paramCount++;
                param->name = symbol;

                LiterParams *params = new LiterParams;
                params->insert(*param);

                $$ = params;
            }
            | num {
                DEBUG("\tbsion: lelement:\tnum\n");
                $$ = $1;
            }
            | MINUS num {
                DEBUG("\tbsion: lelement:\tMINUS num\n");
                $$ = $2;
            }
            | list {
                DEBUG("\tbison: lelement:\tlist\n");
                $$ = $1;
            }
            ;

mathexpr:   num {
              DEBUG("\tbison: mathexpr:\tnum\n");
              $$ = $1;
            }
            | VAR {
                DEBUG("\tbison: mathexpr:\tVAR\n");
                std::string symbol($1);
                free($1);
                DEBUG("VAR: " << symbol << std::endl);

                ParamName *param = new ParamName;
                param->uId = paramCount++;
                param->name = symbol;

                LiterParams *params = new LiterParams;
                params->insert(*param);

                $$ = params;
            }
            | POPEN mathexpr PCLOSE {
                DEBUG("\tbison: mathexpr:\tPOPEN mathexpr PCLOSE\n");
                $$ = $2;
            }
            | MINUS mathexpr %prec UMINUS {
                DEBUG("\tbison: mathexpr:\tMINUS mathexpr\n");
                $$ = $2;
            }
            | mathexpr operator mathexpr %prec PLUS {
                DEBUG("\tbison: mathexpr:\tmathexpr operator mathexpr\n");
                $1->insert($3->begin(), $3->end());
                delete $3;
                $$ = $1;
            }
            ;

num:        INT {
              DEBUG("\tbison: num:\tINT\n");
              ParamName *param = new ParamName;
              param->uId = paramCount++;
              param->name = "INT";

              LiterParams *params = new LiterParams;
              params->insert(*param);

              $$ = params;
            }
            | FLOAT {
                DEBUG("\tbison: num:\tFLOAT\n");
                ParamName *param = new ParamName;
                param->uId = paramCount++;
                param->name = "FLOAT";

                LiterParams *params = new LiterParams;
                params->insert(*param);

                $$ = params;
            }
            ;

operator:   PLUS {DEBUG("\tbison: operator:\tPLUS\n");}
            | MINUS {DEBUG("\tbison: operator:\tMINUS\n");}
            | MULT {DEBUG("\tbison: operator:\tMULT\n");}
            | DIV {DEBUG("\tbison: operator:\tDIV\n");}
            ;

compexpr:   mathexpr compoperator mathexpr {
              DEBUG("\tbison: compexpr:\tmathexpr compoperator mathexpr\n");

              ExprT *expr = new ExprT;

              LiterName *liter = new LiterName;
              liter->uId = literCount++;
              liter->name = "COMP";

              $1->insert($3->begin(), $3->end());
              delete $3;

              expr->insert(LiterT(*liter, *$1));

            }

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

            ExprT *expr = new ExprT;

            ParamName *param = new ParamName;
            param->uId = paramCount++;
            param->name = symbol;

            LiterName *liter = new LiterName;
            liter->uId = literCount++;
            liter->name = "IS_EXPR";

            LiterParams params = *$3;
            params.insert(*param);

            expr->insert(LiterT(*liter, params));
            $$ = expr;
          }
          ;

%%

int main(int, char**) {
    yyparse();
    printSymbolTable(symbolTable);
}

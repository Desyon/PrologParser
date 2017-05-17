%{
#include <iostream>
#include <stdio.h>
#include <string.h>

#include "../include/definitions.h"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char *yytext;

Variable *varListHead;
Variable *varListTail;
PartialProblem *firstPartProb;
PartialProblem *lastPartProb;

%}
%union{
  char *str;
  int num;
}
%start clause
%token DEF DOT COMMA POPEN PCLOSE LOPEN LCLOSE
%token PIPE PLUS MINUS ASTERISK DIV
%token SMALLER SEQUAL GREATER GEQUAL EQUAL UNEQUAL
%token NOT IS
%token <num> NUMBER
%token <str> CONST VAR

%left PLUS MINUS ASTERISK DIV
%left UNEQUAL SMALLER SEQUAL GREATER GEQUAL
%%

clause: clause expression
        | expression
        ;

expression: rule DOT
            | fact DOT
            ;

rule: fact DEF factList
      ;

fact: CONST POPEN params PCLOSE {
        genPartialProblem('E',$1); varListHead = nullptr;
      }
      ;

subRule:  CONST POPEN params PCLOSE {
            genPartialProblem('U', $1); varListHead = nullptr;
          }
          | arithmeticExpr {
              genPartialProblem('U',""); varListHead = nullptr;
          }
          ;

arithmeticExpr: VAR operator arithmeticRhs {
                  genVarNode($1);
                }
                ;

operator: PLUS
          | MINUS
          | EQUAL
          | SEQUAL
          | SMALLER
          | GEQUAL
          | GREATER
          | UNEQUAL
          | ASTERISK
          | DIV
          | IS
          ;

arithmeticRhs:  VAR {
                  genVarNode($1);
                }
                | NUMBER
                | CONST
                | arithmeticExpr
                ;

params: param COMMA params
        | param
        ;

factList: subRule COMMA factList
          | subRule
          ;

list: LOPEN lelements LCLOSE
      | LOPEN lelements PIPE lelements LCLOSE
      | LOPEN LCLOSE
      ;

lelements:  lelement
            | lelement COMMA lelements
            ;

lelement: VAR {
            genVarNode($1);
          }
          | NUMBER
          | list
          ;

param:  CONST
        | NUMBER
        | list
        | VAR {
            genVarNode($1);
          }
        ;


%%
  void genVarNode(char *var_name){
    Variable *ptr = new Variable(var_name);
    if (!varListHead){
      varListHead = ptr;
      varListTail = ptr;
    } else{
      varListTail->next = ptr;
      varListTail = ptr;
    }
  }

void genPartialProblem(char type, char *info){
  PartialProblem *ptr = new PartialProblem;
  ptr->var = varListHead;
  ptr->next = nullptr;
  ptr->prev = nullptr;
  ptr->node = new Node(type, nullptr, varListHead);
  if (!firstPartProb){
    firstPartProb = ptr;
    lastPartProb = ptr;
  } else{
    lastPartProb->next = ptr;
    ptr->prev = lastPartProb;
    lastPartProb = ptr;
  }
}

Node *gen_a_node(Node *current) {
  if(current->type == 'T') {
    current->type = 'A';
    return current;
  } else {
    Node *a_node = new Node('A' , nullptr, nullptr);
    current->insertAfter(a_node);
    current->addOutput(1, 0, a_node);
    return a_node;
  }
}

Node *gen_tmp_node(Node *current) {
  Node *tmp_node = new Node('T' , nullptr, nullptr);
  current->insertAfter(tmp_node);
  current->addOutput(1, 0, tmp_node);

  return tmp_node;
}

Node *connect_with_entry(Node *left, Node *right) {
  Node *u_node = new Node('U' , nullptr, nullptr);
  if(right->type == 'T') {
    gen_a_node(right);
  }
    left->insertAfter(u_node);
    if(left->type == 'E') {
      left->addOutput(2, 'L', u_node);
  } else {
    left->addOutput(2, 0, u_node);
  }
  right->addOutput(1, 0, u_node);

  return u_node;
}

Node *gen_absolute_dependency(Node *left, Node *right) {
  if(left->type == 'A' && left->out != 0) {
    Node *c_node = new Node('C', left->out, nullptr);
    left->out = new Output(1,0,c_node);
    left->insertAfter(c_node);
    left = c_node;
  }

  Node *u_node;
  if(right->type == 'T') {
    right->type = 'U';
    left->addOutput(1, 0, right);
    u_node = right;
  } else {
    u_node = new Node('U' , nullptr, nullptr);
    right->insertAfter(u_node);
    left->addOutput(1, 0, u_node);
    right->addOutput(2, 0, u_node);
  }

  return gen_tmp_node(u_node);
}

Node *gen_g_independency(Node *left, Node *right, Variable *vars) {
  if(left->type == 'A' && left->out != 0) {
    Node *c_node = new Node('C', left->out, nullptr);
    left->out = new Output(1,0,c_node);
    left->insertAfter(c_node);
    left = c_node;
  }

  Node *g_node;
  if(right->type == 'T') {
    right->type = 'G';
    right->vars = vars;
    g_node = right;
  } else {
    g_node = new Node('G', nullptr, vars);
    right->insertAfter(g_node);
    right->addOutput(1, 0, g_node);
  }
  Node *u_node = new Node('U', nullptr, nullptr);
  g_node->insertAfter(u_node);
  left->addOutput(1, 0, u_node);
  g_node->addOutput(2, 'L', u_node);

  Node *tmp_node = gen_tmp_node(u_node);
  g_node->addOutput(1, 'R', u_node->out->target);
  return tmp_node;
}

Node *gen_i_independency(Node *left, Node *right, Variable *vars) {
  if(left->type == 'A' && left->out != 0) {
    Node *c_node = new Node('C', left->out, nullptr);
    left->out = new Output(1, 0, c_node);
    left->insertAfter(c_node);
    left = c_node;
  }

  Node *i_node;
  if(right->type == 'T') {
    right->type = 'I';
    right->vars = vars;
    i_node = right;
  } else {
    i_node = new Node('I', nullptr, vars);
    right->insertAfter(i_node);
    right->addOutput(1, 0, i_node);
  }
  Node *u_node = new Node('U', nullptr, nullptr);;
  i_node->insertAfter(u_node);
  left->addOutput(1, 0, u_node);
  i_node->addOutput(2, 'L', u_node);

  Node *tmp_node = gen_tmp_node(u_node);
  i_node->addOutput(1, 'R', u_node->out->target);
  return tmp_node;
}

Node *gen_g_i_independency(Node *left, Node *right, Variable *gVars, Variable *iVars) {
  if(left->type == 'A' && left->out != 0) {
    Node *c_node = new Node('C', left->out, nullptr);
    left->out = new Output(1, 0, c_node);
    left->insertAfter(c_node);
    left = c_node;
  }

  Node *g_node;
  if(right->type == 'T') {
    right->type = 'G';
    right->vars = gVars;
    g_node = right;
  } else {
    g_node = new Node('G', nullptr, gVars);
    right->insertAfter(g_node);
    right->addOutput(1, 0, g_node);
  }
  Node *u_node = new Node('U', nullptr, nullptr);
  Node *i_node = new Node('I', nullptr, iVars);
  g_node->insertAfter(i_node);
  i_node->insertAfter(u_node);
  left->addOutput(1, 0, u_node);
  g_node->addOutput(2, 'L', u_node);
  g_node->addOutput(1, 'R', i_node);
  i_node->addOutput(2, 'L', u_node);

  Node *tmp_node = gen_tmp_node(u_node);
  i_node->addOutput(1, 'R', u_node->out->target);
  return tmp_node;
}

Node *get_last_node(PartialProblem *pp) {
  Node *last_node = pp->node;
  while(last_node->next != 0) {
    last_node = last_node->next;
  }

  return last_node;
}

Dependency *check_dependency(PartialProblem *entry, PartialProblem *current,  PartialProblem *check) {
  Variable *entry_var = entry->var;
  Variable *current_var = current->var;
  Variable *check_var = check->var;

  Variable *check_equals = 0;
  Variable *check_different = 0;
  Variable *current_different = 0;
  Dependency *depend = new Dependency;
  depend->type = Independency::DEFAULT;
  depend->iVars = 0;
  depend->gVars = 0;

  //check for equals between current and check
  while(nullptr != current_var) {
    check_var = check->var;
    while(nullptr != check_var) {
      if(strcmp(current_var->name,check_var->name) == 0) {
        if(nullptr == check_equals) {
          check_equals = new Variable(check_var->name);
        } else {
          check_equals->appendVar(new Variable(check_var->name));
        }
      }
      check_var = check_var->next;
    }
    current_var = current_var->next;
  }

  //check for G independency/absolute dependency
  int found;
  Variable *tmp_check_equals = check_equals;
  while(nullptr != tmp_check_equals) {
    found = 0;
    entry_var = entry->var;
    while(nullptr != entry_var) {
      if(strcmp(entry_var->name,tmp_check_equals->name) == 0) {
        found = 1;
        if(nullptr == depend->gVars) {
          depend->gVars = new Variable(entry_var->name);
          depend->type = Independency::G;
        } else {
          depend->gVars->appendVar(new Variable(entry_var->name));
        }
      }
      entry_var = entry_var->next;
    }
    if(!found) {
      depend->type = Independency::DEPENDEND;
      return depend;
    }
    tmp_check_equals = tmp_check_equals->next;
  }

//look for all that are in current but not in check
  current_var = current->var;
  while(nullptr != current_var) {
    found = 0;
    tmp_check_equals = check_equals;
    while(nullptr != tmp_check_equals) {
      if(strcmp(current_var->name,tmp_check_equals->name) == 0) {
        found = 1;
      }
      tmp_check_equals = tmp_check_equals->next;
    }
    if(!found) {
      if(nullptr == current_different) {
        current_different = new Variable(current_var->name);
      } else {
        current_different->appendVar(new Variable(current_var->name));
      }
    }
    current_var = current_var->next;
  }

//check for I independency on current site and absolute independency
  while(nullptr != current_different) {
    entry_var = entry->var;
    while(nullptr != entry_var) {
      std::cout << "Current: " << current_different->name << std::endl;
      std::cout << "Entry: " << entry_var->name << std::endl;
      std::cout << "Comp: " << strcmp(current_different->name,entry_var->name) << std::endl;
      if(strcmp(current_different->name,entry_var->name) == 0) {
        if(nullptr == depend->iVars) {
          depend->iVars = new Variable(entry_var->name);
          if(depend->type == Independency::G) {
            depend->type = Independency::GI;
          } else {
            depend->type = Independency::I;
          }
        } else {
          depend->iVars->appendVar(new Variable(entry_var->name));
        }
      }
      entry_var = entry_var->next;
    }
    current_different = current_different->next;
  }
  if(depend->type == 0) {
    depend->type = Independency::ABSOLUTE;
    return depend;
  }

  if(depend->type == Independency::GI || depend->type == Independency::I) {
    //look for all that are in check but not in current
    check_var = check->var;
    while(nullptr != check_var) {
      found = 0;
      tmp_check_equals = check_equals;
      while(nullptr != tmp_check_equals) {
        if(strcmp(check_var->name,tmp_check_equals->name) == 0) {
          found = 1;
        }
        tmp_check_equals = tmp_check_equals->next;
      }
      if(!found) {
        if(nullptr == check_different) {
          check_different = new Variable(check_var->name);
          } else {
            check_different->appendVar(new Variable(check_var->name));
          }
        }
        check_var = check_var->next;
      }

      //check for i independency on check site
      while(nullptr != check_different) {
        entry_var = entry->var;
        while(nullptr != entry_var) {
          if(strcmp(check_different->name,entry_var->name) == 0) {
            if(depend->iVars == 0) {
              depend->iVars = new Variable(entry_var->name);
              if(depend->type == Independency::G) {
                depend->type = Independency::GI;
              } else {
                depend->type = Independency::I;
              }
            } else {
              depend->iVars->appendVar(new Variable(entry_var->name));
            }
          }
          entry_var = entry_var->next;
        }
        check_different = check_different->next;
      }
    }
    return depend;
  }

void paperAlgorithm(PartialProblem *current_pp) {
  PartialProblem *e_problem = current_pp;
  Node *e_node = e_problem->node;
  current_pp = current_pp->next;
  //part 2.1.1
  if(current_pp != 0) {
    e_node->addOutput(1, 'R', current_pp->node);
    Node *left_u_node = connect_with_entry(e_node,gen_a_node(current_pp->node));
    //part 2.1.2
    current_pp = current_pp->next;
    if(current_pp != 0) {
      if(current_pp->node->type == 'U'){ //second partial problem
        Node *c_node = new Node('C', nullptr, nullptr);
        e_node->insertAfter(c_node);
        c_node->addOutput(1, 0, e_node->out->target);
        e_node->out->target = c_node;
        while(current_pp != 0) {
          if(current_pp->node->type == 'U') {
            c_node->addOutput(1, 0, current_pp->node);
            PartialProblem *left_problem = current_pp->prev;
            Node *right_node = current_pp->node;
            int absolute_independency = 1;
            while(left_problem->node->type != 'E') {
              Dependency *depend = check_dependency(e_problem,current_pp,left_problem);
              if(depend->type == Independency::DEPENDEND) {
                right_node = gen_absolute_dependency(get_last_node(left_problem),right_node);
                absolute_independency = 0;
              } else if(depend->type == Independency::G) {
                printf("COMMAE ON");
                right_node = gen_g_independency(get_last_node(left_problem),right_node,depend->gVars);
                absolute_independency = 0;
              } else if(depend->type == Independency::I) {
                right_node = gen_i_independency(get_last_node(left_problem),right_node,depend->iVars);
                absolute_independency = 0;
              } else if(depend->type == Independency::GI) {
                right_node = gen_g_i_independency(get_last_node(left_problem),right_node,depend->gVars,depend->iVars);
                absolute_independency = 0;
              }
              left_problem = left_problem->prev;
            }
            if(absolute_independency) {
              right_node = gen_a_node(right_node);
            }
            left_u_node = connect_with_entry(left_u_node,right_node);
            current_pp = current_pp->next;
            } else {
              break;
            }
          }
        }

        Node *r_node = new Node('R', nullptr, nullptr);
        left_u_node->insertAfter(r_node);
        left_u_node->addOutput(1, 0, r_node);

      } else {
        Node *r_node = new Node('R', nullptr, nullptr);
        left_u_node->insertAfter(r_node);
        left_u_node->addOutput(1, 0, r_node);
      }
    } else {
      Node *r_node = new Node('R', nullptr, nullptr);
      e_node->insertAfter(r_node);
      e_node->addOutput(1, 0, r_node);
    }
  }

int main(int argc, char **argv) {

  varListHead = nullptr;
  varListTail = nullptr;
  firstPartProb = nullptr;
  lastPartProb = nullptr;

  yyparse();
  paperAlgorithm(firstPartProb);
  printTable();
  return 0;
}

Node *connect_and_number_nodes(PartialProblem *pp) {
  Node *head = pp->node;
  Node *current = head;
  int index = 1;

  while(pp!=0) {
    while(current->next!=0) {
      current->index = index;
      index++;
      current = current->next;
    }
    pp = pp->next;
    if(pp!=0) {
      current->next = pp->node;
    }
    current->index = index;
    index++;
    current = current->next;
  }

  return head;
}

void printTableEntry(Node *node){
  printf("%-5d%-3c",node->index,node->type);
  Output *out = node->out;
  while(out!=0) {
    if(out->type != 0) {
      printf("%c:(%d,%d) ",out->type,out->target->index,out->port);
    } else {
      printf("(%d,%d) ",out->target->index,out->port);
    }
    out = out->next;
  }
  Variable *vars = node->vars;
  while(vars!=0) {
    printf("%s,",vars->name);
    vars = vars->next;
  }
  printf("\n");
}

void printTable() {
  Node *current = connect_and_number_nodes(firstPartProb);

  while(current != 0) {
    printTableEntry(current);
    current = current->next;
  }
}

void yyerror (char *message){
  printf("\nThis is not a valid prolog syntax.\n");
}

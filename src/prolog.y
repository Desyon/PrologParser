%{
#include <iostream>
#include <fstream>
#include <string>
#include <string.h>

#include "../include/definitions.h"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char *yytext;

#define CHUNK 1024 /*read 1024 bytes at a time */

int problem_counter;

variable *var_head;
variable *var_tail;
partial_problem *pp_head;
partial_problem *pp_tail;

void yyerror(char *message);

void genVarNode(char *var_name);
void genPartialProblemNode(char type, char *info);

variable *genVarFromChar(char *info);
node *GenNode(char type,  output *output,  variable *vars);
void appendNode( node *current,  node *newNode);

output *genOutput(int port, char type,  node *target);
void insertOutput( output *current,  output *newOutput);
void addOutput( node *current, int port, char type,  node *target);

node *genANode(node *current);
node *connectWithEntry( node *left,  node *right);
node *genAbsoluteDependency( node *left,  node *right);
node *genGDependency( node *left,  node *right,  variable *vars);
node *genIDependency( node *left,  node *right,  variable *vars);
node *genGIDependency( node *left,  node *right,  variable *g_vars, variable *i_vars);
node *getLastNode(partial_problem *pp);

void addVariable( variable *current, char *newVar);
dependency *checkDependency( partial_problem *entry,  partial_problem *current,  partial_problem *check);

node *connectAndNumberNodes( partial_problem *pp);
void printTable();
int printTableEntries( node *node,FILE *output_stream);

void checkForEquals(variable *current_var, variable *check_var, partial_problem *check, variable *check_equals){
	while(current_var != nullptr) {
			check_var = check->var;
			while(check_var != nullptr) {
				if(strcmp(current_var->name,check_var->name) == 0) {
					if(check_equals == nullptr) {
						check_equals = new variable;
						check_equals->name = check_var->name;
						check_equals->next = nullptr;
					} else {
						addVariable(check_equals,check_var->name);
					}
				}
				check_var = check_var->next;
			}
			current_var = current_var->next;
		}
	}

	void checkGAbs(variable *check_equals, variable *entry_var, dependency *depend, partial_problem *entry){
	int found = 0;
			 variable *tmp_check_equals = check_equals;
		while(tmp_check_equals != nullptr) {
			found = 0;
			entry_var = entry->var;
			while(entry_var != nullptr) {
				if(strcmp(entry_var->name,tmp_check_equals->name) == 0) {
					found = 1;
					if(depend->g_vars == nullptr) {
						depend->g_vars = new variable;
						depend->g_vars->name = entry_var->name;
						depend->type = Independency::G;
						depend->g_vars->next = nullptr;
					} else {
						addVariable(depend->g_vars,entry_var->name);
					}
				}
				entry_var = entry_var->next;
			}
			if(!found) {
				depend->type = Independency::DEPENDEND;
				return;
			}
			tmp_check_equals = tmp_check_equals->next;
		}
}

void schwinnAlgorithm( partial_problem *current_pp);
int table_counter = 1;

using namespace std;
%}

  %union{
    char *str;
    int num;
  }

  %start clause
  %token DEF DOT
  %token PLUS MINUS EQUAL NOT IS
  %token UNEQUAL SMALLER SEQUAL GREATER GEQUAL
  %token COMMA POPEN PCLOSE LOPEN LCLOSE PIPE ASTERISK COLON DIV
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
        genPartialProblemNode('E',$1); var_head = nullptr;
      }
      ;

subRule:  CONST POPEN params PCLOSE {
            genPartialProblemNode('U', $1); var_head = nullptr;
          }
          | arithmeticExpr {
              genPartialProblemNode('U',""); var_head = nullptr;
          }
          ;

arithmeticExpr: VAR operator arithmeticRhs;

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

arithmeticRhs:  VAR
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
  variable *ptr = new variable;
  ptr->name = var_name;
  ptr->next = nullptr;
  if (nullptr == var_head){ // Head not set yet
    var_head = ptr;
    var_tail = ptr;
  } else {
    var_tail->next = ptr;
    var_tail = ptr;
  }
}

void genPartialProblemNode(char type, char *info){
  partial_problem *ptr = new partial_problem;
  ptr->var = var_head;
  ptr->next = nullptr;
  ptr->prev = nullptr;
  ptr->node = GenNode(type,0,var_head);
  if (!pp_head) {
    pp_head = ptr;
    pp_tail = ptr;
    } else {
      pp_tail->next = ptr;
      ptr->prev = pp_tail;
      pp_tail = ptr;
    }
  }

  variable *genVarFromChar(char *info) {
    variable *var = new variable;
    var->next = nullptr;
    var->name = info;
    return var;
  }

node *GenNode(char type,  output *output,  variable *vars) {
  node *tmp = new node;
  tmp->type = type;
  tmp->out = output;
  tmp->vars = vars;
  tmp->next = nullptr;
  tmp->prev = nullptr;

  return tmp;
}

void appendNode( node *current,  node *newNode) {
  newNode->next = current->next;
  if(current->next != nullptr) {
    current->next->prev = newNode;
  }
  newNode->prev = current;
  current->next = newNode;
}

output *genOutput(int port, char type,  node *target) {
  output *tmp = new output;
  tmp->port = port;
  tmp->type = type;
  tmp->target = target;
  tmp->next = nullptr;

  return tmp;
}

void insertOutput( output *current,  output *newOutput) {
  newOutput->next = current->next;
  current->next = newOutput;
}

void addOutput( node *current, int port, char type,  node *target) {
  if(current->out != nullptr) {
    output *last = current->out;
    while(last->next != nullptr) {
      last = last->next;
    }
    insertOutput(last,genOutput(port,type,target));
    } else {
      current->out = genOutput(port,type,target);
  }
}

node *genANode( node *current) {
  if(current->type == 'T') {
    current->type = 'A';
    return current;
  } else {
    node *a_node = GenNode('A',0,0);
    appendNode(current,a_node);
    addOutput(current,1,0,a_node);
    return a_node;
  }
}

node *gen_tmp_node( node *current) {
  node *tmp_node = GenNode('T',0,0);
  appendNode(current,tmp_node);
  addOutput(current,1,0,tmp_node);

  return tmp_node;
}

node *connectWithEntry( node *left,  node *right) {
  node *u_node = GenNode('U',0,0);
  if(right->type == 'T') {
    genANode(right);
  }
  appendNode(left,u_node);
  if(left->type == 'E') {
    addOutput(left,2,'L',u_node);
  } else {
    addOutput(left,2,0,u_node);
  }
  addOutput(right,1,0,u_node);

  return u_node;
}

node *genAbsoluteDependency( node *left,  node *right) {
  if(left->type == 'A' && left->out != 0) {
    node *c_node = GenNode('C',left->out,0);
    left->out = genOutput(1,0,c_node);
    appendNode(left,c_node);
    left = c_node;
}

node *u_node;
  if(right->type == 'T') {
    right->type = 'U';
    addOutput(left,1,0,right);
    u_node = right;
  } else {
    u_node = GenNode('U',0,0);
    appendNode(right,u_node);
    addOutput(left,1,0,u_node);
    addOutput(right,2,0,u_node);
  }

  return gen_tmp_node(u_node);
}

node *genGDependency( node *left,  node *right,  variable *vars) {
  if(left->type == 'A' && left->out != 0) {
    node *c_node = GenNode('C',left->out,0);
    left->out = genOutput(1,0,c_node);
    appendNode(left,c_node);
    left = c_node;
  }

  node *g_node;
  if(right->type == 'T') {
    right->type = 'G';
    right->vars = vars;
    g_node = right;
  } else {
    g_node = GenNode('G',0,vars);
    appendNode(right,g_node);
    addOutput(right,1,0,g_node);
  }
  node *u_node = GenNode('U',0,0);
  appendNode(g_node,u_node);
  addOutput(left,1,0,u_node);
  addOutput(g_node,2,'L',u_node);

  node *tmp_node = gen_tmp_node(u_node);
  addOutput(g_node,1,'R',u_node->out->target);

  return tmp_node;
}

node *genIDependency( node *left,  node *right,  variable *vars) {
  if(left->type == 'A' && left->out != 0) {
    node *c_node = GenNode('C',left->out,0);
    left->out = genOutput(1,0,c_node);
    appendNode(left,c_node);
    left = c_node;
  }

  node *i_node;
  if(right->type == 'T') {
    right->type = 'I';
    right->vars = vars;
    i_node = right;
    } else {
      i_node = GenNode('I',0,vars);
      appendNode(right,i_node);
      addOutput(right,1,0,i_node);
    }
    node *u_node = GenNode('U',0,0);
    appendNode(i_node,u_node);
    addOutput(left,1,0,u_node);
    addOutput(i_node,2,'L',u_node);

    node *tmp_node = gen_tmp_node(u_node);
    addOutput(i_node,1,'R',u_node->out->target);

    return tmp_node;
}

node *genGIDependency( node *left,  node *right,  variable *g_vars,  variable *i_vars) {
  if(left->type == 'A' && left->out != 0) {
    node *c_node = GenNode('C',left->out,0);
    left->out = genOutput(1,0,c_node);
    appendNode(left,c_node);
    left = c_node;
  }

  node *g_node;
  if(right->type == 'T') {
    right->type = 'G';
    right->vars = g_vars;
    g_node = right;
  } else {
    g_node = GenNode('G',0,g_vars);
    appendNode(right,g_node);
    addOutput(right,1,0,g_node);
  }
  node *u_node = GenNode('U',0,0);
  node *i_node = GenNode('I',0,i_vars);
  appendNode(g_node,i_node);
  appendNode(i_node,u_node);
  addOutput(left,1,0,u_node);
  addOutput(g_node,2,'L',u_node);
  addOutput(g_node,1,'R',i_node);
  addOutput(i_node,2,'L',u_node);

  node *tmp_node = gen_tmp_node(u_node);
  addOutput(i_node,1,'R',u_node->out->target);

  return tmp_node;
}

node *getLastNode( partial_problem *pp) {
  node *last_node = pp->node;
  while(last_node->next != nullptr) {
    last_node = last_node->next;
  }

  return last_node;
}

void addVariable( variable *current, char *newVar) {
  variable * tmp = new variable;
  tmp->name = newVar;
  tmp->next = nullptr;
  while(current->next != nullptr) {
    current = current->next;
  }
  current->next = tmp;
}

dependency *checkDependency( partial_problem *entry,  partial_problem *current,  partial_problem *check) {
  variable *entry_var = entry->var;
  variable *current_var = current->var;
  variable *check_var = check->var;

  variable *check_equals = nullptr;
  variable *check_different = nullptr;
  variable *current_different = nullptr;
  dependency *depend = new dependency;
  depend->type = Independency::DEFAULT;
  depend->i_vars = nullptr;
  depend->g_vars = nullptr;

  //check for equals between current and check
  checkForEquals(current_var, check_var, check, check_equals);

  // TODO Put into function
  //check for G independency/absolute dependency
  int found;
  variable *tmp_check_equals = check_equals;
  while(tmp_check_equals != nullptr) {
    found = 0;
    entry_var = entry->var;
    while(entry_var != nullptr) {
      if(strcmp(entry_var->name,tmp_check_equals->name) == 0) {
        found = 1;
        if(depend->g_vars == nullptr) {
          depend->g_vars = new variable;
          depend->g_vars->name = entry_var->name;
          depend->type = Independency::G;
          depend->g_vars->next = nullptr;
        } else {
          addVariable(depend->g_vars,entry_var->name);
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

  // TODO Put into function
  //look for all that are in current but not in check
  current_var = current->var;
  while(current_var != nullptr) {
    found = 0;
    tmp_check_equals = check_equals;
    while(tmp_check_equals != nullptr) {
      if(strcmp(current_var->name,tmp_check_equals->name) == 0) {
        found = 1;
      }
      tmp_check_equals = tmp_check_equals->next;
    }
    if(!found) {
      if(current_different == nullptr) {
        current_different = new variable;
        current_different->name = current_var->name;
        current_different->next = nullptr;
      } else {
        addVariable(current_different,current_var->name);
      }
    }
    current_var = current_var->next;
  }

  // TODO Put into function
  //check for I independency on current site and absolute independency
  while(current_different != nullptr) {
    entry_var = entry->var;
    while(entry_var != nullptr) {
      if(strcmp(current_different->name,entry_var->name) == 0) {
        if(depend->i_vars == nullptr) {
          depend->i_vars = new variable;
          depend->i_vars->name = entry_var->name;
          if(depend->type == Independency::G) {
            depend->type = Independency::GI;
          } else {
            depend->type = Independency::I;
          }
          depend->i_vars->next = nullptr;
        } else {
          addVariable(depend->i_vars,entry_var->name);
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
    // TODO Put into function
    while(check_var != nullptr) {
      found = 0;
      tmp_check_equals = check_equals;
      while(tmp_check_equals != nullptr) {
        if(strcmp(check_var->name,tmp_check_equals->name) == 0) {
          found = 1;
        }
        tmp_check_equals = tmp_check_equals->next;
      }
      if(!found) {
        if(check_different == nullptr) {
          check_different = new variable;
          check_different->name = check_var->name;
          check_different->next = nullptr;
        } else {
          addVariable(check_different,check_var->name);
        }
      }
      check_var = check_var->next;
    }

    // TODO Put into function
    //check for i independency on check site
    while(check_different != nullptr) {
      entry_var = entry->var;
      while(entry_var != nullptr) {
        if(strcmp(check_different->name,entry_var->name) == 0) {
          if(depend->i_vars == nullptr) {
            depend->i_vars = new variable;
            depend->i_vars->name = entry_var->name;
            if(depend->type == Independency::G) {
              depend->type = Independency::GI;
            } else {
              depend->type = Independency::I;
            }
            depend->i_vars->next = nullptr;
          } else {
            addVariable(depend->i_vars,entry_var->name);
          }
        }
        entry_var = entry_var->next;
      }
      check_different = check_different->next;
    }
  }
  return depend;
  }

void schwinnAlgorithm( partial_problem *current_pp) {
  partial_problem *e_problem = current_pp;
  node *e_node = e_problem->node;
  current_pp = current_pp->next;
  //part 2.1.1
  if(current_pp != nullptr) {
    addOutput(e_node,1,'R',current_pp->node);
    node *left_u_node = connectWithEntry(e_node,genANode(current_pp->node));
    //part 2.1.2
    current_pp = current_pp->next;
    if(current_pp != nullptr) {
      if(current_pp->node->type == 'U'){ //second partial problem
        node *c_node = GenNode('C',0,0);
        appendNode(e_node,c_node);
        addOutput(c_node,1,0,e_node->out->target);
        e_node->out->target = c_node;
        while(current_pp != nullptr) {
          std::cout << "INFO:\tIn Loop" << std::endl;
          if(current_pp->node->type == 'U') {
            addOutput(c_node,1,0,current_pp->node);
            partial_problem *left_problem = current_pp->prev;
            node *right_node = current_pp->node;
            int absolute_independency = 1;
            while(left_problem->node->type != 'E') {
              dependency *depend = checkDependency(e_problem,current_pp,left_problem);
              if(depend->type == Independency::DEPENDEND) {
                right_node = genAbsoluteDependency(getLastNode(left_problem),right_node);
                absolute_independency = 0;
              } else if (depend->type == Independency::G) {
                right_node = genGDependency(getLastNode(left_problem),right_node,depend->g_vars);
                absolute_independency = 0;
              } else if (depend->type == Independency::I) {
                right_node = genIDependency(getLastNode(left_problem),right_node,depend->i_vars);
                absolute_independency = 0;
              } else if(depend->type == Independency::GI) {
                right_node = genGIDependency(getLastNode(left_problem),right_node,depend->g_vars,depend->i_vars);
                absolute_independency = 0;
              }
              left_problem = left_problem->prev;
            }
            if(absolute_independency) {
              right_node = genANode(right_node);
            }
            left_u_node = connectWithEntry(left_u_node,right_node);
            current_pp = current_pp->next;
          } else {
            break;
          }
        }
      }

      node *r_node = GenNode('R',0,0);
      appendNode(left_u_node,r_node);
      addOutput(left_u_node,1,0,r_node);

      } else {
        node *r_node = GenNode('R',0,0);
        appendNode(left_u_node,r_node);
        addOutput(left_u_node,1,0,r_node);
      }
    } else {
      node *r_node = GenNode('R',0,0);
      appendNode(e_node,r_node);
      addOutput(e_node,1,0,r_node);
    }
}

int main(int argc, char **argv) {
  std::cout << "INFO:\tProgram started.\n" << std::endl;

  var_head = nullptr;
  var_tail = nullptr;
  pp_head = nullptr;
  pp_tail = nullptr;

  yyparse();
  std::cout << "INFO:\tStarting Schwinn...\n" << std::endl;
  schwinnAlgorithm(pp_head);
  std::cout << "INFO:\tPrinting Node-Table...\n" << std::endl;
  printTable();
  std::cout << "INFO:\tSuccess.\n" << std::endl;
  return 0;
}

node *connectAndNumberNodes( partial_problem *pp) {
  node *head = pp->node;
  node *current = head;
  int index = 1;

  while(pp!=nullptr) {
    while(current->next!=nullptr) {
      current->index = index;
      index++;
       current = current->next;
     }
     pp = pp->next;
     if(pp!=nullptr) {
       current->next = pp->node;
     }
     current->index = index;
     index++;
     current = current->next;
  }

  return head;
}

void printTableEntry( node *node, ofstream &os){
  os << node->index << "\t| " << node->type << " | ";

  output *out = node->out;

  while (out) {
    if (out->type) {
      os << out->type << ": (" << out->target->index << "," << out->port << ") ";
    } else {
      os << "(" << out->target->index << "," << out->port << ") ";
    }
    out = out->next;
  }

  os << "| ";

  variable *vars = node->vars;

  while (vars) {
    os << vars->name << ",";
    vars = vars->next;
  }
  os << endl;
}

void printTable() {
  node *current = connectAndNumberNodes(pp_head);

  ofstream os;
  os.open("output.md");

  // insert header of the MD table_out
  os << "Node ID | Node Type | Output | Comment" << endl;
  os << ":------ | :-------- | :----- | :------" << endl;

  while(current != 0) {
    printTableEntry(current, os);
    current = current->next;
  }

  os.close();
}

void yyerror (char *message){
  std::cout << "\nParser Error in line " << lines << std::endl << ":" << message << std::endl;
}

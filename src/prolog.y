%{
  #include <iostream>
  #include <fstream>
  #include <string>
	#include <stdio.h>
	#include <string.h>

	extern "C" int yylex();
	extern "C" int yyparse();
	extern "C" FILE *yyin;
	extern "C" int lines;
	extern "C" char *yytext;

	#define CHUNK 1024 /*read 1024 bytes at a time */
	#define ABSOLUTE_DEPENDENCY 1
	#define G_INDEPENDENCY 2
	#define I_INDEPENDENCY 3
	#define GI_INDEPENDENCY 4
	#define ABSOLUTE_INDEPENDENCY 5

	int problem_counter;

  struct variable *var_head;
	struct variable *var_tail;
	struct partial_problem *pp_head;
	struct partial_problem *pp_tail;

	struct variable {
		char *name;
		struct variable *next;
	};
	struct partial_problem {
		struct variable *var;
		struct node *node;
		struct partial_problem *next;
		struct partial_problem *prev;
	};
	struct node {
		int index;
		char type;
		struct variable *vars;
		struct output *out;
		struct node *next;
		struct node *prev;
	};
	struct output {
		int port;
		char type;
		struct node *target;
		struct output *next;
	};
	struct dependency {
		int type;
		struct variable *g_vars;
		struct variable *i_vars;
	};

	void yyerror(char *message);

	void genVarNode(char *var_name);
	void gebPartialProblemNode(char type, char *info);

	struct variable *genVarFromChar(char *info);
	struct node *GenNode(char type, struct output *output, struct variable *vars);
	void appendNode(struct node *current, struct node *newNode);

	struct output *genOutput(int port, char type, struct node *target);
	void insertOutput(struct output *current, struct output *newOutput);
	void addOutput(struct node *current, int port, char type, struct node *target);

	struct node *genANode(struct node *current);
	struct node *connectWithEntry(struct node *left, struct node *right);
	struct node *genAbsoluteDependency(struct node *left, struct node *right);
	struct node *genGDependency(struct node *left, struct node *right, struct variable *vars);
	struct node *genIDependency(struct node *left, struct node *right, struct variable *vars);
	struct node *genGIDependency(struct node *left, struct node *right, struct variable *g_vars, struct variable *i_vars);
	struct node *getLastNode(struct partial_problem *pp);

	void addVariable(struct variable *current, char *newVar);
	struct dependency *checkDependency(struct partial_problem *entry, struct partial_problem *current, struct partial_problem *check);

	struct node *connectAndNumberNodes(struct partial_problem *pp);
	void printTable();
	int printTableEntries(struct node *node,FILE *output_stream);

	void schwinnAlgorithm(struct partial_problem *current_pp);
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
					gebPartialProblemNode('E',$1); var_head = 0;
				}
				;

	subRule: CONST POPEN params PCLOSE {
						gebPartialProblemNode('U', $1); var_head = 0;
					}
					| arithmeticExpr {
							gebPartialProblemNode('U',""); var_head = 0;
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

	arithmeticRhs: 	VAR
									| NUMBER
									| CONST
									| arithmeticExpr
									;

	params: param COMMA params
					| param
					;

	factList:	 subRule COMMA factList
						| subRule
						;

	list: LOPEN lelements LCLOSE
				| LOPEN lelements PIPE lelements LCLOSE
				| LOPEN LCLOSE
				;

	lelements:	lelement
							| lelement COMMA lelements
							;

	lelement: VAR {
							genVarNode($1);
						}
						| NUMBER
						| list
						;

	param:	CONST
					| NUMBER
					| list
					| VAR {
							genVarNode($1);
						}
					;
	%%
	void genVarNode(char *var_name){
		struct variable *ptr = new variable;
		ptr->name = var_name;
		ptr->next = 0;
		if (!var_head){
			var_head = ptr;
			var_tail = ptr;
		} else{
			var_tail->next = ptr;
			var_tail = ptr;
		}
	}
	void gebPartialProblemNode(char type, char *info){
		struct partial_problem *ptr = new partial_problem;
		ptr->var = var_head;
		ptr->next = 0;
		ptr->prev = 0;
		ptr->node = GenNode(type,0,var_head);
		if (!pp_head){
			pp_head = ptr;
			pp_tail = ptr;
		} else{
			pp_tail->next = ptr;
			ptr->prev = pp_tail;
			pp_tail = ptr;
		}
	}
	struct variable *genVarFromChar(char *info) {
		struct variable *var = new variable;
		var->next = 0;
		var->name = info;
		return var;
	}

	struct node *GenNode(char type, struct output *output, struct variable *vars) {
		struct node *tmp = new node;
		tmp->type = type;
		tmp->out = output;
		tmp->vars = vars;
		tmp->next = 0;
		tmp->prev = 0;

		return tmp;
	}

	void appendNode(struct node *current, struct node *newNode) {
		newNode->next = current->next;
		if(current->next != 0) {
			current->next->prev = newNode;
		}
		newNode->prev = current;
		current->next = newNode;
	}

	struct output *genOutput(int port, char type, struct node *target) {
		struct output *tmp = new output;
		tmp->port = port;
		tmp->type = type;
		tmp->target = target;
		tmp->next = 0;

		return tmp;
	}
	void insertOutput(struct output *current, struct output *newOutput) {
		newOutput->next = current->next;
		current->next = newOutput;
	}
	void addOutput(struct node *current, int port, char type, struct node *target) {
		if(current->out != 0) {
			struct output *last = current->out;
			while(last->next != 0) {
				last = last->next;
			}
			insertOutput(last,genOutput(port,type,target));
		} else {
			current->out = genOutput(port,type,target);
		}
	}

	struct node *genANode(struct node *current) {
		if(current->type == 'T') {
			current->type = 'A';
			return current;
		} else {
			struct node *a_node = GenNode('A',0,0);
			appendNode(current,a_node);
			addOutput(current,1,0,a_node);
			return a_node;
		}
	}
	struct node *gen_tmp_node(struct node *current) {
		struct node *tmp_node = GenNode('T',0,0);
		appendNode(current,tmp_node);
		addOutput(current,1,0,tmp_node);

		return tmp_node;
	}
	struct node *connectWithEntry(struct node *left, struct node *right) {
		struct node *u_node = GenNode('U',0,0);
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
	struct node *genAbsoluteDependency(struct node *left, struct node *right) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = GenNode('C',left->out,0);
			left->out = genOutput(1,0,c_node);
			appendNode(left,c_node);
			left = c_node;
		}

		struct node *u_node;
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
	struct node *genGDependency(struct node *left, struct node *right, struct variable *vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = GenNode('C',left->out,0);
			left->out = genOutput(1,0,c_node);
			appendNode(left,c_node);
			left = c_node;
		}

		struct node *g_node;
		if(right->type == 'T') {
			right->type = 'G';
			right->vars = vars;
			g_node = right;
		} else {
			g_node = GenNode('G',0,vars);
			appendNode(right,g_node);
			addOutput(right,1,0,g_node);
		}
		struct node *u_node = GenNode('U',0,0);
		appendNode(g_node,u_node);
		addOutput(left,1,0,u_node);
		addOutput(g_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		addOutput(g_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *genIDependency(struct node *left, struct node *right, struct variable *vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = GenNode('C',left->out,0);
			left->out = genOutput(1,0,c_node);
			appendNode(left,c_node);
			left = c_node;
		}

		struct node *i_node;
		if(right->type == 'T') {
			right->type = 'I';
			right->vars = vars;
			i_node = right;
		} else {
			i_node = GenNode('I',0,vars);
			appendNode(right,i_node);
			addOutput(right,1,0,i_node);
		}
		struct node *u_node = GenNode('U',0,0);
		appendNode(i_node,u_node);
		addOutput(left,1,0,u_node);
		addOutput(i_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		addOutput(i_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *genGIDependency(struct node *left, struct node *right, struct variable *g_vars, struct variable *i_vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = GenNode('C',left->out,0);
			left->out = genOutput(1,0,c_node);
			appendNode(left,c_node);
			left = c_node;
		}

		struct node *g_node;
		if(right->type == 'T') {
			right->type = 'G';
			right->vars = g_vars;
			g_node = right;
		} else {
			g_node = GenNode('G',0,g_vars);
			appendNode(right,g_node);
			addOutput(right,1,0,g_node);
		}
		struct node *u_node = GenNode('U',0,0);
		struct node *i_node = GenNode('I',0,i_vars);
		appendNode(g_node,i_node);
		appendNode(i_node,u_node);
		addOutput(left,1,0,u_node);
		addOutput(g_node,2,'L',u_node);
		addOutput(g_node,1,'R',i_node);
		addOutput(i_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		addOutput(i_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *getLastNode(struct partial_problem *pp) {
		struct node *last_node = pp->node;
		while(last_node->next != 0) {
			last_node = last_node->next;
		}
		return last_node;
	}

	void addVariable(struct variable *current, char *newVar) {
			struct variable * tmp = new variable;
			tmp->name = newVar;
			tmp->next = 0;
			while(current->next != 0) {
				current = current->next;
			}
			current->next = tmp;
	}
	struct dependency *checkDependency(struct partial_problem *entry, struct partial_problem *current, struct partial_problem *check) {
		struct variable *entry_var = entry->var;
		struct variable *current_var = current->var;
		struct variable *check_var = check->var;

		struct variable *check_equals = 0;
		struct variable *check_different = 0;
		struct variable *current_different = 0;
		struct dependency *depend = new dependency;
		depend->type = 0;
		depend->i_vars = 0;
		depend->g_vars = 0;

		//check for equals between current and check
		while(current_var != 0) {
			check_var = check->var;
			while(check_var != 0) {
				if(strcmp(current_var->name,check_var->name) == 0) {
					if(check_equals == 0) {
						check_equals = new variable;
						check_equals->name = check_var->name;
						check_equals->next = 0;
					} else {
						addVariable(check_equals,check_var->name);
					}
				}
				check_var = check_var->next;
			}
			current_var = current_var->next;
		}

		//check for G independency/absolute dependency
		int found;
		struct variable *tmp_check_equals = check_equals;
		while(tmp_check_equals != 0) {
			found = 0;
			entry_var = entry->var;
			while(entry_var != 0) {
				if(strcmp(entry_var->name,tmp_check_equals->name) == 0) {
					found = 1;
					if(depend->g_vars == 0) {
						depend->g_vars = new variable;
						depend->g_vars->name = entry_var->name;
						depend->type = G_INDEPENDENCY;
						depend->g_vars->next = 0;
					} else {
						addVariable(depend->g_vars,entry_var->name);
					}
				}
				entry_var = entry_var->next;
			}
			if(!found) {
				depend->type = ABSOLUTE_DEPENDENCY;
				return depend;
			}
			tmp_check_equals = tmp_check_equals->next;
		}

		//look for all that are in current but not in check
		current_var = current->var;
		while(current_var != 0) {
			found = 0;
			tmp_check_equals = check_equals;
			while(tmp_check_equals != 0) {
				if(strcmp(current_var->name,tmp_check_equals->name) == 0) {
					found = 1;
				}
				tmp_check_equals = tmp_check_equals->next;
			}
			if(!found) {
				if(current_different == 0) {
					current_different = new variable;
					current_different->name = current_var->name;
					current_different->next = 0;
				} else {
					addVariable(current_different,current_var->name);
				}
			}
			current_var = current_var->next;
		}

		//check for I independency on current site and absolute independency
		while(current_different != 0) {
			entry_var = entry->var;
			while(entry_var != 0) {
				if(strcmp(current_different->name,entry_var->name) == 0) {
					if(depend->i_vars == 0) {
						depend->i_vars = new variable;
						depend->i_vars->name = entry_var->name;
						if(depend->type == G_INDEPENDENCY) {
							depend->type = GI_INDEPENDENCY;
						} else {
							depend->type = I_INDEPENDENCY;
						}
						depend->i_vars->next = 0;
					} else {
						addVariable(depend->i_vars,entry_var->name);
					}
				}
				entry_var = entry_var->next;
			}
			current_different = current_different->next;
		}
		if(depend->type == 0) {
			depend->type = ABSOLUTE_INDEPENDENCY;
			return depend;
		}

		if(depend->type == GI_INDEPENDENCY || depend->type == I_INDEPENDENCY) {
			//look for all that are in check but not in current
			check_var = check->var;
			while(check_var != 0) {
				found = 0;
				tmp_check_equals = check_equals;
				while(tmp_check_equals != 0) {
					if(strcmp(check_var->name,tmp_check_equals->name) == 0) {
						found = 1;
					}
					tmp_check_equals = tmp_check_equals->next;
				}
				if(!found) {
					if(check_different == 0) {
						check_different = new variable;
						check_different->name = check_var->name;
						check_different->next = 0;
					} else {
						addVariable(check_different,check_var->name);
					}
				}
				check_var = check_var->next;
			}

			//check for i independency on check site
			while(check_different != 0) {
				entry_var = entry->var;
				while(entry_var != 0) {
					if(strcmp(check_different->name,entry_var->name) == 0) {
						if(depend->i_vars == 0) {
							depend->i_vars = new variable;
							depend->i_vars->name = entry_var->name;
							if(depend->type == G_INDEPENDENCY) {
								depend->type = GI_INDEPENDENCY;
							} else {
								depend->type = I_INDEPENDENCY;
							}
							depend->i_vars->next = 0;
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

	void schwinnAlgorithm(struct partial_problem *current_pp) {
		struct partial_problem *e_problem = current_pp;
		struct node *e_node = e_problem->node;
		current_pp = current_pp->next;
		//part 2.1.1
		if(current_pp != 0) {
			addOutput(e_node,1,'R',current_pp->node);
			struct node *left_u_node = connectWithEntry(e_node,genANode(current_pp->node));
			//part 2.1.2
			current_pp = current_pp->next;
			if(current_pp != 0) {
				if(current_pp->node->type == 'U'){ //second partial problem
					struct node *c_node = GenNode('C',0,0);
					appendNode(e_node,c_node);
					addOutput(c_node,1,0,e_node->out->target);
					e_node->out->target = c_node;
					while(current_pp != 0) {
						std::cout << "INFO:\tIn Loop" << std::endl;
						if(current_pp->node->type == 'U') {
						addOutput(c_node,1,0,current_pp->node);
						struct partial_problem *left_problem = current_pp->prev;
						struct node *right_node = current_pp->node;
						int absolute_independency = 1;
						while(left_problem->node->type != 'E') {
							struct dependency *depend = checkDependency(e_problem,current_pp,left_problem);
							if(depend->type == ABSOLUTE_DEPENDENCY) {
								right_node = genAbsoluteDependency(getLastNode(left_problem),right_node);
								absolute_independency = 0;
							} else if(depend->type == G_INDEPENDENCY) {
								right_node = genGDependency(getLastNode(left_problem),right_node,depend->g_vars);
								absolute_independency = 0;
							} else if(depend->type == I_INDEPENDENCY) {
								right_node = genIDependency(getLastNode(left_problem),right_node,depend->i_vars);
								absolute_independency = 0;
							} else if(depend->type == GI_INDEPENDENCY) {
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

				struct node *r_node = GenNode('R',0,0);
				appendNode(left_u_node,r_node);
				addOutput(left_u_node,1,0,r_node);

			} else {
				struct node *r_node = GenNode('R',0,0);
				appendNode(left_u_node,r_node);
				addOutput(left_u_node,1,0,r_node);
			}
		} else {
			struct node *r_node = GenNode('R',0,0);
			appendNode(e_node,r_node);
			addOutput(e_node,1,0,r_node);
		}
	}

	int main(int argc, char **argv) {
		std::cout << "INFO:\tProgram started.\n" << std::endl;

		var_head = 0;
		var_tail = 0;
		pp_head = 0;
		pp_tail = 0;

		yyparse();
		std::cout << "INFO:\tStarting Schwinn...\n" << std::endl;
		schwinnAlgorithm(pp_head);
		std::cout << "INFO:\tPrinting Node-Table...\n" << std::endl;
		printTable();
		std::cout << "INFO:\tSuccess.\n" << std::endl;
		return 0;
	}

	struct node *connectAndNumberNodes(struct partial_problem *pp) {
		struct node *head = pp->node;
		struct node *current = head;
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

	void printTableEntry(struct node *node, ofstream &os){
    os << node->index << "\t| " << node->type << " | ";

    struct output *out = node->out;

    while (out) {
      if (out->type) {
        os << out->type << ": (" << out->target->index << "," << out->port << ") ";
      } else {
        os << "(" << out->target->index << "," << out->port << ") ";
      }
      out = out->next;
    }

    os << "| ";

    struct variable *vars = node->vars;

    while (vars) {
      os << vars->name << ",";
      vars = vars->next;
    }
    os << endl;
	}

	void printTable() {
		struct node *current = connectAndNumberNodes(pp_head);

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

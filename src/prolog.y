%{
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

	void gen_var_node(char *var_name);
	void gen_partial_problem_node(char type, char *info);

	struct variable *gen_var_from_char(char *info);
	struct node *gen_node(char type, struct output *output, struct variable *vars);
	void insert_node_before(struct node *current, struct node *newNode);
	void insert_node_after(struct node *current, struct node *newNode);

	struct output *gen_output(int port, char type, struct node *target);
	void insert_output(struct output *current, struct output *newOutput);
	void add_output(struct node *current, int port, char type, struct node *target);

	struct node *gen_a_node(struct node *current);
	struct node *connect_with_entry(struct node *left, struct node *right);
	struct node *gen_absolute_dependency(struct node *left, struct node *right);
	struct node *gen_g_independency(struct node *left, struct node *right, struct variable *vars);
	struct node *gen_i_independency(struct node *left, struct node *right, struct variable *vars);
	struct node *gen_g_i_independency(struct node *left, struct node *right, struct variable *g_vars, struct variable *i_vars);
	struct node *get_last_node(struct partial_problem *pp);

	void add_variable(struct variable *current, char *newVar);
	struct dependency *check_dependency(struct partial_problem *entry, struct partial_problem *current, struct partial_problem *check);

	struct node *connect_and_number_nodes(struct partial_problem *pp);
	void print_table();
	int print_table_entries(struct node *node,FILE *output_stream);

	void schwinn(struct partial_problem *current_pp);
	int table_counter = 1;
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
					gen_partial_problem_node('E',$1); var_head = 0;
				}
				;

	subRule: CONST POPEN params PCLOSE {
						gen_partial_problem_node('U', $1); var_head = 0;
					}
					| arithmeticExpr {
							gen_partial_problem_node('U',""); var_head = 0;
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
							gen_var_node($1);
						}
						| NUMBER
						| list
						;

	param:	CONST
					| NUMBER
					| list
					| VAR {
							gen_var_node($1);
						}
					;
	%%
	void gen_var_node(char *var_name){
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
	void gen_partial_problem_node(char type, char *info){
		struct partial_problem *ptr = new partial_problem;
		ptr->var = var_head;
		ptr->next = 0;
		ptr->prev = 0;
		ptr->node = gen_node(type,0,var_head);
		if (!pp_head){
			pp_head = ptr;
			pp_tail = ptr;
		} else{
			pp_tail->next = ptr;
			ptr->prev = pp_tail;
			pp_tail = ptr;
		}
	}
	struct variable *gen_var_from_char(char *info) {
		struct variable *var = new variable;
		var->next = 0;
		var->name = info;
		return var;
	}

	struct node *gen_node(char type, struct output *output, struct variable *vars) {
		struct node *tmp = new node;
		tmp->type = type;
		tmp->out = output;
		tmp->vars = vars;
		tmp->next = 0;
		tmp->prev = 0;

		return tmp;
	}
	void insert_node_before(struct node *current, struct node *newNode) {
		newNode->prev = current->prev;
		current->prev->next = newNode;
		newNode->next = current;
		current->prev = newNode;
	}
	void insert_node_after(struct node *current, struct node *newNode) {
		newNode->next = current->next;
		if(current->next != 0) {
			current->next->prev = newNode;
		}
		newNode->prev = current;
		current->next = newNode;
	}

	struct output *gen_output(int port, char type, struct node *target) {
		struct output *tmp = new output;
		tmp->port = port;
		tmp->type = type;
		tmp->target = target;
		tmp->next = 0;

		return tmp;
	}
	void insert_output(struct output *current, struct output *newOutput) {
		newOutput->next = current->next;
		current->next = newOutput;
	}
	void add_output(struct node *current, int port, char type, struct node *target) {
		if(current->out != 0) {
			struct output *last = current->out;
			while(last->next != 0) {
				last = last->next;
			}
			insert_output(last,gen_output(port,type,target));
		} else {
			current->out = gen_output(port,type,target);
		}
	}

	struct node *gen_a_node(struct node *current) {
		if(current->type == 'T') {
			current->type = 'A';
			return current;
		} else {
			struct node *a_node = gen_node('A',0,0);
			insert_node_after(current,a_node);
			add_output(current,1,0,a_node);
			return a_node;
		}
	}
	struct node *gen_tmp_node(struct node *current) {
		struct node *tmp_node = gen_node('T',0,0);
		insert_node_after(current,tmp_node);
		add_output(current,1,0,tmp_node);

		return tmp_node;
	}
	struct node *connect_with_entry(struct node *left, struct node *right) {
		struct node *u_node = gen_node('U',0,0);
		if(right->type == 'T') {
			gen_a_node(right);
		}
		insert_node_after(left,u_node);
		if(left->type == 'E') {
			add_output(left,2,'L',u_node);
		} else {
			add_output(left,2,0,u_node);
		}
		add_output(right,1,0,u_node);

		return u_node;
	}
	struct node *gen_absolute_dependency(struct node *left, struct node *right) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = gen_node('C',left->out,0);
			left->out = gen_output(1,0,c_node);
			insert_node_after(left,c_node);
			left = c_node;
		}

		struct node *u_node;
		if(right->type == 'T') {
			right->type = 'U';
			add_output(left,1,0,right);
			u_node = right;
		} else {
			u_node = gen_node('U',0,0);
			insert_node_after(right,u_node);
			add_output(left,1,0,u_node);
			add_output(right,2,0,u_node);
		}


		return gen_tmp_node(u_node);
	}
	struct node *gen_g_independency(struct node *left, struct node *right, struct variable *vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = gen_node('C',left->out,0);
			left->out = gen_output(1,0,c_node);
			insert_node_after(left,c_node);
			left = c_node;
		}

		struct node *g_node;
		if(right->type == 'T') {
			right->type = 'G';
			right->vars = vars;
			g_node = right;
		} else {
			g_node = gen_node('G',0,vars);
			insert_node_after(right,g_node);
			add_output(right,1,0,g_node);
		}
		struct node *u_node = gen_node('U',0,0);
		insert_node_after(g_node,u_node);
		add_output(left,1,0,u_node);
		add_output(g_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		add_output(g_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *gen_i_independency(struct node *left, struct node *right, struct variable *vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = gen_node('C',left->out,0);
			left->out = gen_output(1,0,c_node);
			insert_node_after(left,c_node);
			left = c_node;
		}

		struct node *i_node;
		if(right->type == 'T') {
			right->type = 'I';
			right->vars = vars;
			i_node = right;
		} else {
			i_node = gen_node('I',0,vars);
			insert_node_after(right,i_node);
			add_output(right,1,0,i_node);
		}
		struct node *u_node = gen_node('U',0,0);
		insert_node_after(i_node,u_node);
		add_output(left,1,0,u_node);
		add_output(i_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		add_output(i_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *gen_g_i_independency(struct node *left, struct node *right, struct variable *g_vars, struct variable *i_vars) {
		if(left->type == 'A' && left->out != 0) {
			struct node *c_node = gen_node('C',left->out,0);
			left->out = gen_output(1,0,c_node);
			insert_node_after(left,c_node);
			left = c_node;
		}

		struct node *g_node;
		if(right->type == 'T') {
			right->type = 'G';
			right->vars = g_vars;
			g_node = right;
		} else {
			g_node = gen_node('G',0,g_vars);
			insert_node_after(right,g_node);
			add_output(right,1,0,g_node);
		}
		struct node *u_node = gen_node('U',0,0);
		struct node *i_node = gen_node('I',0,i_vars);
		insert_node_after(g_node,i_node);
		insert_node_after(i_node,u_node);
		add_output(left,1,0,u_node);
		add_output(g_node,2,'L',u_node);
		add_output(g_node,1,'R',i_node);
		add_output(i_node,2,'L',u_node);

		struct node *tmp_node = gen_tmp_node(u_node);
		add_output(i_node,1,'R',u_node->out->target);
		return tmp_node;
	}
	struct node *get_last_node(struct partial_problem *pp) {
		struct node *last_node = pp->node;
		while(last_node->next != 0) {
			last_node = last_node->next;
		}
		return last_node;
	}

	void add_variable(struct variable *current, char *newVar) {
			struct variable * tmp = new variable;
			tmp->name = newVar;
			tmp->next = 0;
			while(current->next != 0) {
				current = current->next;
			}
			current->next = tmp;
	}
	struct dependency *check_dependency(struct partial_problem *entry, struct partial_problem *current, struct partial_problem *check) {
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
						add_variable(check_equals,check_var->name);
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
						add_variable(depend->g_vars,entry_var->name);
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
					add_variable(current_different,current_var->name);
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
						add_variable(depend->i_vars,entry_var->name);
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
						add_variable(check_different,check_var->name);
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
							add_variable(depend->i_vars,entry_var->name);
						}
					}
					entry_var = entry_var->next;
				}
				check_different = check_different->next;
			}
		}
		return depend;
	}

	void schwinn(struct partial_problem *current_pp) {
		struct partial_problem *e_problem = current_pp;
		struct node *e_node = e_problem->node;
		current_pp = current_pp->next;
		//part 2.1.1
		if(current_pp != 0) {
			add_output(e_node,1,'R',current_pp->node);
			struct node *left_u_node = connect_with_entry(e_node,gen_a_node(current_pp->node));
			//part 2.1.2
			current_pp = current_pp->next;
			if(current_pp != 0) {
				if(current_pp->node->type == 'U'){ //second partial problem
					struct node *c_node = gen_node('C',0,0);
					insert_node_after(e_node,c_node);
					add_output(c_node,1,0,e_node->out->target);
					e_node->out->target = c_node;
					while(current_pp != 0) {
						printf("INFO:\tIn Loop\n");
						if(current_pp->node->type == 'U') {
						add_output(c_node,1,0,current_pp->node);
						struct partial_problem *left_problem = current_pp->prev;
						struct node *right_node = current_pp->node;
						int absolute_independency = 1;
						while(left_problem->node->type != 'E') {
							struct dependency *depend = check_dependency(e_problem,current_pp,left_problem);
							if(depend->type == ABSOLUTE_DEPENDENCY) {
								right_node = gen_absolute_dependency(get_last_node(left_problem),right_node);
								absolute_independency = 0;
							} else if(depend->type == G_INDEPENDENCY) {
								right_node = gen_g_independency(get_last_node(left_problem),right_node,depend->g_vars);
								absolute_independency = 0;
							} else if(depend->type == I_INDEPENDENCY) {
								right_node = gen_i_independency(get_last_node(left_problem),right_node,depend->i_vars);
								absolute_independency = 0;
							} else if(depend->type == GI_INDEPENDENCY) {
								right_node = gen_g_i_independency(get_last_node(left_problem),right_node,depend->g_vars,depend->i_vars);
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

				struct node *r_node = gen_node('R',0,0);
				insert_node_after(left_u_node,r_node);
				add_output(left_u_node,1,0,r_node);

			} else {
				struct node *r_node = gen_node('R',0,0);
				insert_node_after(left_u_node,r_node);
				add_output(left_u_node,1,0,r_node);
			}
		} else {
			struct node *r_node = gen_node('R',0,0);
			insert_node_after(e_node,r_node);
			add_output(e_node,1,0,r_node);
		}
	}

	int main(int argc, char **argv) {
		printf("INFO:\tProgram started.\n");

		var_head = 0;
		var_tail = 0;
		pp_head = 0;
		pp_tail = 0;

		yyparse();
		printf("INFO:\tStarting Schwinn...\n");
		schwinn(pp_head);
		printf("INFO:\tPrinting Node-Table...\n");
		print_table();
		printf("INFO:\tSuccess. Terminating...\n");
		return 0;
	}
	struct node *connect_and_number_nodes(struct partial_problem *pp) {
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

	int print_table_entry(struct node *node,FILE *output_stream){
		fprintf(output_stream,"%-5d%-3c",node->index,node->type);
		struct output *out = node->out;
		while(out!=0) {
			if(out->type != 0) {
				fprintf(output_stream,"%c:(%d,%d) ",out->type,out->target->index,out->port);
			} else {
				fprintf(output_stream,"(%d,%d) ",out->target->index,out->port);
			}
			out = out->next;
		}
		struct variable *vars = node->vars;
		while(vars!=0) {
			fprintf(output_stream,"%s,",vars->name);
			vars = vars->next;
		}
		fprintf(output_stream,"\n");
	}

	void print_table() {
		struct node *current = connect_and_number_nodes(pp_head);
		FILE *table_out;
		table_out = fopen("output.md","w");

		while(current != 0) {
			print_table_entry(current,table_out);
			current = current->next;
		}

		fclose(table_out);
	}

	void yyerror (char *message){
		printf("\nParser Error in line %d:\n%s\n", lines, message);
	}

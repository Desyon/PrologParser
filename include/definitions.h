#ifndef DEFINITIONS_H
#define DEFINITIONS_H

enum Independency {
  // DEFAULT is fallback for "NULL" assignment and never used otherwise
  DEFAULT, DEPENDEND, G, I, GI, ABSOLUTE
};

struct Variable {
  char *name;
  struct Variable *next;
  Variable(char *n) : name(n){
    next = nullptr;
  }

  void appendVar(Variable *var) {
    if(nullptr != next) {
      next->appendVar(var);
    } else {
      next = var;
    }
  }
};

struct PartialProblem {
  struct Variable *var;
  struct Node *node;
  struct PartialProblem *next;
  struct PartialProblem *prev;
};

struct Output {
  int port;
  char type;
  struct Node *target;
  struct Output *next;

  Output(int p, char t, Node *targ) :
  port(p), type(t), target(targ) {
    next = nullptr;
  }

  void append(Output *output){
    if(nullptr != next) {
      next->append(output);
    } else {
      next = output;
    }
  }
};

struct Node {
  int index;
  char type;
  struct Output *out;
  struct Variable *vars;
  struct Node *next;
  struct Node *prev;

  Node(char t, Output *o, Variable *v) :
  type(t), out(o), vars(v) {
    index = -1;
    prev = nullptr;
    next = nullptr;
  }

  void insertAfter(Node *node) {
    node->next = next;
    if(nullptr != next){
      next->prev = node;
    }
    node->prev = this;
    next = node;
  }

  void addOutput(int p, char t, Node *targ) {
    if(nullptr != out) {
      out->append(new Output(p, t, targ));
    } else {
      out = new Output(p, t, targ);
    }
  }
};

struct Dependency {
  Independency type;
  struct Variable *gVars;
  struct Variable *iVars;
};

// Method declarations

void yyerror(char *);

void genVarNode(char *);
void genPartialProblem(char , char *);

Variable *gen_var_from_char(char *);

Node *gen_a_node(Node *);
Node *connect_with_entry(Node *, Node *);
Node *gen_absolute_dependency(Node *, Node *);
Node *gen_g_independency(Node *, Node *, Variable *);
Node *gen_i_independency(Node *, Node *, Variable *);
Node *gen_g_i_independency(Node *, Node *, Variable *, Variable *);
Node *get_last_node(PartialProblem *);

Dependency *check_dependency(PartialProblem *, PartialProblem *, PartialProblem *);

Node *connect_and_number_nodes(PartialProblem *);
void printTableEntry();
void printTable();

void paperAlgorithm(PartialProblem *);

#endif /* DEFINITIONS_H */

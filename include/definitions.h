#ifndef DEFINITIONS_H
#define DEFINITIONS_H

enum Independency {
  // DEFAULT is fallback for "NULL" assignment and never used otherwise
  DEFAULT, DEPENDEND, G, I, GI, ABSOLUTE
};

enum Type : unsigned char {
  // Type of Nodes
  // Temp gets casted into another Type when needed
  APPLY = 'A',
  COPY = 'C',
  UPDATE = 'U',
  ENTRY = 'E',
  RETURN = 'R',
  GROUND = 'G',
  INDEPENDENCE = 'I',
  TEMP = 'T'
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
  Type type;
  struct Output *out;
  struct Variable *vars;
  struct Node *next;
  struct Node *prev;

  Node(Type t, Output *o, Variable *v) :
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

  void addOutput(int p, char 
  t, Node *targ) {
    if(nullptr != out) {
      out->append(new Output(p, t, targ));
    } else {
      out = new Output(p, t, targ);
    }
  }
};

struct PartialProblem {
  char *info;
  struct Variable *var;
  struct Node *node;
  struct PartialProblem *next;
  struct PartialProblem *prev;

  Node *getLastNode() {
    Node *tmp = node;
    while(nullptr != tmp->next) {
      tmp = tmp->next;
    }
    return tmp;
  }

};

  PartialProblem * get_dat_pp(char *i){
    PartialProblem *pp = new PartialProblem;
    pp->info = i;
    pp->var = nullptr;
    pp->node = nullptr;
    pp->next = nullptr;
    pp->prev = nullptr;
      
    return pp;
    }
    
struct Dependency {
  Independency type;
  struct Variable *gVars;
  struct Variable *iVars;
};

struct PrintList {
  Node *node;
  char *ppInfo;
  PrintList *next;

  PrintList(Node *n, char* info) :
  node(n), ppInfo(info) {
    next = nullptr;
  }

  void append(PrintList *input) {
    if (nullptr != next) {
      next->append(input);
    } else {
      next = input;
    }
  }
};

struct HelperVariable {
  struct Variable *var;
  struct PartialProblem *pp;
  struct HelperVariable *next;
  
  HelperVariable(Variable *v, PartialProblem *p) :
    var(v), pp(p) {
    }
      
  void appendVar(HelperVariable *input) {
    if (nullptr != next) {
      next->appendVar(input);
    } else {
      next = input;
    }
  }
};

// Method declarations

void yyerror(char *);

void genVarNode(char *);
void genPartialProblem(Type , char *);

Node *genANode(Node *);
Node *connectWithEntry(Node *, Node *);
Node *genAbsouluteDependency(Node *, Node *);
Node *genGIndependency(Node *, Node *, Variable *);
Node *genIIndependency(Node *, Node *, Variable *);
Node *genGIIndependency(Node *, Node *, Variable *, Variable *);

Dependency *checkDependency(PartialProblem *, PartialProblem *, PartialProblem *);

PrintList *numberAndOrderNodes(PartialProblem *);
void printTableEntry();
void printTable();

void paperAlgorithm(PartialProblem *);

#endif /* DEFINITIONS_H */

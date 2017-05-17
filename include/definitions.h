#ifndef DEFINITIONS_H
#define DEFINITIONS_H

typedef struct variable variable;
typedef struct Output Output;
typedef struct Node Node;
typedef struct partial_problem partial_problem;
typedef struct dependency dependency;

enum Independency {
  // DEFAULT is fallback for "NULL" assignment and never used otherwise
  DEPENDEND, ABSOLUTE, G, I, GI, DEFAULT
};

struct variable{
  char *name;
  struct variable *next;
};

struct Output{
  int port;
  char type;
  struct Node *target;
  struct Output *next;

  Output(int p, char t, Node *targ) :
  port(p), type(t), target(targ) {
    next = nullptr;
  }
};

struct Node{
  int index;
  char type;
  struct variable *vars;
  struct Output *out;
  struct Node *next;
  struct Node *prev;

  Node(char t, Output *o, variable *v) :
  type(t), out(o), vars(v) {
    prev = nullptr;
    next = nullptr;
  }
};

struct partial_problem{
  struct variable *var;
  struct Node *node;
  struct partial_problem *next;
  struct partial_problem *prev;
};

struct dependency{
  Independency type;
  struct variable *g_vars;
  struct variable *i_vars;
};

#endif /* DEFINITIONS_H */

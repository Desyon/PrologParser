#ifndef DEFINITIONS_H
#define DEFINITIONS_H

typedef struct variable variable;
typedef struct output output;
typedef struct node node;
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

struct output{
  int port;
  char type;
  struct node *target;
  struct output *next;
};

struct node{
  int index;
  char type;
  struct variable *vars;
  struct output *out;
  struct node *next;
  struct node *prev;
};

struct partial_problem{
  struct variable *var;
  struct node *node;
  struct partial_problem *next;
  struct partial_problem *prev;
};

struct dependency{
  Independency type;
  struct variable *g_vars;
  struct variable *i_vars;
};

#endif /* DEFINITIONS_H */

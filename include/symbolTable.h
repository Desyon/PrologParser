#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <vector>
#include <iostream>
#include <cstddef>

struct NamedId {
  int id;
  std::string name;
};

typedef NamedId liter_t, param_t;

struct literal {
  NamedId id;
  std::vector<param_t> params;
};

/**FUNCTION PROTOTYPES*/
void insertLiteral(literal l);
void insertParam(int id, param_t p);

void printSymbolTable();

#endif /** SYMBOLTABLE_H */

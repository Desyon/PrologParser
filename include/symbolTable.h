#ifndef SYMBOLTABLE_H
#define SYMBOLTABLE_H

#include <vector>
#include <set>
#include <map>
#include <iostream>
#include <cstddef>

struct NameId {
  int uId;
  std::string name;
};

struct IdComp {
  bool operator() (const NameId& left, const NameId& right) const {
    return left.uId < right.uId;
  }
};

typedef NameId liter_t, param_t;

typedef std::map<
          liter_t,
          std::set<
            param_t,
            IdComp
          >
        > expr;

/**FUNCTION PROTOTYPES*/
void insertLiteral();
void insertParam();

void printSymbolTable();

#endif /** SYMBOLTABLE_H */

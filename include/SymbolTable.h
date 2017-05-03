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

typedef NameId LiterName, ParamName;

typedef std::set<
          ParamName,
          IdComp
        > LiterParams;

typedef std::pair<
          LiterName,
          std::set<
            ParamName,
            IdComp
          >
        > LiterT;

typedef std::map<
          LiterName,
          std::set<
            ParamName,
            IdComp
          >,
          IdComp
        > ExprT;

typedef std::vector<ExprT> SymbolTable;

void printSymbolTable(SymbolTable);

#endif /** SYMBOLTABLE_H */

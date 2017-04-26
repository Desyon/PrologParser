#include <string>

#include "symbolTable.h"

/**GLOBAL VARIABLES*/

std::vector<expr> symbol_table;

int paramCount = 0;

//TODO: Rework insert funtions
void insertLiteral() {
  //symbol_table.back.insert(symbol_table.end(), l);
}

void insertParam() {
  //symbol_table.back[id].second.insert(p);
}

void printSymbolTable() {
  std::cout << "|-----SYMBOL TABLE-----|" << "\n\n";

  int exprCount = 1;
  for(auto &expression : symbol_table) {
    std::cout << "EXPR" << exprCount << ":" << std::endl;
    for(auto &liter : expression) {
      std::cout << "LITER:\t" << liter.first.name << std::endl;
      for(auto &param : liter.second) {
        std::cout << "\tPARAM:\t" << param.name << std::endl;
      }
    }
  }
}

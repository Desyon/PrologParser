#include <string>

#include "SymbolTable.h"

/**GLOBAL VARIABLES*/

void printSymbolTable(SymbolTable symbolTable) {
  std::cout << "|-----SYMBOL TABLE-----|" << "\n\n";

  int exprCount = 1;
  for(auto &expression : symbolTable) {
    std::cout << "EXPR" << exprCount++ << ":" << std::endl;
    for(auto &liter : expression) {
      std::cout << "LITER:\t" << liter.first.name << std::endl;
      for(auto &param : liter.second) {
        std::cout << "\tPARAM:\t" << param.name << std::endl;
      }
    }
  }
}

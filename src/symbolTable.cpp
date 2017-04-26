#include "symbolTable.h"

/**GLOBAL VARIABLES*/

std::vector<literal> symbol_table;

int paramCount = 0;

void insertLiteral(literal l) {
  symbol_table.insert(symbol_table.end(), l);
}

void insertParam(int id, param_t p) {
  symbol_table[id].params.insert(symbol_table[id].params.end(), p);
}

void printSymbolTable() {
std::cout << "|-----SYMBOL TABLE-----|" << "\n\n";

  for(std::vector<literal>::size_type i = 0; i < symbol_table.size(); i++) {
    std::cout << "LITER: " << symbol_table[i].id.name << std::endl;
    for(std::vector<param_t>::size_type n = 0; n < symbol_table[i].params.size(); n++) {
      std::cout << "\tPARAM: " << symbol_table[i].params[n].name << std::endl;
    }
  }
}

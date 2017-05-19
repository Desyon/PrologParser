%{
#include <iostream>
#include <stdio.h>
#include <string.h>

#include "../include/definitions.h"

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern "C" int lines;
extern "C" char *yytext;

Variable *varListHead;
Variable *varListTail;
PartialProblem *firstPartProb;
PartialProblem *lastPartProb;

%}
%union{
  char *str;
  int num;
}
%start clause
%token DEF DOT COMMA POPEN PCLOSE LOPEN LCLOSE
%token PIPE PLUS MINUS ASTERISK DIV
%token SMALLER SEQUAL GREATER GEQUAL EQUAL UNEQUAL
%token NOT IS
%token <num> NUMBER
%token <str> CONST VAR

%left PLUS MINUS ASTERISK DIV
%left UNEQUAL SMALLER SEQUAL GREATER GEQUAL
%%

clause: clause expression
        | expression
        ;

expression: rule DOT
            | fact DOT
            ;

rule: fact DEF factList
      ;

fact: CONST POPEN params PCLOSE {
        genPartialProblem(Type::ENTRY,$1); varListHead = nullptr;
      }
      ;

subRule:  CONST POPEN params PCLOSE {
            genPartialProblem(Type::UPDATE, $1); varListHead = nullptr;
          }
          | arithmeticExpr {
              genPartialProblem(Type::UPDATE,""); varListHead = nullptr;
          }
          ;

arithmeticExpr: VAR operator arithmeticRhs {
                  genVarNode($1);
                }
                ;

operator: PLUS
          | MINUS
          | EQUAL
          | SEQUAL
          | SMALLER
          | GEQUAL
          | GREATER
          | UNEQUAL
          | ASTERISK
          | DIV
          | IS
          ;

arithmeticRhs:  VAR {
                  genVarNode($1);
                }
                | NUMBER
                | CONST
                | arithmeticExpr
                ;

params: param COMMA params
        | param
        ;

factList: subRule COMMA factList
          | subRule
          ;

list: LOPEN lelement restlist
      | LOPEN LCLOSE
      ;

restlist: PIPE list LCLOSE
          | PIPE lelement LCLOSE
          | COMMA lelement restlist
          | LCLOSE
          ;

lelement: VAR {
            genVarNode($1);
          }
          | NUMBER
          | list
          ;

param:  CONST
        | NUMBER
        | list
        | VAR {
            genVarNode($1);
          }
        ;


%%
  void genVarNode(char *var_name){
    Variable *ptr = new Variable(var_name);
    if (!varListHead){
      varListHead = ptr;
      varListTail = ptr;
    } else{
      varListTail->next = ptr;
      varListTail = ptr;
    }
  }

void genPartialProblem(Type type, char *info){
  PartialProblem *ptr = new PartialProblem;
  ptr->var = varListHead;
  ptr->info = info;
  ptr->next = nullptr;
  ptr->prev = nullptr;
  ptr->node = new Node(type, nullptr, varListHead);
  if (!firstPartProb){
    firstPartProb = ptr;
    lastPartProb = ptr;
  } else{
    lastPartProb->next = ptr;
    ptr->prev = lastPartProb;
    lastPartProb = ptr;
  }
}

Node *genANode(Node *current) {
  if(current->type == Type::TEMP) {
    current->type = Type::APPLY;
    return current;
  } else {
    Node *aNode = new Node(Type::APPLY , nullptr, nullptr);
    current->insertAfter(aNode);
    current->addOutput(1, 0, aNode);
    return aNode;
  }
}

Node *genTmpNode(Node *current) {
  Node *tmpNode = new Node(Type::TEMP , nullptr, nullptr);
  current->insertAfter(tmpNode);
  current->addOutput(1, 0, tmpNode);

  return tmpNode;
}

Node *connectWithEntry(Node *left, Node *right) {
  Node *uNode = new Node(Type::UPDATE , nullptr, nullptr);
  if(right->type == Type::TEMP) {
    genANode(right);
  }
  left->insertAfter(uNode);
  if(left->type == Type::ENTRY) {
    left->addOutput(2, 'L', uNode);
  } else {
    left->addOutput(2, 0, uNode);
  }
  right->addOutput(1, 0, uNode);

  return uNode;
}

Node *genAbsouluteDependency (Node *left, Node *right) {
  if(left->type == Type::APPLY && left->out != 0) { //  copy the apply
    Node *cNode = new Node(Type::COPY, left->out, nullptr);
    left->out = new Output(1,0,cNode);
    left->insertAfter(cNode);
    left = cNode;
  }

  Node *uNode;
  if(right->type == Type::TEMP) { //  make it update node
    right->type = Type::UPDATE;
    left->addOutput(1, 0, right);
    uNode = right;
  } else {  //  create new update node
    uNode = new Node(Type::UPDATE , nullptr, nullptr);
    right->insertAfter(uNode);
    left->addOutput(1, 0, uNode);
    right->addOutput(2, 0, uNode);
  }

  return genTmpNode(uNode);
}

Node *genGIndependency(Node *left, Node *right, Variable *vars) {
  if(left->type == Type::APPLY && left->out != nullptr) { //  copy the apply
    Node *cNode = new Node(Type::COPY, left->out, nullptr);
    left->out = new Output(1,0,cNode);
    left->insertAfter(cNode);
    left = cNode;
  }

  Node *gNode;
  if(right->type == Type::TEMP) { //  make right a ground node
    right->type = Type::GROUND;
    right->vars = vars;
    gNode = right;
  } else {  //  create new ground node
    gNode = new Node(Type::GROUND, nullptr, vars);
    right->insertAfter(gNode);
    right->addOutput(1, 0, gNode);
  }
  //  insert update after ground
  Node *uNode = new Node(Type::UPDATE, nullptr, nullptr);
  gNode->insertAfter(uNode);
  left->addOutput(1, 0, uNode);
  gNode->addOutput(2, 'L', uNode);

  Node *tmpNode = genTmpNode(uNode);
  gNode->addOutput(1, 'R', uNode->out->target);
  return tmpNode;
}

Node *genIIndependency(Node *left, Node *right, Variable *vars) {
  if(left->type == Type::APPLY && left->out != 0) { // copy the apply
    Node *cNode = new Node(Type::COPY, left->out, nullptr);
    left->out = new Output(1, 0, cNode);
    left->insertAfter(cNode);
    left = cNode;
  }

  Node *iNode;
  if(right->type == Type::TEMP) { //  make right i node
    right->type = Type::INDEPENDENCE;
    right->vars = vars;
    iNode = right;
  } else {  //  create new i node
    iNode = new Node(Type::INDEPENDENCE, nullptr, vars);
    right->insertAfter(iNode);
    right->addOutput(1, 0, iNode);
  }
  // insert update after i
  Node *uNode = new Node(Type::UPDATE, nullptr, nullptr);;
  iNode->insertAfter(uNode);
  left->addOutput(1, 0, uNode);
  iNode->addOutput(2, 'L', uNode);

  Node *tmpNode = genTmpNode(uNode);
  iNode->addOutput(1, 'R', uNode->out->target);
  return tmpNode;
}

Node *genGIIndependency(Node *left, Node *right, Variable *gVars, Variable *iVars) {
  if(left->type == Type::APPLY && left->out != 0) { //  copy the apply
    Node *cNode = new Node(Type::COPY, left->out, nullptr);
    left->out = new Output(1, 0, cNode);
    left->insertAfter(cNode);
    left = cNode;
  }

  Node *gNode;
  if(right->type == Type::TEMP) { // make it ground
    right->type = Type::GROUND;
    right->vars = gVars;
    gNode = right;
  } else {  //  create new ground
    gNode = new Node(Type::GROUND, nullptr, gVars);
    right->insertAfter(gNode);
    right->addOutput(1, 0, gNode);
  }
  //  insert new i node after ground
  //  insert new update node after i
  Node *uNode = new Node(Type::UPDATE, nullptr, nullptr);
  Node *iNode = new Node(Type::INDEPENDENCE, nullptr, iVars);
  gNode->insertAfter(iNode);
  iNode->insertAfter(uNode);
  //  order the output paths
  left->addOutput(1, 0, uNode);
  gNode->addOutput(2, 'L', uNode);
  gNode->addOutput(1, 'R', iNode);
  iNode->addOutput(2, 'L', uNode);

  Node *tmpNode = genTmpNode(uNode);
  iNode->addOutput(1, 'R', uNode->out->target);
  return tmpNode;
}

Dependency *checkDependency(PartialProblem *entry, PartialProblem *current,  PartialProblem *check) { // check dependencies between two partial problems
  // Initialize helper
  Variable *entryVar = entry->var;
  Variable *currentVar = current->var;
  Variable *checkVar = check->var;

  Variable *checkEquals = nullptr;  // list of variables to be checked with the same name
  Variable *checkDifferent = nullptr;
  Variable *currentDifferent = nullptr;
  Dependency *depend = new Dependency;
  depend->type = Independency::DEFAULT;
  depend->iVars = nullptr;
  depend->gVars = nullptr;

  //check for equals between current and check
  while(nullptr != currentVar) {  // iterate over all variables of current partial problem
    checkVar = check->var;
    while(nullptr != checkVar) {
      if(strcmp(currentVar->name,checkVar->name) == 0) {  // Add to list for checkEquals
        if(nullptr == checkEquals) {
          checkEquals = new Variable(checkVar->name);
        } else {
          checkEquals->appendVar(new Variable(checkVar->name));
        }
      }
      checkVar = checkVar->next;
    }
    currentVar = currentVar->next;
  }

  //check for G independency/absolute dependency
  bool found;
  Variable *tmpCheckEquals = checkEquals;
  while(nullptr != tmpCheckEquals) {
    found = false;
    entryVar = entry->var;
    while(nullptr != entryVar) {  //  compare all variables in checkEquals with those in entry problem
      if(strcmp(entryVar->name,tmpCheckEquals->name) == 0) {
        //  found G Independency, add it to gVars
        found = true;
        std::cout << "Found G Independency in " << current->info << " with " << check->info << std::endl;
        if(nullptr == depend->gVars) {
          depend->gVars = new Variable(entryVar->name);
          depend->type = Independency::G;
        } else {
          depend->gVars->appendVar(new Variable(entryVar->name));
        }
      }
      entryVar = entryVar->next;
    }
    if(!found) {
        std::cout << "Found Dependence in " << current->info << " with " << check->info << std::endl;
      depend->type = Independency::DEPENDEND;
      return depend;
    }
    tmpCheckEquals = tmpCheckEquals->next;
  }

//look for all variables that are in current but not in check
  currentVar = current->var;  //  reset currentVar
  while(nullptr != currentVar) {
    found = false;
    tmpCheckEquals = checkEquals;
    while(nullptr != tmpCheckEquals) {
      if(strcmp(currentVar->name,tmpCheckEquals->name) == 0) {
        found = true;
      }
      tmpCheckEquals = tmpCheckEquals->next;
    }
    if(!found) {  //  append variable name to the list
      if(nullptr == currentDifferent) {
        currentDifferent = new Variable(currentVar->name);
      } else {
        currentDifferent->appendVar(new Variable(currentVar->name));
      }
    }
    currentVar = currentVar->next;
  }

//check for I independency on current site and absolute independency
  while(nullptr != currentDifferent) {
    entryVar = entry->var;
    while(nullptr != entryVar) {  // Check all variable against the ones that are different
      if(strcmp(currentDifferent->name,entryVar->name) == 0) {
        if(nullptr == depend->iVars) {
          depend->iVars = new Variable(entryVar->name);
          if(depend->type == Independency::G) {
            depend->type = Independency::GI;  // if arleady G -> GI
        std::cout << "Found GI Independency in " << current->info << " with " << check->info << std::endl;
          } else {
        std::cout << "Found I Independency in " << current->info << " with " << check->info << std::endl;
            depend->type = Independency::I; // I 
          }
        } else {  // Add variable to the variable list
          depend->iVars->appendVar(new Variable(entryVar->name));
        }
      }
      entryVar = entryVar->next;
    }
    currentDifferent = currentDifferent->next;
  }
  if(depend->type == Independency::DEFAULT) { //  if still no dependency -> absolute independent
    depend->type = Independency::ABSOLUTE;
    return depend;
  }

  if(depend->type == Independency::GI || depend->type == Independency::I) {
    //look for all variables that are in check but not in current
    checkVar = check->var;
    while(nullptr != checkVar) {
      found = false;
      tmpCheckEquals = checkEquals;
      while(nullptr != tmpCheckEquals) {
        if(strcmp(checkVar->name,tmpCheckEquals->name) == 0) {
          found = true;
        }
        tmpCheckEquals = tmpCheckEquals->next;
      }
      if(!found) {
        if(nullptr == checkDifferent) {
          checkDifferent = new Variable(checkVar->name);
          } else {
            checkDifferent->appendVar(new Variable(checkVar->name));
          }
        }
        checkVar = checkVar->next;
      }

      //check for i independency on check site
      while(nullptr != checkDifferent) {
        entryVar = entry->var;
        while(nullptr != entryVar) {
          if(strcmp(checkDifferent->name,entryVar->name) == 0) {
            if(depend->iVars == nullptr) {
              depend->iVars = new Variable(entryVar->name);
              if(depend->type == Independency::G) { //  if already G independet -> GI independent
                depend->type = Independency::GI;
                std::cout << "Found GI Independency in " << check->info << " with " << current->info << std::endl;
              } else {
                depend->type = Independency::I;
                std::cout << "Found I Independency in " << check->info << " with " << current->info << std::endl;
              }
            } else {
              depend->iVars->appendVar(new Variable(entryVar->name));
            }
          }
          entryVar = entryVar->next;
        }
        checkDifferent = checkDifferent->next;
      }
    }
    // return final dependency
    return depend;
  }

void paperAlgorithm(PartialProblem *currPartProb) {
  // Init entry problem, set first partial problem
  PartialProblem *eProb = currPartProb;
  Node *eNode = eProb->node;
  currPartProb = currPartProb->next;
  //part 2.1.1
  if(currPartProb != nullptr) { // first partial problem
    eNode->addOutput(1, Type::RETURN, currPartProb->node);
    // Connect node to entry node
    Node *leftUNode = connectWithEntry(eNode,genANode(currPartProb->node));
    //part 2.1.2
    currPartProb = currPartProb->next;
    if(currPartProb != nullptr) {
      if(currPartProb->node->type == Type::UPDATE){ //second partial problem
        // create copy node for all following partial problems
        Node *cNode = new Node(Type::COPY, nullptr, nullptr);
        eNode->insertAfter(cNode);
        cNode->addOutput(1, 0, eNode->out->target);
        eNode->out->target = cNode;

        while(currPartProb != nullptr) {  // loop over all partial problems
          if(currPartProb->node->type == Type::UPDATE) {
            // Add copy node as input to update node
            cNode->addOutput(1, 0, currPartProb->node);
            PartialProblem *leftProb = currPartProb->prev;
            Node *rightNode = currPartProb->node;
            bool absoluteInd = true;  // assume absolute independency

            while(leftProb->node->type != Type::ENTRY) {  // Check dependencies from right to left
              // Check for dependency
              Dependency *depend = checkDependency(eProb, currPartProb, leftProb);
              
              switch(depend->type){ // generate nodes according to independency
              case Independency::DEPENDEND : 
                rightNode = genAbsouluteDependency(leftProb->getLastNode(),rightNode);
                absoluteInd = false;
                break;
              case Independency::G :
                rightNode = genGIndependency(leftProb->getLastNode(),rightNode,depend->gVars);
                absoluteInd = false;
                break;
              case Independency::I :
                rightNode = genIIndependency(leftProb->getLastNode(),rightNode,depend->iVars);
                absoluteInd = false;
                break;
              case Independency::GI :
                rightNode = genGIIndependency(leftProb->getLastNode(),rightNode,depend->gVars,depend->iVars);
                absoluteInd = false;
                break;
              }
              leftProb = leftProb->prev;
            }
            if(absoluteInd) { // independent -> create apply node
              rightNode = genANode(rightNode);
            }
            leftUNode = connectWithEntry(leftUNode,rightNode);
            currPartProb = currPartProb->next;
            } else {  // no update -> no dependency
              break;
            }
          }
        }
        //  Connect return node
        Node *rNode = new Node(Type::RETURN, nullptr, nullptr);
        leftUNode->insertAfter(rNode);
        leftUNode->addOutput(1, 0, rNode);

      } else {  // only one partial problem -> insert return node
        Node *rNode = new Node(Type::RETURN, nullptr, nullptr);
        leftUNode->insertAfter(rNode);
        leftUNode->addOutput(1, 0, rNode);
      }
    } else {  // No partial problem -> insert return node
      Node *rNode = new Node(Type::RETURN, nullptr, nullptr);
      eNode->insertAfter(rNode);
      eNode->addOutput(1, 0, rNode);
    }
  }

int main(int argc, char **argv) {

  std::cout << "Program started. Setting up..." << std::endl;

  varListHead = nullptr;
  varListTail = nullptr;
  firstPartProb = nullptr;
  lastPartProb = nullptr;

  std::cout << "Running Parser..." << std::endl;
  yyparse();
  std::cout << std::endl << "Generating intermediate code..." << std::endl;
  paperAlgorithm(firstPartProb);
  std::cout << std::endl;
  printTable();
  return 0;
}

PrintList *numberAndOrderNodes(PartialProblem *pp) {
  PrintList *print = nullptr;
  Node *current = pp->node;
  // set intermediate pointer to stall R Node until the end
  Node *rNode = nullptr;
  int index = 1;

  // loop through all partial problems
  while(nullptr != pp) {
    // loop through all nodes of the partial problem
    while(nullptr != current->next) {
      current->index = index++;

      // check if print list already exists
      if(nullptr == print) {
        PrintList *insert;
        if(Type::ENTRY == current->type || Type::UPDATE == current->type){
          insert = new PrintList(current, pp->info);
        } else {
          insert = new PrintList(current, nullptr);
        }

        // set node as print list
        print = insert;
      } else {
        PrintList *insert;
        if(Type::ENTRY == current->type || Type::UPDATE == current->type){
          insert = new PrintList(current, pp->info);
        } else {
          insert = new PrintList(current, nullptr);
        }
        // append node to print list
        print->append(insert);
      }
      current = current->next;
    }

    // append first node of next partial problem
    pp = pp->next;
    if(pp != nullptr) {
      current->next = pp->node;
    }

    // find and stall R node to append in the end
    if(Type::RETURN == current->type) {
      rNode = current;
      current = current->next;
    } else {
      current->index = index++;
      PrintList *insert;
      if(Type::ENTRY == current->type || Type::UPDATE == current->type){
        insert = new PrintList(current, pp->info);
      } else {
        insert = new PrintList(current, nullptr);
      }
      print->append(insert);
      current = current->next;
    }
  }

  // reappend R node to print list
  rNode->index = index;
  print->append(new PrintList(rNode, nullptr));

  return print;
}

void printTableEntry(Node *node, char* info){
  // TODO Maybe orient on type of node for nicer output.
  using namespace std;

  cout << node->index << "\t" << static_cast<unsigned char>(node->type) << "\t";
  Output *out = node->out;
  int outs = 0;
  while(nullptr != out) {
    if(out->type != 0) {
      outs++;
      cout << out->type << ":(" << out->target->index << "," << out->port << ") ";
    } else {
      outs++;
      cout << "(" << out->target->index << "," << out->port << ")\t";
    }
    out = out->next;
  }

  for(outs; outs < 5; outs++){
    cout << "\t";
  }

  if (nullptr != info) {
    cout << info;
  }

  Variable *vars = node->vars;
  if(vars){
    cout << "(";
    while(nullptr != vars) {
      cout << vars->name;
      if(vars->next) cout << ",";
      vars = vars->next;
    }
    cout << ")";
  }
  cout << endl;
}

void printTable() {
  PrintList *current = numberAndOrderNodes(firstPartProb);

  // newline before table
  std::cout << std::endl;

  while(current != nullptr) {
    printTableEntry(current->node, current->ppInfo);
    current = current->next;
  }
}

void yyerror (char *message){
  std::cout << std::endl << "Parser error in line " << lines << std::endl;
}

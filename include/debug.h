#ifndef DEBUG_H
#define DEBUG_H

//#define ENABLE_DEBUG

#ifdef ENABLE_DEBUG
#include <iostream>
#define DEBUG(x) std::cerr << "DEBUG: " << x << std::endl;
#else
#define DEBUG(x)
#endif

#endif

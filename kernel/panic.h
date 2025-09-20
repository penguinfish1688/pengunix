#ifndef PANIC_H
#define PANIC_H

#include "libc.h"

void panic();

#define assert(condition) \
    do { \
        if (!(condition)) { \
            printk("Assert Error: %s. In file: %s line: %d", \
                #condition, \
                __FILE__, \
                __LINE__ \
            ); \
            panic(); \
        } \
    } while (0) \



#endif



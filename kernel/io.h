#ifndef IO_H
#define IO_H
#include "types.h"
 
/* implemented in kernel/kernel.asm */

void out(uchar val, uint16 port);
uchar in(uint16 port);                 

#endif

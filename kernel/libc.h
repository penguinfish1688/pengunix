#ifndef LIBC_H
#define LIBC_H

#include "types.h"

uchar *memcpy(uchar*, uchar*, int);
uchar *disp_mem(uchar*, int n);
char *disp_str(char*);
int disp_num(int);
int disp_dec(int);
void printk(char *, ...);
void clear_screen();

extern void disp_char(char);
extern void del_char();

#ifndef max
#define max(a, b) (((a) > (b)) ? (a) : (b))
#endif

#ifdef min
#define min(a, b) (((a) < (b)) ? (a) : (b))
#endif

#ifndef abs
#define abs(a) (((a) < 0) ? -(a) : (a))
#endif


#endif

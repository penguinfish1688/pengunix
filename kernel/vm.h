#ifndef VM_H
#define VM_H

#include "types.h"

#define MEM_TYPE_USR 1
#define MEM_TYPE_SYS 2

#define MEMINFO_TBL_SIZE 16

struct meminfo {
    int64 base;
    int64 size;
    int type; 
};

extern struct meminfo meminfo_tbl[MEMINFO_TBL_SIZE];

void show_mem_info();

int get_max_addr();

#endif

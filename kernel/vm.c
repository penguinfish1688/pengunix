#include "vm.h"
#include "libc.h"

/* In kernel/kernel.asm, data is copied to meminfo_tbl */
struct meminfo meminfo_tbl[MEMINFO_TBL_SIZE];
int64 max_addr;

void show_mem_info() {
    disp_str("__BASE__    __SIZE__    __TYPE__\n");
    for (int i = 0; i < MEMINFO_TBL_SIZE; i++) {
        if (meminfo_tbl[i].base || meminfo_tbl[i].size || meminfo_tbl[i].type) {
            disp_num((int)meminfo_tbl[i].base);
            disp_str("  ");
            disp_num((int)meminfo_tbl[i].size);
            disp_str("  ");
            if (meminfo_tbl[i].type == MEM_TYPE_USR)
                disp_str("USER");
            else if (meminfo_tbl[i].type == MEM_TYPE_SYS) 
                disp_str("SYSTEM");
            else
                disp_str("UNKNOWN");
            disp_str("\n");
        }
    }
    return ;
}

int get_max_addr() {
    max_addr = -1;
    for (int i = 0; i < MEMINFO_TBL_SIZE; i++) {
        if (meminfo_tbl[i].type == MEM_TYPE_USR) {
            max_addr = max(max_addr, (int)meminfo_tbl[i].base + (int)meminfo_tbl[i].size);
        }
    }
    return max_addr;
}










#ifndef GLOBAL_H
#define GLOBAL_H


#define KERNEL_STACK_BASE   0x9F000
#define KERNEL_ENTRY        0x30000
#define VIDEO_MEM_BASE      0xB8000

/* next char being printed's video memory address relative to 0xB8000*/
extern int output_addr;

#endif


#ifndef DESC_H
#define DESC_H
#include "types.h"


#define NR_GDT 32
#define NR_LDT 32
#define NR_IDT 256


struct __attribute__((packed)) desc_ptr {
    uint16 len;
    void *base;
};

struct __attribute__((packed)) desc {
    uint16 limit_low;
    uint16 base_low;
    uint8  base_mid;
    uint16 attr; 
    uint8  base_high;
};

struct __attribute__((packed)) gate {
    uint16 offset_low;
    uint16 selector;
    uint8  pcount;
    uint8  attr;
    uint16 offset_high;
};


struct __attribute__((packed)) tss {
    uint32  last;
    uint32  esp0;
    uint32  ss0;
    uint32  esp1;
    uint32  ss1;
    uint32  esp2;
    uint32  ss2;
    uint32  gr3;
    uint32  eip;
    uint32  eflags;
    uint32  eax;
    uint32  ecx;
    uint32  edx;
    uint32  ebx;
    uint32  esp;
    uint32  ebp;
    uint32  esi;
    uint32  edi;
    uint32  es;
    uint32  cs;
    uint32  ss;
    uint32  ds;
    uint32  fs;
    uint32  gs;
    uint32  ldt_selector;
    uint32  iomap;
};

typedef uint16 selector_t;

void load_gdt(struct desc_ptr*);

void load_ldt(selector_t);

void load_idt(struct desc_ptr*);

void init_ldt();

void init_tss();

void bootloader_gdt_selector();

uint current_ss();

uint current_esp();

void load_tss(selector_t);

#define GDT_ENTRY(_base, _limit, _attr) (struct desc){ \
    .limit_low = ((_limit) & 0xFFFF),              \
    .base_low = ((_base) & 0xFFFF),                \
    .base_mid = (((_base) >> 16) & 0xFF),          \
    .attr = (((_attr) & 0xF0FF) + (((_limit) >> 8) & 0x0F00)), \
    .base_high = ((_base >> 24) & 0xFF)            \
}

#define GDT_PTR(_base, _len) (struct desc_ptr){ \
    .len = (_len),   \
    .base = (_base)  \
}

#define LDT_ENTRY(_base, _limit, _attr) (struct desc){ \
    .limit_low = (_limit) & 0xFFFF,              \
    .base_low = (_base) & 0xFFFF,                \
    .base_mid = ((_base) >> 16) & 0xFF,          \
    .attr = ((_attr) & 0xF0FF) + (((_limit) >> 8) & 0x0F00), \
    .base_high = (_base >> 24) & 0xFF            \
}

#define LDT_PRT(_base, _len) (struct desc_ptr){ \
    .len = (_len),   \
    .base = (_base)  \
}

#define GATE_ENTRY(_selector, _offset, _pcount, _attr)(struct gate){ \
    .offset_low = ((_offset) & 0xFFFF),     \
    .selector = (_selector),                \
    .pcount = ((_pcount) & 0x1F),           \
    .attr = (_attr),                        \
    .offset_high = (((_offset) >> 16) & 0xFFFF) \
}

#define GET_SELECTOR(_nr_desc, _rpl) (((_nr_desc)<<3) + (_rpl))

/* *******************************************************************************************************
 * define descriptor attributes 
 *
 * Byte 6 & 7, the third argument of GDT descriptor struct
 *
 * |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |
 * |  G  | D/B |  0  | AVL | segment limit 16..19  |  P  |    DPL    |  S  |         TYPE          |
 *
 * *******************************************************************************************************/ 

/* Address Access Type
 * Access the code/stack segment in 32. For expand down data segment, the size limit is set to 32Gb rather than 64 Kb */

#define DA_32 0x4000  

/* Limit granularity
 * Data limit granularity set to 4K */

#define LG_4K 0x8000   

/* Request Privilege Type (Selector) */
#define SP_RPL0    0
#define SP_RPL1    1
#define SP_RPL2    2
#define SP_RPL3    3
#define SA_TIL     4    // LDT selector flag

/* Descriptor Privilege Type (Descriptor) */
#define DP_DPL0    0x0000   // ring 0
#define DP_DPL1    0x0020   // ring 1
#define DP_DPL2    0x0040   // ring 2
#define DP_DPL3    0x0060   // ring 3

/*  Code/Data Access Type
 * P=1 means present. S=1 means this is code or data.
 * R=read, A=access, W=write, D=expand down, E=execute */

#define DA_R       0x90
#define DA_RW      0x92
#define DA_RD      0x94
#define DA_RWD     0x96
#define DA_E       0x98
#define DA_RE      0x9A
#define DA_ECO     0x9C
#define DA_RECO    0x9E

/* System segment */
#define DA_LDT         0x82
#define DA_TaskGate    0x85 
#define DA_386TSS      0x89 // TSS
#define DA_386CGate    0x8C // Call Gate
#define DA_386IGate    0x8E // Interrupt Gate
#define DA_386TGate    0x8F // Trap Gate

/* create GDT and LDT */
extern struct desc gdt[NR_GDT];
extern struct desc_ptr gdt_ptr;
extern selector_t gdt_selector[NR_GDT];

extern struct desc default_ldt[NR_LDT];
extern selector_t default_ldt_selector[NR_LDT];

/* global IDT */
extern struct gate idt[NR_IDT];
extern struct desc_ptr idt_ptr;


/* global TSS */
extern struct tss tss;

/* setup global gdt table */
#define NR_GDT_START     0
#define NR_GDT_FLAT_CODE 1
#define NR_GDT_FLAT_DATA 2
#define NR_GDT_VIDEO     3
#define NR_GDT_PAGE_DIR  4
#define NR_GDT_PAGE_TBL  5 
#define NR_GDT_TSS       6
#define NR_GDT_LDT       7

/* LDT */
#define NR_LDT_START        0
#define NR_LDT_FLAT_CODE    1
#define NR_LDT_FLAT_DATA    2
#define NR_LDT_VIDEO        3

/* segment base and limit */
#define FLAT_MEM_BASE   0
#define FLAT_MEM_LIMIT  0xFFFFF // limit = 0xFFFFF * 4kb = 32Gb
#define VIDEO_BASE      0xB8000
#define VIDEO_LIMIT     0x7FFF
#define PAGE_DIR_BASE   0x100000
#define PAGE_DIR_LIMIT  0xFFFFF









#endif

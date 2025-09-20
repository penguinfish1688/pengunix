#include "desc.h"

/* global GDT */
struct desc gdt[NR_GDT];
struct desc_ptr gdt_ptr;
selector_t gdt_selector[NR_GDT];

/* default LDT - A template to build a new process */
struct desc default_ldt[NR_LDT];
selector_t default_ldt_selector[NR_LDT];

/* global IDT */
struct gate idt[NR_IDT];
struct desc_ptr idt_ptr;

/* global TSS */
struct tss tss;

/* In bootloader we use macro to define selectors, but here we need variables. */
void bootloader_gdt_selector() {
    /* glabal GDT selector */
    gdt_selector[NR_GDT_START]      =  GET_SELECTOR(NR_GDT_START, SP_RPL0);
    gdt_selector[NR_GDT_FLAT_CODE]  =  GET_SELECTOR(NR_GDT_FLAT_CODE, SP_RPL0);
    gdt_selector[NR_GDT_FLAT_DATA]  =  GET_SELECTOR(NR_GDT_FLAT_DATA, SP_RPL0);
    gdt_selector[NR_GDT_VIDEO]      =  GET_SELECTOR(NR_GDT_VIDEO, SP_RPL3);
    gdt_selector[NR_GDT_PAGE_DIR]   =  GET_SELECTOR(NR_GDT_PAGE_DIR, SP_RPL0);
    gdt_selector[NR_GDT_PAGE_TBL]   =  GET_SELECTOR(NR_GDT_PAGE_TBL, SP_RPL0);
}

void init_ldt() {
    /* Build default LDT entry */
    default_ldt[NR_LDT_START]       = LDT_ENTRY(0, 0, 0);
    default_ldt[NR_LDT_FLAT_CODE]   = LDT_ENTRY(0, 0xFFFFF, DA_RE+DP_DPL3+DA_32+LG_4K);
    default_ldt[NR_LDT_FLAT_DATA]   = LDT_ENTRY(0, 0xFFFFF, DA_RW+DP_DPL3+DA_32+LG_4K);
    default_ldt[NR_LDT_VIDEO]       = LDT_ENTRY(0xB8000, 0x7FFF, DA_RW+DP_DPL3+DA_32);
    
    /* LDT selectors */
    default_ldt_selector[NR_LDT_START]      = GET_SELECTOR(NR_LDT_START, SP_RPL3+SA_TIL);
    default_ldt_selector[NR_LDT_FLAT_CODE]  = GET_SELECTOR(NR_LDT_FLAT_CODE, SP_RPL3+SA_TIL);
    default_ldt_selector[NR_LDT_FLAT_DATA]  = GET_SELECTOR(NR_LDT_FLAT_DATA, SP_RPL3+SA_TIL);
    default_ldt_selector[NR_LDT_VIDEO]      = GET_SELECTOR(NR_LDT_VIDEO, SP_RPL3+SA_TIL);
    
    return ;
}

void init_tss() {
    /* Set esp until you need it */    
    tss.ss0 = (uint32)gdt_selector[NR_GDT_FLAT_DATA];
    
    tss.iomap = sizeof(struct tss);
    /* Add TSS into GDT */
    gdt[NR_GDT_TSS] = GDT_ENTRY((uint)&tss, sizeof(struct tss)-1, DA_386TSS);
    
    /* Add TSS GDT selector*/
    gdt_selector[NR_GDT_TSS] = GET_SELECTOR(NR_GDT_TSS, SP_RPL0);
    load_tss(gdt_selector[NR_GDT_TSS]);
    return ;
}
























#include "io.h"
#include "irq.h"
#include "desc.h"
#include "libc.h"
#include "syscall.h"

/* 
 * irq_handlers defined in kernel/ 
 * irq_entry function in kernel/kernel.asm transfer control to one one of these
 */
void *irq_handlers[IRQ_NUM];



void init8259a() {
    out(0x11, 0x20); // Trigger initialize command word (ICW)
    out(0x11, 0xA0);

    out(0x20, 0x21); // ICW2 master set irq number to 0x20
    out(0x28, 0xA1); // ICW2 slave set irq number to 0x28

    out(0x04, 0x21); // ICW3 master third port connect to slave
    out(0x02, 0xA1); // ICW3 slave connect to third port in master
    
    out(0x01, 0x21); // ICW4 master enable x86 mode
    out(0x01, 0xA1); // ICW4 slave enable x86 mode
    
    for (int i = 0; i < IRQ_NUM; i++) {
        disable_8259a(i);
    }
    
    
    return ;
}

void init_idt() {
    /* Build IDT exception entries */
    idt[NR_DE] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)divide_error, 0, DA_386IGate);
    idt[NR_DB] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)single_step_exception, 0, DA_386IGate);
    idt[NR_NI] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)nmi, 0, DA_386IGate);
    idt[NR_BP] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)breakpoint_exception, 0, DA_386IGate);
    idt[NR_OF] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)overflow, 0, DA_386IGate);
    idt[NR_BR] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)bounds_check, 0, DA_386IGate);
    idt[NR_UD] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)inval_opcode, 0, DA_386IGate);
    idt[NR_NM] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)copr_not_available, 0, DA_386IGate);
    idt[NR_DF] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)double_fault, 0, DA_386IGate);
    idt[NR_SO] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)copr_seg_overrun, 0, DA_386IGate);
    idt[NR_TS] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)inval_tss, 0, DA_386IGate);
    idt[NR_NP] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)segment_not_present, 0, DA_386IGate);
    idt[NR_SS] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)stack_exception, 0, DA_386IGate);
    idt[NR_GP] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)general_protection, 0, DA_386IGate);
    idt[NR_PF] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)page_fault, 0, DA_386IGate);
    idt[NR_PS] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)copr_presv, 0, DA_386IGate);
    idt[NR_MF] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)copr_error, 0, DA_386IGate);
    idt[NR_AC] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)align_check, 0, DA_386IGate);
    idt[NR_MC] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)machine_check, 0, DA_386IGate);
    idt[NR_XF] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)simd_error, 0, DA_386IGate);

    /* Build IDT IRQ entries */
    idt[NR_IRQ_00] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq00, 0, DA_386IGate);
    idt[NR_IRQ_01] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq01, 0, DA_386IGate);
    idt[NR_IRQ_02] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq02, 0, DA_386IGate);
    idt[NR_IRQ_03] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq03, 0, DA_386IGate);
    idt[NR_IRQ_04] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq04, 0, DA_386IGate);
    idt[NR_IRQ_05] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq05, 0, DA_386IGate);
    idt[NR_IRQ_06] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq06, 0, DA_386IGate);
    idt[NR_IRQ_07] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq07, 0, DA_386IGate);
    idt[NR_IRQ_08] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq08, 0, DA_386IGate);
    idt[NR_IRQ_09] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq09, 0, DA_386IGate);
    idt[NR_IRQ_10] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq10, 0, DA_386IGate);
    idt[NR_IRQ_11] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq11, 0, DA_386IGate);
    idt[NR_IRQ_12] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq12, 0, DA_386IGate);
    idt[NR_IRQ_13] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq13, 0, DA_386IGate);
    idt[NR_IRQ_14] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq14, 0, DA_386IGate);
    idt[NR_IRQ_15] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)irq15, 0, DA_386IGate);
    
    idt[0x80] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)syscall_handler, 0, DA_386IGate+DP_DPL3);

    /* Fill IDT pointer */
    idt_ptr.len = NR_IDT * sizeof(struct gate);
    idt_ptr.base = (void *)idt;
    
    /* Load IDT */
    load_idt(&idt_ptr);

}

int enable_8259a(int port_nr) {
    if (port_nr < 0 || port_nr > 15) {
        disp_str("Invalid 8259A port number\n");
        return -1;
    }
    uchar settings;
    if (port_nr < 8) {
        /* master 8259a */
        uchar mask = 1;
        mask = mask << (port_nr);
        mask = ~mask;
        settings = in(0x21);
        //disp_str("before: ");
        //disp_num((int)settings & 0xFF);
        settings = settings & mask;
        //disp_str(" after: ");
        //disp_num((int)settings & 0xFF);
        out(settings, 0x21);
    }
    else {
        /* slave 8259a */
        uchar mask = 1;
        mask = mask << (port_nr-8);
        mask = ~mask;
        settings = in(0xA1);
        settings = settings & mask;
        out(settings, 0xA1);
    }
    return 0;
}

int disable_8259a(int port_nr) {
    if (port_nr < 0 || port_nr > 15) {
        disp_str("Invalid 8259A port number\n");
        return -1;
    }
    uchar settings;
    if (port_nr < 8) {
        /* master 8259a */
        uchar mask = 1;
        mask = mask << (port_nr);
        settings = in(0x21);

        //disp_str("before: ");
        //disp_num((int)settings & 0xFF);
        settings = settings | mask;
        //disp_str(" after: ");
        //disp_num((int)settings & 0xFF);
        
        out(settings, 0x21);
    }
    else {
        /* slave 8259a */
        uchar mask = 1;
        mask = mask << (port_nr-8);
        settings = in(0xA1);
        settings = settings | mask;
        out(settings, 0xA1);
    }
    return 0;
}

/* Show enabled/disabled ports */
void disp_8259a() {
    uint8 master_map, slave_map;
    master_map = in(0x21);
    slave_map  = in(0xA1);
    uint8 ptr = 1;
    for (int i = 0; i < 8; i++) {
        disp_str("master port ");
        disp_num(i);
        if (ptr & master_map) 
            disp_str(" off\n");
        else
            disp_str(" on\n");
        ptr = ptr << 1;
    }
    ptr = 1;
    for (int i = 0; i < 8; i++) {
        disp_str("slave port ");
        disp_num(i);
        if (ptr & slave_map) 
            disp_str(" off\n");
        else
            disp_str(" on\n");
        ptr = ptr << 1;
    }
    return ;
}


int register_handler(int nr_irq, void *callback) {
    if (nr_irq > 255 || nr_irq < 0) {
        disp_str("IRQ number should be >= 0 and <= 255 ");
        return -1;
    }
    idt[nr_irq] = GATE_ENTRY(gdt_selector[NR_GDT_FLAT_CODE], (uint)callback, 0, DA_386IGate);
    return 0;
}

void exception_handler(int vec_no, int error_no, int eip, int cs, int eflags) {
    if (vec_no >= EXCEPT_NUM) {
        disp_str("unknown verctor number: ");
        disp_num(vec_no);
        disp_str("\nUpdating exception handler is required.\n");
        return ;
    }
    char *err_msg[EXCEPT_NUM] = {
        "Devide error. ",           // 0
        "Single step exception. ",  // 1
        "NMI. ",                    // 2
        "Breakpoint Exception. ",   // 3
        "Overflow. ",               // 4
        "Bounds check. ",           // 5
        "Invalid opcode. ",         // 6
        "Corp not available. ",     // 7
        "Double fault. ",           // 8
        "Corp segment overrun. ",   // 9
        "Invalid TSS. ",            // 10
        "Segment not present. ",    // 11
        "Stack exception. ",        // 12
        "General protection. ",      // 13
        "Page fault. ",              // 14
        "Corp preserve. ",           // 15
        "Corp error. ",              // 16
        "Alignment check. ",         // 17
        "Machine check. ",           // 18
        "SIMD error. "              // 19
    };
    
    char *cur_msg = err_msg[vec_no];
    disp_str(cur_msg);
    if (error_no != -1) {
        disp_num(error_no);
    }
    disp_str(" eip: ");
    disp_num(eip);
    disp_str(" cs: ");
    disp_num(cs);
    disp_str(" eflags: ");
    disp_num(eflags);
    disp_str("\n");
    return ;
}

void foo_callback() {
    return ;
}










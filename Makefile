ASM         = nasm
ASM_FLAG    = -I include/
ASM_DBFLAG  = -DDEBUG -l temp.lst
ELF_FLAG	= -f elf
CC          = gcc
CC_32       = -m32 
CC_FLAG     = -nostdlib -ffreestanding -fno-stack-protector -nostdinc -c
LD          = ld
LD_FLAG     = -Ttext 0x200000 -m elf_i386 # -s strip the symbol of the output file

.PHONY : default default_debug clean

default : boot/boot.bin boot/loader.bin kernel/kernel.bin
	sync	
	qemu-system-i386 -fda floppy

kernel_debug : boot/boot.bin boot/loader.bin kernel/kernel.bin
	sync	
	qemu-system-i386 -fda floppy -s -S


default_debug : boot/boot_debug.bin boot/loader_debug.bin kernel/kernel.bin
	sync
	qemu-system-i386 -fda floppy -s -S
	make clean
clean : 
	# Remove MBR bin
	rm -rf boot/boot.bin
	# Remove bootloader from src and floppy disk
	rm -rf boot/loader.bin
	sudo rm -rf mountpoint/loader.bin
	# Remove kernel from src and floppy disk
	rm -rf kernel/kernel.bin
	rm -rf kernel/kernel_c.o
	rm -rf kernel/kernel_asm.o    
	rm -rf kernel/desc.o
	rm -rf kernel/libc.o
	rm -rf kernel/proc.o
	rm -rf kernel/keyboard.o
	rm -rf kernel/vm.o
	rm -rf kernel/syscall.o
	rm -rf kernel/irq.o
	rm -rf kernel/ipc.o
	rm -rf kernel/syscall_asm.o
	sudo rm -rf mountpoint/kernel.bin
	

kernel/kernel.bin : kernel/kernel.asm kernel/syscall.asm kernel/kernel.c kernel/types.h kernel/desc.h kernel/desc.c kernel/global.h kernel/libc.c kernel/libc.h kernel/io.h kernel/irq.h kernel/irq.c kernel/proc.c kernel/proc.h kernel/keyboard.c kernel/keyboard.h kernel/keymap.h kernel/fifo.h kernel/vm.c kernel/vm.h kernel/syscall.c kernel/syscall.h kernel/panic.h kernel/ipc.h kernel/ipc.c
	$(ASM) $(ASM_FLAG) $(ELF_FLAG) -o kernel/kernel_asm.o kernel/kernel.asm # -o kernel/printchar.o kernel/printchar.asm
	$(ASM) $(ASM_FLAG) $(ELF_FLAG) -o kernel/syscall_asm.o kernel/syscall.asm
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/kernel_c.o kernel/kernel.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/desc.o kernel/desc.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/libc.o kernel/libc.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/irq.o kernel/irq.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/proc.o kernel/proc.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/keyboard.o kernel/keyboard.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/vm.o kernel/vm.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/syscall.o kernel/syscall.c
	$(CC) $(CC_FLAG) $(CC_32) -o kernel/ipc.o kernel/ipc.c
	$(LD) $(LD_FLAG) -o kernel/kernel.bin kernel/desc.o kernel/keyboard.o kernel/syscall.o kernel/ipc.o kernel/vm.o kernel/irq.o kernel/proc.o kernel/libc.o kernel/kernel_asm.o kernel/kernel_c.o kernel/syscall_asm.o  #kernel/printchar.o kernel/printk.o  # kernel/kernel.bin must be the first file, so that the entry address would be at 0x30000
	sudo cp $@ mountpoint

boot/boot.bin : boot/boot.asm include/fat12hdr.inc include/loader.inc
	$(ASM) $(ASM_FLAG) -o $@ $<
	dd if=boot/boot.bin of=floppy bs=512 count=1 conv=notrunc

boot/boot_debug.bin : boot/boot.asm
	$(ASM) $(ASM_FLAG) $(ASM_DBFLAG) -o boot/boot.bin $<
	dd if=boot/boot.bin of=floppy bs=512 count=1 conv=notrunc

boot/loader.bin : boot/loader.asm include/fat12hdr.inc include/loader.inc	
	$(ASM) $(ASM_FLAG) -o boot/loader.bin $<
	sudo cp boot/loader.bin mountpoint

boot/loader_debug.bin : boot/loader.asm include/fat12hdr.inc include/loader.inc
	$(ASM) $(ASM_FLAG) $(ASM_DBFLAG) -o boot/loader.bin $<
	sudo cp boot/loader.bin mountpoint
    





# nasm -DDEBUG -o boot.bin boot.asm
# dd if=boot.bin of=floppy bs=512 count=1 conv=notrunc
# qemu-system-i386 -fda floppy 

loader_segment  equ 0x8000
loader_offset   equ 0x0     ; Loader will be loaded to 0x8000:0x0
loader_addr     equ 0x80000

FAT_offset equ 0xE000  ; FAT root directory will be loaded to 0x7000:E000

kernel_elf_segment  equ 0x5000
kernel_elf_offset   equ 0x0
kernel_elf_addr     equ 0x50000

kernel_entry    equ 0x30000

# Pengunix

A 32-bit x86 operating system written from scratch.

## Features

- **Custom bootloader**: FAT12 filesystem support, loads kernel from floppy
- **Protected mode**: GDT, LDT, and TSS setup
- **Interrupt handling**: 8259A PIC initialization, IDT setup
- **Process management**: Multi-process scheduling with priority support
- **Memory management**: Paging with page directory/tables
- **Keyboard driver**: PS/2 keyboard input handling
- **IPC**: Inter-process communication via mailboxes (send/receive)
- **System calls**: Basic syscall interface

## Project Structure

- `boot/` - Bootloader and second-stage loader (NASM assembly)
- `kernel/` - Kernel source code (C + assembly)
- `include/` - Shared headers for bootloader

## Build & Run

```bash
make          # Build and run in QEMU
make clean    # Clean build artifacts
```

Requires: `nasm`, `gcc`, `ld`, `qemu-system-i386`

## Credits
- Inspired by Orange's OS

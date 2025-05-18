# ECE 469 Lab 1: Booting a PC

## Overview

This lab introduces the x86 boot process and provides experience working with a basic bootloader and the early initialization stages of the JOS operating system. Students build familiarity with x86 assembly, GNU debugging tools (GDB), the QEMU emulator, ELF file structure, and virtual memory.

The lab is divided into three parts:
1. PC bootstrap and x86 assembly inspection.
2. Understanding and debugging the bootloader.
3. Exploring and modifying early JOS kernel code.

## Key Files

- `boot/boot.S`, `boot/main.c`: Bootloader code in assembly and C.
- `kern/entry.S`, `entrypgdir.c`: Kernel entry and page directory setup.
- `lib/printfmt.c`: Format string parsing used in kernel output.
- `kern/console.c`, `kern/monitor.c`, `kern/kdebug.c`: Console output and kernel monitor utilities.

## Key Exercises Completed

### Formatted Output (`vprintfmt` in `lib/printfmt.c`)
- Implemented support for the `%o` (octal) format specifier used in the kernel's formatted output system.

### Stack Backtrace (`mon_backtrace` in `kern/monitor.c`)
- Implemented a function to walk the call stack using saved `%ebp` values.
- Added output for function arguments and debug symbols using `debuginfo_eip()`.

### Debugging and Tracing with GDB
- Used `make qemu-nox-gdb` and `gdb` to debug early boot code.
- Stepped through execution from BIOS to bootloader to kernel.
- Set breakpoints at physical addresses such as `0x7c00` to trace bootloader execution.
- Inspected memory before and after virtual memory mapping to understand how `CR0_PG` affects address translation.

## Tools Used

- QEMU emulator for x86 PC simulation.
- GDB for instruction-level debugging of early boot code and kernel execution.
- `make grade` for testing and verifying lab functionality.
- `.gdbinit` file for automated debugging setup.

## Results

- All exercises completed and passed using the autograder (`make grade`).
- Implemented stack backtrace output with function names, source lines, and arguments.
- Gained a detailed understanding of early system bootstrapping, ELF loading, and virtual memory setup.

## Submission

Lab was packaged using `make handin` and submitted as `lab1-handin.tar.gz` to Brightspace.

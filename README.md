# ECE 469 Lab 3: User Environments

## Overview

In this lab, kernel support for user-mode environments was implemented. This involved building basic process management, setting up address spaces, loading and running user programs, and adding exception and syscall handling.

### Major components:

1. **Environment Management**
   - Implemented and initialized the `Env` structure and environment array.
   - Created and tracked user-mode environments (`envs[]`, `env_free_list`, `curenv`).
   - Implemented `env_create()` and `env_run()` to load ELF binaries and start execution.

2. **Virtual Memory for Environments**
   - Allocated a new page directory per environment with kernel mappings included.
   - Loaded ELF segments into environment memory using `load_icode()` and `region_alloc()`.

3. **Trap and System Call Handling**
   - Built the Interrupt Descriptor Table (IDT) and added trap handlers in `trapentry.S`.
   - Implemented the trap handling flow in `trap.c`, including `trap_dispatch()`.
   - Handled software interrupts and system calls using `int $0x30`.
   - Validated user pointers with `user_mem_check()` to ensure memory safety.

## Key Files

- `kern/env.c`: Core environment creation and loading functions.
- `kern/trap.c`, `kern/trapentry.S`: Trap setup and dispatcher logic.
- `kern/syscall.c`: System call interface and kernel syscall implementations.
- `lib/syscall.c`: User-mode syscall stubs using inline assembly.
- `lib/libmain.c`: Initializes user program and `thisenv` pointer.
- `inc/env.h`, `inc/trap.h`, `inc/syscall.h`: Shared kernel/user definitions.

## Implementation Highlights

- User programs are loaded from ELF binaries embedded in the kernel.
- The trap handling path builds a `Trapframe` on the kernel stack and dispatches to handlers.
- System calls pass arguments via registers and return values in `%eax`.
- Page faults are handled explicitly, with safety checks against invalid kernel-mode faults.
- `env_pgdir` holds each environment’s page directory, used to isolate address spaces.
- The breakpoint exception (`int3`) drops to the kernel monitor for debugging.

## Lab Questions

Answers to conceptual and implementation questions from the lab are written in `answers-lab3.txt`.

## Submission

Submitted via:

```bash
git add answers-lab3.txt README.md
git commit -am "Final submission for Lab 3"
make handin

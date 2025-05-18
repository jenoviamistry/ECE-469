# ECE 469 Lab 4: Preemptive Multitasking

## Overview

In this lab, the JOS kernel was extended to support preemptive multitasking, environment creation, and inter-process communication (IPC) across multiple CPUs. The lab is divided into three parts:

1. **Part A: Multiprocessor Support and Cooperative Scheduling**
   - Enabled symmetric multiprocessing (SMP) by booting application processors (APs).
   - Mapped per-CPU kernel stacks and initialized LAPIC and multiprocessor data structures.
   - Implemented basic system calls to create, configure, and manage environments.
   - Added round-robin scheduling with `sched_yield()` and cooperative multitasking via `sys_yield()`.

2. **Part B: Copy-on-Write Fork**
   - Implemented user-level `fork()` using copy-on-write optimization to delay copying until write access.
   - Installed a user-mode page fault handler using `set_pgfault_handler()` to manage COW behavior.
   - Handled recursive page faults and exception stack allocation for user environments.

3. **Part C: Preemption and IPC**
   - Enabled LAPIC-based clock interrupts to support kernel preemption of environments.
   - Handled IRQs 0–15 in `trap_dispatch()` and switched control using `sched_yield()`.
   - Implemented IPC system calls: `sys_ipc_recv()` and `sys_ipc_try_send()` for message and page sharing.
   - Created user-level IPC library with `ipc_recv()` and `ipc_send()`.

## Key Files

- `kern/init.c`: AP bootstrap and CPU startup logic.
- `kern/pmap.c`: Added MMIO region mapping and per-CPU kernel stack mapping.
- `kern/lapic.c`, `kern/mpconfig.c`, `kern/mpentry.S`: LAPIC configuration and AP startup.
- `kern/env.c`: System calls for environment creation and memory mapping.
- `kern/syscall.c`: Core syscall implementations including `sys_exofork`, `sys_yield`, `sys_ipc_*`.
- `kern/trap.c`, `kern/trapentry.S`: Trap setup, IRQ handling, and user page fault dispatch.
- `kern/sched.c`: Round-robin scheduler logic in `sched_yield()`.
- `lib/fork.c`: User-mode copy-on-write `fork()` logic.
- `lib/ipc.c`: User-mode IPC wrapper implementations.
- `lib/pfentry.S`: Assembly for user-mode page fault upcall.
- `inc/trap.h`, `inc/env.h`, `inc/memlayout.h`: Shared structures and constants.

## Implementation Highlights

- Booted and synchronized multiple CPUs using LAPIC inter-processor interrupts.
- Each CPU maintains its own kernel stack and TSS.
- The big kernel lock was used to prevent race conditions across multiple CPUs in kernel mode.
- Round-robin scheduler ensures fair environment switching across CPUs.
- Copy-on-write pages are marked with `PTE_COW` and lazily duplicated on write faults.
- Interrupt-based preemption uses clock IRQs to take control from environments.
- IPC allows sending 32-bit values and optional page mappings between environments.

## Testing

- Verified correct AP boot sequence and stack mapping with `make qemu CPUS=4`.
- Validated scheduling with `user/yield`, `user/spin`, and `stresssched`.
- Tested page fault handling with `user/faultalloc`, `faultread`, and `faultdie`.
- Verified COW-based fork correctness using `user/forktree`.
- Confirmed IPC with `user/pingpong` and `user/primes`.

## Lab Questions

Answers to conceptual and implementation questions from the lab are written in `answers-lab4.txt`.

## Submission

Submitted via:

```bash
git add answers-lab4.txt README.md
git commit -am "Final submission for Lab 4"
make handin

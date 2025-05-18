# ECE 469 Lab 5: File System, Spawn, and Shell

## Overview

In this lab, file system functionality was introduced to enable spawning new processes and running a shell from user space. The lab focuses on implementing basic file system primitives, RPC-based file system access, process spawning, and shell interaction.

### Major Components:

1. **Block Cache and Disk Access**
   - Implemented a page-fault-driven block cache using virtual memory and IDE polling I/O.
   - Functions implemented:
     - `bc_pgfault()` to load disk blocks into memory on-demand.
     - `flush_block()` to flush modified pages back to disk.

2. **File System Management**
   - Manipulated on-disk file system metadata using `fs/fs.c`.
   - Implemented:
     - `alloc_block()` to find and reserve free disk blocks.
     - `file_block_walk()` and `file_get_block()` to resolve file block offsets.

3. **RPC-based File System Server**
   - Created a file system server in `fs/serv.c` that communicates with user environments via IPC.
   - Functions implemented:
     - `serve_read()` and `serve_write()` for reading and writing files.
     - IPC handler functions in `lib/file.c` to send/receive file system calls.

4. **Process Spawning**
   - Implemented `sys_env_set_trapframe()` in the kernel to initialize child environments.
   - Set up `spawn()` from user space to load executables and start new environments.
   - Implemented `copy_shared_pages()` in `lib/spawn.c` and modified `duppage()` in `lib/fork.c` to share PTEs marked with `PTE_SHARE`.

5. **Shell and Console I/O**
   - Connected `kbd_intr` and `serial_intr` to the appropriate IRQ handlers.
   - Enabled interactive shell input/output via console file descriptors.
   - Added input redirection (`<`) support in the shell.

## Key Files

- `fs/fs.c`: On-disk file system manipulation logic.
- `fs/bc.c`: Block cache page fault handler.
- `fs/serv.c`: File system server that responds to IPC file operations.
- `lib/file.c`, `lib/fd.c`: File system client interface in user space.
- `lib/spawn.c`: Logic to load and start new environments from ELF binaries.
- `kern/syscall.c`: Kernel system call dispatch and implementations.
- `kern/trap.c`: IRQ handler registration for keyboard and serial input.
- `user/sh.c`: Shell implementation with pipe and redirection support.

## Implementation Highlights

- Block-level I/O is mapped into the virtual address space and populated lazily on page fault.
- Files are represented by a single `File` struct, combining inode and directory metadata.
- File descriptors and console are shared across fork/spawn using `PTE_SHARE`.
- Spawn loads ELF binaries and sets up stacks using `pgfault()` and memory copying.
- Shell can run piped commands, redirect input, and interact with the file system via standard I/O.

## Testing

- Verified correctness using provided programs:
  - `spawnhello`, `testpteshare`, `testkbd`, `testfdsharing`
  - `forktree`, `pingpong`, `primes`, and full shell command tests.
- Final tests:
  - `make run-testshell`
  - `make grade`

## Lab Questions

Answers to the conceptual and implementation questions are provided in `answers-lab5.txt`.

## Submission

Submitted via:

```bash
git add README.md answers-lab5.txt
git commit -am "Final submission for Lab 5"
make handin
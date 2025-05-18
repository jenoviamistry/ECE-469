# ECE 469 Lab 2: Memory Management

## Overview

In this lab, memory management is implemented in two major components:

1. **Physical Page Allocation**  
   - Implemented a page allocator that manages free and used physical memory pages using a `PageInfo` structure and a free list.
   - Implemented basic allocation and deallocation functions: `boot_alloc()`, `page_alloc()`, and `page_free()`.

2. **Virtual Memory Management**  
   - Set up virtual to physical address mapping using x86 page tables.
   - Implemented functions to insert, lookup, and remove virtual memory mappings:
     - `pgdir_walk()`
     - `boot_map_region()`
     - `page_lookup()`
     - `page_insert()`
     - `page_remove()`

## Key Files

- `kern/pmap.c`: Main file for physical and virtual memory management.
- `inc/memlayout.h`: Defines memory layout and address space organization.
- `kern/kclock.c`, `kern/kclock.h`: Provides total available memory via CMOS.

## Implementation Highlights

- Page allocator uses a linked list of `PageInfo` structures to track free pages.
- Memory mappings initialized in `mem_init()` to set up kernel address space.
- Used macros `KADDR(pa)` and `PADDR(va)` to convert between virtual and physical addresses.
- Reference counting via `pp_ref` field used to track shared memory use.

## Testing

- Verified correctness using:
  - `check_page_free_list()`
  - `check_page_alloc()`
  - `check_kern_pgdir()`
  - `check_page_installed_pgdir()`
- All tests passed using `make grade`.

## Lab Questions

Answers to conceptual and implementation questions from the lab are written in `answers-lab2.txt`.

## Submission

Submitted via:

```bash
git add answers-lab2.txt
git commit -am "Final submission for Lab 2"
make handin

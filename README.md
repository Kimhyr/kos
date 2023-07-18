# K-OS

A simple operating system for educational purposes.

I'm currently *kinda* following the book, [*Writing a Simple Operating System from Scratch* by Nick Blundell](https://www.cs.bham.ac.uk/~exr/lectures/opsys/10_11/lectures/os-dev.pdf).
This book is *very* incomplete. I don't recommend following it.

## Building

Before building, view [Prerequisites](#Prerequisites).

1. First enter `make init` in ths source directory (`/`); then,
2. enter `make all` in the source directory (`/`) to build everything.
    * Files should be located in the `/build` directory.

### Prerequisites

* A UNIX-like environment,
* [GNU Make](https://www.gnu.org/software/make/),
* [NASM](https://www.nasm.us/) (an assembler), and
* [QEMU](https://www.qemu.org/) (a machine emulator).

## Executing

After building

1. Enter `make em` to use the [QEMU](https://www.qemu.org/) emulator to run the
   operating system.

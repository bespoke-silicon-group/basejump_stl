# BaseJump Standard Template Library (STL) Repository

This library is a comprehensive hardware library for SystemVerilog that seeks to
contain all of the commonly used HW primitives. 

See this paper http://cseweb.ucsd.edu/~mbtaylor/papers/Taylor_DAC_BaseJump_STL_2018.pdf
which describes the design and usage.

## Contents

* bsg_async

This is for asynchronous building blocks, like the bsg_async_fifo, synchronizers, and credit counters.

* bsg_misc

Small, miscellaneous building blocks, like counters, reset timers, gray to binary coders, etc.

* bsg_fsb

Bsg front side bus modules; also murn interfacing code.

* bsg_comm_link

Source synchronous communication interface. (Also used as FPGA bridge).
 
* bsg_dataflow

For standalone modules involved in data plumbing. E.g. two-element fifos, fifo-to-fifo transfer engines,
sbox units, compare_and_swap, and array pack/unpack.

* bsg_test

Data, clock, and reset generator for test benches.

* testing

Mirrors the other directories, with tests.

## Contact

Email: taylor-bsg@googlegroups.com

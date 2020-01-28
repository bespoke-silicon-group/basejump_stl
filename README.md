# BaseJump Standard Template Library (STL) Repository

This library is a comprehensive hardware library for SystemVerilog that seeks to
contain all of the commonly used HW primitives. 

See this paper [docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf](https://github.com/bespoke-silicon-group/basejump_stl/blob/master/docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf)
which describes the design and usage.

To use BaseJump STL, you currently need to specify [bsg_misc/bsg_defines.v](https://github.com/bespoke-silicon-group/basejump_stl/blob/master/bsg_misc/bsg_defines.v) as a pre include file for your simulation or simulation toolsuite.

It defines a bunch of macros that are used across BaseJump STL.

## Contents

* bsg_misc

Small, miscellaneous building blocks, like counters, reset timers, gray to binary coders, etc.

* bsg_async

This is for asynchronous building blocks, like the bsg_async_fifo, synchronizers, and credit counters.

* bsg_fsb

Bsg front side bus modules; also murn interfacing code.

* bsg_link

Unidirectional off-chip high-speed source synchronous communication interface. (also used as FPGA bridge).
 
* bsg_dataflow

For standalone modules involved in data plumbing. E.g. two-element fifos, fifo-to-fifo transfer engines,
sbox units, compare_and_swap, and array pack/unpack.

* bsg_test

Data, clock, and reset generator for test benches.

* testing

Mirrors the other directories, with tests.

* hard

Mirrors other directories, contains replacement files for specific process technologies.

## Contact

Email: taylor-bsg@googlegroups.com

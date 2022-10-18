# BaseJump Standard Template Library (STL) Repository

This library is a comprehensive hardware library for SystemVerilog that seeks to
contain all of the commonly used HW primitives. 

See this paper [docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf](https://github.com/bespoke-silicon-group/basejump_stl/blob/master/docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf)
which describes the design and usage.

Please also see the [BSG SystemVerilog Style Guide](https://docs.google.com/document/d/1xA5XUzBtz_D6aSyIBQUwFk_kSUdckrfxa2uzGjMgmCU/edit#) which describes many of the conventions used in this library, including the variants of the valid/ready handshaking protocols.

Note: bsg_misc/bsg_defines.v contains many macros used by BaseJump STL. Make sure it is in your include path.

## Contents

* bsg_misc

 Lots of digital building blocks, like counters, reset timers, gray to binary coders, etc.
 
* bsg_mem

Portable SRAM and RF interfaces.

* bsg_dataflow

For standalone modules involved in data plumbing. E.g. two-element fifos, fifo-to-fifo transfer engines,
sbox units, compare_and_swap, and array pack/unpack.

* bsg_async

This is for asynchronous building blocks, like the bsg_async_fifo, synchronizers, and credit counters.

Note: for tapeouts, you will need to pay attention to the physical design and timing constraints for these components.

* bsg_noc

Network on chip implementations

* bsg_cache

Reusable Cache implementation

* bsg_link

High speed off-chip communication link (over LVCMOS I/Os, can hit 1.2 Gbps per pin to FPGA).

Unidirectional off-chip high-speed source synchronous communication interface. (also used as FPGA bridge).

* bsg_clk_gen

Open source portable clock generator (all-standard cell)

* bsg_dmc

LPDDR1 Dram Controller and PHY.
Requires advanced knowledge to tapeout.
 
* bsg_test

Data, clock, and reset generator for test benches.

* testing

Mirrors the other directories, with tests.

* hard

Mirrors other directories, contains replacement files for specific process technologies.

## Contact

Email: taylor-bsg@googlegroups.com

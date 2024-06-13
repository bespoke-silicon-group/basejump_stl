# BaseJump Standard Template Library (STL) Repository

This library is a comprehensive hardware library for SystemVerilog that seeks to
contain all of the commonly used HW primitives. 

See this paper [docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf](https://github.com/bespoke-silicon-group/basejump_stl/blob/master/docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf)
which describes the design and usage.

Please also see the [BSG SystemVerilog Style Guide](https://docs.google.com/document/d/1xA5XUzBtz_D6aSyIBQUwFk_kSUdckrfxa2uzGjMgmCU/edit#) which describes many of the conventions used in this library, including the variants of the valid/ready handshaking protocols.

Note: bsg_misc/bsg_defines.sv contains many macros used by BaseJump STL. Make sure it is in your include path.

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

## Interfaces
Since the [docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf](https://github.com/bespoke-silicon-group/basejump_stl/blob/master/docs/BaseJump_STL_DAC_2018_Camera_Ready.pdf) paper, we have expanded our understanding of the latency-insensitive paradigm. [BaseJump STL 2.0](https://github.com/bespoke-silicon-group/basejump_stl/pull/666) taxonomized several new producer and consumer interfaces. In BaseJump STL parlance, a latency-insensitive handshake consists of a "valid" and "ready" signal. The helpfulness of the handshake is classified by the extended name of the ready signal (the valid is always 'v'). The direction of dependencies is specified below. Dependencies may be combinational paths or latched. However, in all cases the handshake is considered "complete" during the single cycle when both "valid" and "ready" are high. Once a valid signal has been raised, it must not be lowered until a handshake has occurred.

The following interface types are clarified from the original BaseJump STL paper (-> indicates combinational dependency):

* ready_and_i || v_o (Helpful Producer)
* ready_then_i -> v_i (Demanding Producer)
* v_i -> yumi_o (Demanding Consumer)
* ready_and_i || v_i (Helpful Consumer)

Additionally, there are a few special cases:

* v_i / v_o (no ready signal, "handshake" happens without backpressure)
* ready_param_i / ready_param_o (helpfulness depends on parameterization)
* ready_passthrough_i -> ready_passthrough_o (consumption helpfulness depends on production helpfulness)

## Contact

Email: taylor-bsg@googlegroups.com

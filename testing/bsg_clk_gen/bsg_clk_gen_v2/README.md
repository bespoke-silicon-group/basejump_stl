This testbench appears to be out of date, but the instructions for using static timing analysis to check for races is probably still useful.

This link has a more up-to-date testing infrastructure for the clock generator, which was used in our July 2019 tapeouts:

https://bitbucket.org/taylor-bsg/bsg_designs/src/master/toplevels/bsg_ac_clk_gen_3/testing/traces/

It helps automatic generating testing traces for the clock generators that
you can use to look at waveforms in gate-level simulation with parasitics (the recommended methodology for verifation.)

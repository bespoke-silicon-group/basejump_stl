This is a rapid-port tunable standard-cell digital clock generator design. 

Note A: the bsg_nonsynth_clk_watcher module is very useful for monitoring the frequency and phase of the generated clock, for debugging and testing.


Note B: TESTING

In addition to doing SDF annotated post-APR simulation; or spice-extracted simulation of the clock generator, you can also use static timing analysis to see what the delay of one oscillator traversal is (corresponding to one phase of the clock period). Here are some some copy-and-paste of some timing checks we have used in previous tapeouts:
```
In IC compiler (or possibly Primetime), here is a different way to time these paths instead
  of running with SDF annotation.
  
  1. look at arrows in timing report, and read the value off the last arrow.
     does not include the delay of an AND2.
     
  a. longest path through oscillator (one half clock cycle) not including delay through ADG and gate A1/A2
  
  report_timing  -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y -to clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/A
  
  b. shortest paths through oscillator
  
 report_timing    -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A2/Y   -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A2/Y   -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/D    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/D   -to clk_gen_core_inst/clk_gen_osc_inst/fdt/A1/Y
 
  c. more generally :
  
  report_timing
    -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y

    // course delay element (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y   (slow ADG0)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A2/Y   (fast ADG0)

    // course delay element (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A1/Y   (slow ADG1)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A2/Y   (fast ADG1)

   // course delay tuner (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/A  (slowest)
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/B
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/C
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/D  (fastest)
    
    // fine delay tuner (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/A (slowest)
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/B
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/C
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/D (fastest)
    -to clk_gen_core_inst/clk_gen_osc_inst/fdt/A1/Y
 
40nm example:
 
report_timing -from clk_gen_core_inst/clk_gen_osc_inst/adt/I1/I -through clk_gen_core_inst/clk_gen_osc_inst/adt/M1/I3 -through clk_gen_core_inst/clk_gen_osc_inst/cdt/M1/I3 -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/I3 -to clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/ZN

```

Note C:

There is a testbench which we used for testing here https://github.com/bespoke-silicon-group/basejump_stl/tree/master/testing/bsg_clk_gen that was used for 180nm and 40nm tapeouts. For subsequent tapeouts, we use an infrastructure based on bsg_tag and trace replay, which is more versatile.
 

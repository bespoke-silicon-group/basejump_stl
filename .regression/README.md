## run_config json breakdown
1) Design_name: the name of your design, should be the same as the verilog file you’d like to run (ie. bsg_mem_1r1w_sync)
2) Filelist: all the files necessary for your design to synthesize. (itself, submodules that it depends on, and defines if it needs any)
3) Run_config:  a list of different configurations for your design
   - Name: this name will describe your run_config. (may include, size, frequency, type of design, whatever you like)
   - Description: add a more detailed description of what you’re trying to test
   - Parameters: if your design needs parameters, such as data width, then specify it here
   - Constraints: this is clock constraint
     - Clk_period: describes what period, in ns, used to constrain your design
     - Clk_port_name: if your design takes clk as an input, put the name of the clk port here, if your design does not use clk, put    “virtual” for virtual clock
     - Input: this is input2reg timing constraint
     - Output: this is reg2output timing constraint
     - Uncertainty: used for clk uncertainty 
     - Io_time_format: "period" or "percent". You can either specify the input/output timing constraint as period (in ns) or percent of the clk_period (ie input constraint = 50% of clk_period if “input”:”50” and “io_time_format”:”percent”)
     
## daily.json (should change the name to something not .json)
if you'd like to run multiple designs, fill out a file with includes like:
```bash
  include bsg_misc/bsg_and.json
  include bsg_mem/bsg_mem_1r1w.json
  include bsg_misc/bsg_xor.json
```

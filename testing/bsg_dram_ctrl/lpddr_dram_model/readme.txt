Disclaimer of Warranty:
-----------------------
This software code and all associated documentation, comments or other 
information (collectively "Software") is provided "AS IS" without 
warranty of any kind. MICRON TECHNOLOGY, INC. ("MTI") EXPRESSLY 
DISCLAIMS ALL WARRANTIES EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
TO, NONINFRINGEMENT OF THIRD PARTY RIGHTS, AND ANY IMPLIED WARRANTIES 
OF MERCHANTABILITY OR FITNESS FOR ANY PARTICULAR PURPOSE. MTI DOES NOT 
WARRANT THAT THE SOFTWARE WILL MEET YOUR REQUIREMENTS, OR THAT THE 
OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED OR ERROR-FREE. 
FURTHERMORE, MTI DOES NOT MAKE ANY REPRESENTATIONS REGARDING THE USE OR 
THE RESULTS OF THE USE OF THE SOFTWARE IN TERMS OF ITS CORRECTNESS, 
ACCURACY, RELIABILITY, OR OTHERWISE. THE ENTIRE RISK ARISING OUT OF USE 
OR PERFORMANCE OF THE SOFTWARE REMAINS WITH YOU. IN NO EVENT SHALL MTI, 
ITS AFFILIATED COMPANIES OR THEIR SUPPLIERS BE LIABLE FOR ANY DIRECT, 
INDIRECT, CONSEQUENTIAL, INCIDENTAL, OR SPECIAL DAMAGES (INCLUDING, 
WITHOUT LIMITATION, DAMAGES FOR LOSS OF PROFITS, BUSINESS INTERRUPTION, 
OR LOSS OF INFORMATION) ARISING OUT OF YOUR USE OF OR INABILITY TO USE 
THE SOFTWARE, EVEN IF MTI HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
DAMAGES. Because some jurisdictions prohibit the exclusion or 
limitation of liability for consequential or incidental damages, the 
above limitation may not apply to you.

Copyright 2008 Micron Technology, Inc. All rights reserved.

Getting Started:
----------------
Unzip the included files to a folder.
Compile mobile_ddr.v and tb.v using a verilog simulator.
Simulate the top level test bench tb.
Or, if you are using the ModelSim simulator, type "do tb.do" at the prompt.

File Descriptions:
------------------
mobile_ddr.v                    --mobile ddr model 
mobile_ddr_mcp.v                --structural wrapper for mobile_ddr multi-chip package model
128Mb_mobile_ddr_parameters.vh  --File that contains all parameters used by the model
256Mb_mobile_ddr_parameters.vh  --File that contains all parameters used by the model
512Mb_mobile_ddr_parameters.vh  --File that contains all parameters used by the model
1024Mb_mobile_ddr_parameters.vh --File that contains all parameters used by the model
2048Mb_mobile_ddr_parameters.vh --File that contains all parameters used by the model
readme.txt                      --This file
tb.v                            --Test bench
tb.do                           --File that compiles and runs the above files

Defining the Density (part size):
-------------------------
The verilog compiler directive "`define" may be used to choose between on of the
densities supported by the mobile ddr model.  Allowable densities are listed in
the *.vh file.  The density is used to select a set of bank, row, column, and timing 
parameters for the mobile ddr model.  The following are examples of defining 
the density.

    simulator   command line
    ---------   ------------
    ModelSim    vlog +define+den512Mb mobile_ddr.v
    VCS         vcs +define+den512Mb mobile_ddr.v
    NC-Verilog  ncverilog +define+den512Mb mobile_ddr.v


Defining the Speed Grade:
-------------------------
The verilog compiler directive "`define" may be used to choose between 
multiple speed grades supported by the mobile ddr model.  Allowable speed 
grades are listed in the mobile_ddr_parameters.vh file and begin with the 
letters "sg".  The speed grade is used to select a set of timing 
parameters for the mobile ddr model.  The following are examples of defining 
the speed grade.

    simulator   command line
    ---------   ------------
    ModelSim    vlog +define+sg75 mobile_ddr.v
    VCS         vcs +define+sg75 mobile_ddr.v
    NC-Verilog  ncverilog +define+sg75 mobile_ddr.v


Defining the Organization:
--------------------------
The verilog compiler directive "`define" may be used to choose between 
multiple organizations supported by the mobile ddr model.  Valid 
organizations include "x16" and "x32", and are listed in the 
mobile_ddr_parameters.vh file.  The organization is used to select the amount 
of memory and the port sizes of the mobile ddr model.  The following are
examples of defining the organization.

    vlog +define+x16 mobile_ddr.v
    simulator   command line
    ---------   ------------
    ModelSim    vlog +define+x16 mobile_ddr.v
    VCS         vcs +define+x16 mobile_ddr.v
    NC-Verilog  ncverilog +define+x16 mobile_ddr.v

All combinations of speed grade and organization are considered valid 
by the mobile ddr model even though a Micron part may not exist for every 
combination.

Allocating Memory:
------------------
An associative array has been implemented to reduce the amount of 
static memory allocated by the mobile ddr model.  The number of 
entries in the associative array is controlled by the part_mem_bits 
parameter, and is equal to 2^part_mem_bits.  For example, if the 
part_mem_bits parameter is equal to 10, the associative array will be 
large enough to store 1024 write data transfers to unique addresses.  
The following are examples of setting the MEM_BITS parameter to 8.

    simulator   command line
    ---------   ------------
    ModelSim    vsim -Gpart_mem_bits=8 mobile_ddr
    VCS         vcs -pvalue+part_mem_bits=8 mobile_ddr.v
    NC-Verilog  ncverilog +defparam+mobile_ddr.part_mem_bits=8 mobile_ddr.v

It is possible to allocate memory for every address supported by the 
mobile ddr model by using the verilog compiler directive "`define FULL_MEM".
This procedure will improve simulation performance at the expense of 
system memory.  The following are examples of allocating memory for
every address.

    Simulator   command line
    ---------   ------------
    ModelSim    vlog +define+FULL_MEM mobile_ddr.v
    VCS         vcs +define+FULL_MEM mobile_ddr.v
    NC-Verilog  ncverilog +define+FULL_MEM mobile_ddr.v


Reduced Page Mode:
------------------
Mobile DDR 256Mb, 512Mb, and 1024Mb part may be built with the reduced page size
architecture. This part is accessed with the +define+RP designator. RP
parts have one extra row bit and one less column bit effectively cutting
the page size in half but doubling the number of rows keeping total part
size the same.

    Part Size   Valid RP Designators
    ---------   --------------------
    256Mb       +define+RP
    512Mb       +define+RP
    1024Mb      +define+RP

    Simulator   command line
    ---------   ------------
    ModelSim    vlog +define+RP mobile_ddr.v
    VCS         vcs +define+RP mobile_ddr.v
    NC-Verilog  ncverilog +define+RP mobile_ddr.v

Multi-Chip Package Model:
-------------------------
The 1024Mb model can be supported in a Multi Chip Package, that allows
multiple die models in one structural package. The number of ranks and 
chip selects of the mcp can be configured by using the `DUAL_RANK define 
on the simulator call line.  The currently supported configurations are 
listed below:

    Package Configuration   Valid MCP Designator
    ---------------------   --------------------
    2 Chip Selects, 2 Die   +define+DUAL_RANK
    2 Chip Selects, 1 Die   (default)

The single rank mcp is the default.  In order to simulate the DUAL_RANK 
model, the define needs to be added:

    Simulator   command line
    ---------   ------------
    ModelSim    vlog +define+DUAL_RANK mobile_ddr.v mobile_ddr_mcp.v
    VCS         vcs +define+DUAL_RANK mobile_ddr.v mobile_ddr_mcp.v
    NC-Verilog  ncverilog +define+DUAL_RANK mobile_ddr.v mobile_ddr_mcp.v


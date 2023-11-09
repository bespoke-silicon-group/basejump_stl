# FPGA side of the bsg_link

The directory contains, instructions, source code and timing constraints.

Also good would be a link to a google doc that contains advice for PCB stackup / routing advice / decap selection and via placement for attain high speed for bsg_link.

## How to use the source codes

1. Remove bsg_link_oddr_phy.sv, bsg_link_iddr_phy.sv and bsg_link_ddr_upstream.sv from the Vivado project.
2. Add source codes in this directory to the Vivado project.
3. Generate a 90-degree phase delayed clock using the on-FPGA MMCM, connect CLK90 to the bsg_link_ddr_upstream module.

## How to use the XDC timing constraints

1. Copy-n-paste contents in tcl/bsg_link_ddr.sample_constraints.xdc into the .xdc file of the Vivado project.
2. Modify the periods, names, ports, pins, and margins based on the target application.

Note: Xilinx .xdc file does not go through regular tcl parser, some tcl commands (like for-loop) are not supported. As a result, **user should copy-n-paste these constraints for each bsg_link channel**.

## How to use the TCL timing constrains

1. In the Vivado synthesis flow, avoid using "read_xdc" with constraints spec'd in a tcl file.
2. Include tcl/bsg_link_ddr.sample_constraints.tcl, call the tcl function with parameters based on user application.

## How to use the XDC placement constraints

1. User should copy-n-paste the constraints to the target Vivado flow.
2. Constraints should be duplicated to all pins / all IO banks (only single pin / bank is constrained in the example).

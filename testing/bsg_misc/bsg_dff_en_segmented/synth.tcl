set TOP           "dut"
set RTL_DIR       "."
set OUT_DIR       "./WORK"
file mkdir $OUT_DIR

# Typical 45 nm reference libraries (replace with your own)
#set target_library   [list "/path/to/saed90nm_typ.db"]
#set LIB_SRC "/gro/cad/pdk/sky130/sky130A.latest/libs.ref/sky130_fd_sc_hd/lib/sky130_fd_sc_hd__tt_025C_1v80.lib"

set link_library     "* $target_library"
set search_path      [list $RTL_DIR ../../../bsg_dataflow ../../../bsg_misc]
#set target_library   [list $LIB_SRC]
set target_library [list "/gro/cad/pdk/free45/bsg/db/stdcell/nldm/NangateOpenCellLibrary_typical.db"]
set link_library     "* $target_library"

#read_lib $LIB_SRC

# ------- Read + elaborate ---------------------------------------------
analyze -format sverilog  ../../../bsg_misc/bsg_dff_en.sv
analyze -format sverilog  ../../../bsg_misc/bsg_dff_en_segmented.sv
analyze -format sverilog  dut.sv
elaborate $TOP                             ;# build design hierarchy
current_design $TOP

create_clock -name clk_i -period 10.0 -waveform {0 5} [get_ports clk_i]

# ------- Optional: quick sanity switches ------------------------------
set_fix_multiple_port_nets -all -buffer_constants

# ------- Synthesize ----------------------------------------------------
compile_ultra -no_autoungroup -gate_clock   ;# fast, good-quality compile

# ------- Write results -------------------------------------------------
write -format verilog -hier -output $OUT_DIR/${TOP}_gates.v
write_sdf   -version 3.0        $OUT_DIR/${TOP}.sdf
report_timing  -max_paths 10  > $OUT_DIR/timing.rpt
report_area                 > $OUT_DIR/area.rpt

quit

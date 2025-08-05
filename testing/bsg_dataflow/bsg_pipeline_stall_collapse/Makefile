# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_pipeline_stall_collapse.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_dataflow
BSG_MISC_FILES      =   bsg_defines.sv bsg_cycle_counter.sv bsg_scan.sv bsg_dff_en.sv bsg_dff_reset_en.sv bsg_dff_en_segmented.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv

TEST_MAIN   = test_bsg.sv dut.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = DUMMY

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
DUMMY = 0
############################################################################

include ../../Makefile.sim


synth:
	$(DC_SHELL) -f synth.tcl


clean:
	-rm -f *.mr *.pvl *.syn
	-rm -rf csrc WORK cksum_dir alib-52 simv.daidir
	-rm -f *.log ucli.key *.svf moduleparamid outfile simv


verilator:
	/gro/cad/verilator/v5.036/verilator/bin/verilator -Wno-fatal -top-module test_bsg -y $(TOP)/bsg_test -I$(TOP)/bsg_misc --binary $(TEST_MAIN) $(BSG_TESTME_DIR)/$(BSG_TESTME_FILES) $(BSG_MISC_FLES)

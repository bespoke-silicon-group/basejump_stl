# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015

HARDEN = 0

TOP = ../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    = 
BSG_TESTME_DIR      = 
BSG_MISC_FILES      =  bsg_defines.sv bsg_counter_clear_up.sv bsg_mux2_gatestack.sv bsg_dff.sv bsg_dff_en.sv
BSG_ASYNC_FILES     = bsg_launch_sync_sync.sv
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_TAG_FILES       = bsg_tag_pkg.sv bsg_tag_client.sv bsg_tag_master.sv
BSG_GUTS_FILES      =
BSG_TEST_FILES      = bsg_nonsynth_clock_gen.sv

BSG_CLK_GEN_FILES   =
ifeq ($(HARDEN),0)
BSG_CLK_GEN_DIR     = $(TOP)/bsg_clk_gen
BSG_HARD_LIB        =
else
BSG_CLK_GEN_DIR     = $(TOP)/hard/bsg_clk_gen
BSG_HARD_LIB        = -v /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v
endif

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P    = 8
############################################################################

include ../Makefile.sim

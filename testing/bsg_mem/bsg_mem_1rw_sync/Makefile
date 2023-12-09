# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_mem_1r1w.sv
# Bandhav Veluri 8/29/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_mem_1rw_sync.sv bsg_mem_1rw_sync_synth.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_mem
BSG_MISC_FILES      =   bsg_defines.sv bsg_cycle_counter.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv \
                       bsg_nonsynth_random_gen.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P ELS_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P = 1 4 5
ELS_P   = 1 2 3 4 5 8 
############################################################################

include ../../Makefile.sim

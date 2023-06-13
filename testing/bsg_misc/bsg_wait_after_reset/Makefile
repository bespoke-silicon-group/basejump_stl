# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_wait_after_reset.sv
# Bandhav Veluri 6/5/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################

BSG_TESTME_FILES    =   bsg_wait_after_reset.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_defines.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P OTHER_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P = 1 2 3 4
OTHER_P = 1
############################################################################

include ../../Makefile.sim

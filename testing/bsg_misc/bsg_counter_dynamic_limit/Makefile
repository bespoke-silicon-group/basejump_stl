# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_counter_w_overflow.v renamed as bsg_counter_dynamic_limit
# Bandhav Veluri 5/21/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_counter_dynamic_limit.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_circular_ptr.sv bsg_defines.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.sv \
									bsg_nonsynth_clock_gen.sv

#TEST_FILES = test_assembler.v
#TEST_MAIN = test_bsg_comm_link.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = testbench

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P OVERFLOW_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P    = 1 2 3 4 8
OVERFLOW_P = 1 2 3 4 8
############################################################################

include ../../Makefile.sim

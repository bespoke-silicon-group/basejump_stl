# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_counter_clock_downsample.sv
# Scott Davidson (stdavids@eng.ucsd.edu) 8/21/2016

TOP = ../../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    = bsg_counter_clock_downsample.sv bsg_strobe.sv bsg_dff.sv bsg_xnor.sv bsg_muxi2_gatestack.sv bsg_nand.sv bsg_nor3.sv bsg_reduce.sv bsg_buf.sv
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_TEST_FILES      = bsg_nonsynth_clock_gen.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
# This test currently fails because strobe.v does not currently work for inputs of WIDTH_P = 1
WIDTH_P    = 1 2 3 4 8
############################################################################

include ../../Makefile.sim

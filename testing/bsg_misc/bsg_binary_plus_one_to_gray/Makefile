# MBT 8-26-2014

#
# Change these variables to determine what tests are run.
#

#CHANNEL_WIDTH           = 8

#RING_BYTES              = 10# 1

#NUM_CHANNELS            =   1 # 2 3 4 5 6 7 8 9 10 11 # 12 13 14 15
#CORE_0_PERIOD      =  2
#IO_MASTER_0_PERIOD =   6
#IO_MASTER_1_PERIOD =   2
#CORE_1_PERIOD      =   1

TOP = ../../..

BSG_TESTME_FILES    = bsg_binary_plus_one_to_gray.sv
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_cycle_counter.sv bsg_defines.sv bsg_scan.sv
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.sv bsg_nonsynth_clock_gen.sv bsg_nonsynth_ascii_writer.sv

TEST_MAIN=test_bsg.sv
TEST_MODULE = test_bsg

WIDTH_P = 1 2 3 4 5 8

scan_params = WIDTH_P

include ../../Makefile.sim

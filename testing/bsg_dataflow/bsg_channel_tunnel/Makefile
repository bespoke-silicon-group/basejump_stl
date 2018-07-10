# Example parameter scan makefile
#
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_channel_narrow.v
# Bandhav Veluri 6/16/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_channel_tunnel.v
BSG_TESTME_DIR      =   $(TOP)/bsg_dataflow
BSG_MISC_FILES      =   bsg_defines.v bsg_counter_up_down.v bsg_counter_up_down_variable.v bsg_counter_clear_up.v  bsg_round_robin_arb.v  bsg_crossbar_o_by_i.v  bsg_circular_ptr.v bsg_decode_with_v.v bsg_decode.v bsg_mux_one_hot.v bsg_cycle_counter.v
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_channel_tunnel_in.v bsg_channel_tunnel_out.v  bsg_round_robin_n_to_1.v bsg_1_to_n_tagged_fifo.v bsg_1_to_n_tagged.v bsg_fifo_1r1w_small.v bsg_fifo_tracker.v
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       = bsg_mem_1r1w.v

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.v \
                       bsg_nonsynth_clock_gen.v \
                       bsg_nonsynth_ascii_writer.v

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P  = 1 32 33 64
NUM_IN_P = 1 2 3 4
REMOTE_CREDITS_P = 1 2 3 4 5 6 16
# 2^dec must be <= remote_credits =)
LG_CREDIT_DECIMATION_P = 0 1 2 3
USE_PSEUDO_LARGE_FIFO_P = 0 1
# whether to have receive rates; or 2^n declining receive rates on each channel
ASYMMETRIC_P = 0
############################################################################

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P NUM_IN_P REMOTE_CREDITS_P LG_CREDIT_DECIMATION_P ASYMMETRIC_P USE_PSEUDO_LARGE_FIFO_P

include ../../Makefile.sim

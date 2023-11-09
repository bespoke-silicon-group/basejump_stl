# Example parameter scan makefile
#
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_channel_narrow.sv
# Bandhav Veluri 6/16/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_channel_tunnel.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_dataflow
BSG_MISC_FILES      =   bsg_defines.sv bsg_counter_up_down.sv bsg_counter_up_down_variable.sv bsg_counter_clear_up.sv  bsg_round_robin_arb.sv  bsg_crossbar_o_by_i.sv  bsg_circular_ptr.sv bsg_decode_with_v.sv bsg_decode.sv bsg_mux_one_hot.sv bsg_cycle_counter.sv
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_channel_tunnel_in.sv bsg_channel_tunnel_out.sv  bsg_round_robin_n_to_1.sv bsg_1_to_n_tagged_fifo.sv bsg_1_to_n_tagged.sv bsg_fifo_1r1w_small.sv bsg_fifo_tracker.sv bsg_fifo_1r1w_small_unhardened.sv
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       = bsg_mem_1r1w.sv bsg_mem_1r1w_synth.sv

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv

TEST_MAIN   = test_bsg.sv
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

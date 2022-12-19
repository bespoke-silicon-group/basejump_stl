# Example parameter scan makefile
#
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_mem_1rw_sync_byte_masked.v
# Bandhav Veluri 8/29/2015

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_mem_banked_crossbar.v
BSG_TESTME_DIR      =   $(TOP)/bsg_mem
BSG_MISC_FILES      =   bsg_defines.v bsg_crossbar_o_by_i.v bsg_transpose.v bsg_cycle_counter.v bsg_encode_one_hot.v bsg_mux_one_hot.v bsg_round_robin_arb.v  bsg_arb_fixed.v bsg_priority_encode_one_hot_out.v bsg_scan.v
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       =   bsg_mem_1rw_sync.v bsg_mem_1rw_sync_mask_write_byte.v bsg_mem_1rw_sync_mask_write_byte_synth.v bsg_mem_1rw_sync_synth.v

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.v \
                       bsg_nonsynth_clock_gen.v \
                       bsg_nonsynth_ascii_writer.v \
                       bsg_nonsynth_random_gen.v

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
PORTS_P = 1 2 3 4
BANKS_P = 1 2 3 4
BANK_SIZE_P = 4 16 64 256
RR_LO_HI_P  = 0  1  2

# this is a list of all variables you want to vary for the simulation
scan_params = PORTS_P BANKS_P BANK_SIZE_P RR_LO_HI_P

include ../../Makefile.sim
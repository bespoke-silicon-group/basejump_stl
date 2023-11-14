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
BSG_TESTME_FILES    =   bsg_mem_banked_crossbar.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_mem
BSG_MISC_FILES      =   bsg_defines.sv bsg_crossbar_o_by_i.sv bsg_transpose.sv bsg_cycle_counter.sv bsg_encode_one_hot.sv bsg_mux_one_hot.sv bsg_round_robin_arb.sv  bsg_arb_fixed.sv bsg_priority_encode_one_hot_out.sv bsg_scan.sv
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       =   bsg_mem_1rw_sync.sv bsg_mem_1rw_sync_mask_write_byte.sv bsg_mem_1rw_sync_mask_write_byte_synth.sv bsg_mem_1rw_sync_synth.sv

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv \
                       bsg_nonsynth_random_gen.sv

TEST_MAIN   = test_bsg.sv
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

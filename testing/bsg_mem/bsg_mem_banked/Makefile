# Parameter scan makefile for the banked bsg_mem wrappers
#
# test_bsg.sv checks the banked wrappers, over the bank geometries it lists,
# against a reference memory. This makefile scans latch_last_read_p.

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_mem_1rw_sync_mask_write_bit_banked.sv \
                        bsg_mem_1rw_sync_mask_write_byte_banked.sv \
                        bsg_mem_1r1w_sync_banked.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_mem
BSG_MISC_FILES      =   bsg_defines.sv bsg_decode.sv bsg_decode_with_v.sv bsg_dff.sv \
                        bsg_dff_en.sv bsg_dff_en_bypass.sv bsg_mux.sv
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       =   bsg_mem_1rw_sync.sv bsg_mem_1rw_sync_synth.sv \
                        bsg_mem_1rw_sync_mask_write_bit.sv bsg_mem_1rw_sync_mask_write_bit_synth.sv \
                        bsg_mem_1rw_sync_mask_write_byte.sv bsg_mem_1rw_sync_mask_write_byte_synth.sv \
                        bsg_mem_1r1w_sync.sv bsg_mem_1r1w_sync_synth.sv

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = LATCH_P

# this is a list of all values for each variable in the scan_params list
LATCH_P = 0 1
############################################################################

include ../../Makefile.sim

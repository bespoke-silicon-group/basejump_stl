# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#

TOP = ../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_wormhole_broadcast.sv
BSG_TESTME_DIR      =   $(TOP)/bsg_noc
BSG_MISC_FILES      =   bsg_defines.sv bsg_cycle_counter.sv bsg_scan.sv bsg_id_pool_dealloc_alloc_one_hot.sv bsg_encode_one_hot.sv bsg_arb_round_robin.sv bsg_priority_encode_one_hot_out.sv bsg_dff_reset_set_clear.sv bsg_counter_set_down.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_two_fifo.sv
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_NOC_FILES       = bsg_wormhole_router_packet_parser.sv bsg_wormhole_router_input_control.sv
BSG_MEM_FILES       = bsg_mem_1r1w.sv bsg_mem_1r1w_synth.sv
BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = DUMMY

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
DUMMY = 0
############################################################################

include ../../Makefile.sim

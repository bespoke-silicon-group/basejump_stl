# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_mesh_router.v
# Bandhav Veluri 2/4/2016

TOP = ../../..

# place the parameters you want to scan here.
BSG_TESTME_FILES    = bsg_wormhole_router_adapter_in.v
BSG_TESTME_DIR      = $(TOP)/bsg_noc
BSG_MISC_FILES      = bsg_counter_clear_up.v bsg_mux.v bsg_scan.v bsg_defines.v bsg_mux_one_hot.v bsg_encode_one_hot.v bsg_circular_ptr.v bsg_arb_round_robin.v bsg_cycle_counter.v bsg_transpose.v bsg_array_concentrate_static.v bsg_unconcentrate_static.v bsg_concentrate_static.v
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_fifo_1r1w_small.v bsg_two_fifo.v bsg_fifo_1r1w_small_unhardened.v bsg_fifo_tracker.v bsg_parallel_in_serial_out_dynamic.v
BSG_FSB_FILES       = bsg_fsb_node_trace_replay.v
BSG_GUTS_FILES      =
BSG_NOC_FILES       = bsg_noc_pkg.v bsg_mesh_router_pkg.v bsg_mesh_router_decoder_dor.v bsg_noc_links.vh
BSG_MEM_FILES       = bsg_mem_1r1w.v bsg_mem_1r1w_synth.v
ADDITIONAL_FILES		= bsg_trace_rom.v

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.v \
                  bsg_nonsynth_clock_gen.v \
                  bsg_nonsynth_ascii_writer.v

#TEST_FILES = test_assembler.v
#TEST_MAIN = test_bsg_comm_link.v

TEST_MAIN   = testbench.v
TEST_MODULE = testbench

# this is a list of all variables you want to vary for the simulation
scan_params = DUMMY

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.

DUMMY = 0


include ../../Makefile.sim

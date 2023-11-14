# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_mesh_router.sv
# Bandhav Veluri 2/4/2016

TOP = ../../..

# place the parameters you want to scan here.
BSG_TESTME_FILES    = bsg_mesh_to_ring_stitch.sv
BSG_TESTME_DIR      = $(TOP)/bsg_noc
BSG_MISC_FILES      = bsg_scan.sv bsg_defines.sv bsg_mux_one_hot.sv bsg_encode_one_hot.sv bsg_circular_ptr.sv bsg_arb_round_robin.sv bsg_cycle_counter.sv bsg_transpose.sv bsg_array_concentrate_static.sv bsg_unconcentrate_static.sv bsg_concentrate_static.sv
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_fifo_1r1w_small.sv bsg_fifo_1r1w_small_unhardened.sv bsg_fifo_tracker.sv
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_NOC_FILES       = bsg_noc_pkg.sv bsg_mesh_router_pkg.sv bsg_mesh_router_decoder_dor.sv
BSG_MEM_FILES       = bsg_mem_1r1w.sv bsg_mem_1r1w_synth.sv

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.sv \
                  bsg_nonsynth_clock_gen.sv \
                  bsg_nonsynth_ascii_writer.sv

#TEST_FILES = test_assembler.v
#TEST_MAIN = test_bsg_comm_link.sv

TEST_MAIN   = test_mesh_to_ring_stitch.sv
TEST_MODULE = test_mesh_to_ring_stitch

# this is a list of all variables you want to vary for the simulation
scan_params = DATA_WIDTH_P MESH_EDGE_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.

DATA_WIDTH_P = 4
MESH_EDGE_P  = 0 1 2


include ../../Makefile.sim

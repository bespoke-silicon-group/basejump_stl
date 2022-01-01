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
include $(TOP)/../bsg_cadenv/cadenv.mk

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =   bsg_channel_tunnel.v
BSG_TESTME_DIR      =   $(TOP)/bsg_dataflow
BSG_MISC_FILES      =   bsg_defines.v bsg_counter_up_down.v bsg_counter_up_down_variable.v bsg_counter_clear_up.v  bsg_round_robin_arb.v  bsg_crossbar_o_by_i.v  bsg_circular_ptr.v bsg_decode_with_v.v bsg_decode.v bsg_mux_one_hot.v bsg_cycle_counter.v
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_channel_tunnel_in.v bsg_channel_tunnel_out.v  bsg_round_robin_n_to_1.v bsg_1_to_n_tagged_fifo.v bsg_1_to_n_tagged.v bsg_fifo_1r1w_small.v bsg_fifo_1r1w_small_unhardened.v bsg_fifo_tracker.v
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       = bsg_mem_1r1w.v bsg_mem_1r1w_synth.v

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.v \
                       bsg_nonsynth_clock_gen.v \
                       bsg_nonsynth_ascii_writer.v

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P  = 32 33 64
NUM_IN_P = 2 3 4
NUM_CREDIT_CHANNELS_P = 1 2
REMOTE_CREDITS_P = 1 2 3 4 5 6 16
# 2^dec must be <= remote_credits =)
LG_CREDIT_DECIMATION_P = 0 1 2 3
USE_PSEUDO_LARGE_FIFO_P = 0 1
# whether to have receive rates; or 2^n declining receive rates on each channel
ASYMMETRIC_P = 0
############################################################################

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P NUM_IN_P NUM_CREDIT_CHANNELS_P REMOTE_CREDITS_P LG_CREDIT_DECIMATION_P ASYMMETRIC_P USE_PSEUDO_LARGE_FIFO_P

#include ../../Makefile.sim
##########
# settings for Xilinx Vivado
BSG_IP_CORES_COMP = xvlog --sv
BSG_IP_CORES_ELAB = xelab -debug typical -s top_sim --timescale=1ns/1ps
BSG_IP_CORES_SIM  = xsim --runall top_sim
BSG_IP_CORES_SIM_DEFINE_PARAM =-d@
BSG_IP_CORES_SIM_INCLUDE_DIRS = -i $(TOP)/bsg_test -i $(TOP)/bsg_misc -i $(TOP)/bsg_dataflow
BSG_IP_CORES_SIM_CLEAN_FILES = xvlog* xelab* webtalk* xsim* *.wdb
#
##########

ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x))     \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x))     \
              $(foreach x,$(BSG_MEM_FILES),$(TOP)/bsg_mem/$(x))     \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x))   \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x))   \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x))           \
              $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x))       \
              $(TEST_MAIN)

# default rule: run all of the targets.
all: clean
	vcs -sverilog -full64 -assert svaext $(ALL_FILES) +define+WIDTH_P=32 +define+NUM_IN_P=2 +define+NUM_CREDIT_CHANNELS_P=2 +define+REMOTE_CREDITS_P=4 +define+LG_CREDIT_DECIMATION_P=0 +define+USE_PSEUDO_LARGE_FIFO_P=0 +define+ASYMMETRIC_P=0 \
		+incdir+$(TOP)/bsg_misc +debug_all +vcs+vcdpluson +vcs+vcdplusautoflushon -timescale=1ns/1ps
	./simv +vcd+vcspluson +vcs+vcdplusautoflushon

view:
	dve -full64 -vpd vcdplus.vpd &

# this runs an individual target
# we replace the @ with a space so that the parameters are used as
# command line options

run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) | /usr/bin/tee outfile
  
clean:
	@echo removing outfile
	rm -f outfile
	rm -rf csrc
	rm -rf simv*
	rm -f vc_hdrs.h


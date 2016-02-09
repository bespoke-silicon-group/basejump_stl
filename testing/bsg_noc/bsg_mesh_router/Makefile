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
BSG_TESTME_FILES    = bsg_mesh_router.v
BSG_TESTME_DIR      = $(TOP)/bsg_noc
BSG_MISC_FILES      = bsg_defines.v bsg_mux_one_hot.v bsg_encode_one_hot.v bsg_circular_ptr.v bsg_round_robin_arb.v bsg_cycle_counter.v 
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = bsg_fifo_1r1w_small.v
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_NOC_FILES       = bsg_noc_pkg.v
BSG_MEM_FILES       = bsg_mem_1r1w.v

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.v \
                  bsg_nonsynth_clock_gen.v \
                  bsg_nonsynth_ascii_writer.v

#TEST_FILES = test_assembler.v
#TEST_MAIN = test_bsg_comm_link.v

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = DATA_WIDTH_P MESH_EDGE_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.

DATA_WIDTH_P = 4
MESH_EDGE_P  = 0 1 2



############################# SIMULATOR COMMANDS ###########################
BSG_IP_CORES_COMP = vlog -sv -mfcu $(ALL_FILES) -quiet
BSG_IP_CORES_SIM  = vsim -batch $(TEST_MODULE) -do "run -all; quit -f"
############################################################################




ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_NOC_FILES),$(TOP)/bsg_noc/$(x)) \
              $(foreach x,$(BSG_MEM_FILES),$(TOP)/bsg_mem/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
              $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(TEST_MAIN)

# function that generates a string for each combination of the parameters;
# spaces separated by "@" signs.
bsg_param_scan = $(if $(1),$(foreach v__,$($(firstword $(1))),\
                    $(call bsg_param_scan,$(filter-out $(firstword $(1)),\
                    $(1)),$(2),$(3),$(4)@$(2)$(firstword $(1))$(3)$(v__))),\
                    $(4))

# this takes the parameters and creates a set of make targets, one for every 
# combination of the parameters
commands = $(call bsg_param_scan,$(scan_params),+define+,=)

$(warning bsg_param_scan: $(commands))


# default rule: run all of the targets.
all: initial $(foreach x,$(commands),run.$(x))

# this runs an individual target
# we replace the @ with a space so that the parameters are used as 
# command line options

run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*)
	$(BSG_IP_CORES_SIM) >> outfile
  
initial:
	rm -f outfile

# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_mem_1rw_sync_mask_write_bit_from_1r1w

TOP = ../../../..

########################### SIMULATION PARAMETERS ##########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    =  bsg_mem_1rw_sync_mask_write_bit_from_1r1w.sv
BSG_TESTME_DIR      =  $(TOP)/bsg_mem/
BSG_MISC_FILES      =  bsg_defines.sv bsg_cycle_counter.sv bsg_dff.sv bsg_dff_en_bypass.sv bsg_dff_en.sv bsg_dff_reset_en.sv
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  = 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       =  bsg_mem_1r1w_sync.sv bsg_mem_1r1w_sync_synth.sv

BSG_TEST_FILES      =  bsg_nonsynth_reset_gen.sv \
                       bsg_nonsynth_clock_gen.sv \
                       bsg_nonsynth_ascii_writer.sv \
                       bsg_nonsynth_random_gen.sv

TEST_MAIN   = test_bsg.sv
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P ELS_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P = 8 21 8 33
ELS_P   = 40 41 8
############################################################################

############################# SIMULATOR COMMANDS ###########################
BSG_IP_CORES_COMP = vlog -sv -mfcu -work work \
                      +incdir+$(TOP)/bsg_test \
                      +incdir+$(TOP)/bsg_mem  \
                      +incdir+$(TOP)/bsg_misc $(ALL_FILES) -quiet

BSG_IP_CORES_SIM  = vsim -t ps -batch -lib work $(TEST_MODULE) -do "run -all; quit -f"
############################################################################




ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_legacy/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
              $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(foreach x,$(BSG_MEM_FILES),$(TOP)/bsg_mem/$(x)) \
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
.SILENT:
all: clean $(foreach x,$(commands),run.$(x))
	grep "Errors" transcript
	echo Number of writes issued:
	grep "| v | w" transcript | wc -l
	echo Number of writes performed:
	grep "w_en 1" transcript | wc -l
	echo Number of reads issued:
	grep "| v | r" transcript | wc -l
	echo Number of reads performed:
	grep "r_en 1" transcript | wc -l

# this runs an individual target
# we replace the @ with a space so that the parameters are used as 
# command line options

run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*)
	$(BSG_IP_CORES_SIM) >> transcript
  
clean:
	rm -rf transcript work

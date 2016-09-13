
export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export ICC_RELEASE=icc/K-2015.06-SP5-2
export VCS_RELEASE=vcs/K-2015.09-SP2-2
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin
export DC_RELEASE    = syn/G-2012.06-SP5-4

# Example parameter scan makefile
# 
# This makefile is a skeleton that simulates a module many times
# trying out variations of a product of different command line parameters.
#
# MBT 5/12/2015
#
# Edited to test bsg_counter_clock_downsample.v
# Scott Davidson (stdavids@eng.ucsd.edu) 8/21/2016

TOP = ../../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    = bsg_counter_clock_downsample.v
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_TEST_FILES      = bsg_nonsynth_clock_gen.v

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P    = 1 2 3 4 8
############################################################################


############################# SIMULATOR COMMANDS ###########################

VCS_FLAGS  = -PP -notice -full64 +lint=all,noVCDE +v2k -sverilog -timescale=100ps/10ps  +vcs+loopreport

############################################################################


ALL_FILES = $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
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
all: $(foreach x,$(commands),run.$(x))

# this runs an individual target
# we replace the @ with a space so that the parameters are used as 
# command line options

run.%: $(ALL_FILES)
	-rm -rf simv csrc simv.daidir
	$(VCS_BIN)/vcs $(VCS_FLAGS) $(filter-out small-clean,$^) $(subst @, ,$*) -o simv
	./simv $(subst @, ,$*) | tee $@.log

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &
%.echo:
	@echo $($*)

clean:
	- rm -rf simv csrc simv.daidir DVEfiles vcdplus.vpd ucli.key simv.log run.*.log


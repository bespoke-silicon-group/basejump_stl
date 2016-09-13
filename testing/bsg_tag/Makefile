
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

HARDEN = 0

TOP = ../..

########################### SIMULATION PARAMETERS ###########################
# place the parameters you want to scan here.
BSG_TESTME_FILES    = 
BSG_TESTME_DIR      = 
BSG_MISC_FILES      =  bsg_defines.v bsg_counter_clear_up.v
BSG_ASYNC_FILES     = bsg_launch_sync_sync.v
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_TAG_FILES       = bsg_tag_pkg.v bsg_tag_client.v bsg_tag_master.v
BSG_GUTS_FILES      =
BSG_TEST_FILES      = bsg_nonsynth_clock_gen.v

BSG_CLK_GEN_FILES   =
ifeq ($(HARDEN),0)
BSG_CLK_GEN_DIR     = $(TOP)/bsg_clk_gen
BSG_HARD_LIB        =
else
BSG_CLK_GEN_DIR     = $(TOP)/hard/bsg_clk_gen
BSG_HARD_LIB        = -v /gro/cad/mosis/pdk/tsmc/cl025g/std_cells/Rev_2004q2v1/aci/sc/verilog/tsmc25.v
endif

TEST_MAIN   = test_bsg.v
TEST_MODULE = test_bsg

# this is a list of all variables you want to vary for the simulation
scan_params = WIDTH_P

# this is a list of all values for each variable in the scan_params list
# note; if you leave out values for a variable, then the product of the
# sets is null, and nothing will run.
WIDTH_P    = 8
############################################################################


############################# SIMULATOR COMMANDS ###########################

VCS_FLAGS  = -PP -notice -full64 +lint=all,noVCDE,noNS +v2k -sverilog -timescale=100ps/10ps  +vcs+loopreport +notimingchecks
VCS_FLAGS += +incdir+$(TOP)/bsg_tag/

############################################################################


ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) \
            $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) \
              $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) \
              $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) \
              $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) \
              $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) \
              $(foreach x,$(BSG_TAG_FILES),$(TOP)/bsg_tag/$(x)) \
              $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) \
              $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) \
              $(SYNOPSYS_DIR)/$(ICC_RELEASE)/packages/gtech/src_ver/GTECH_NAND2.v \
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
	$(VCS_BIN)/vcs $(VCS_FLAGS) $(filter-out small-clean,$^) $(subst @, ,$*) -o simv $(BSG_HARD_LIB)
	./simv $(subst @, ,$*) | tee $@.log

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &
%.echo:
	@echo $($*)

clean:
	- rm -rf simv csrc simv.daidir DVEfiles vcdplus.vpd ucli.key simv.log run.*.log *.log



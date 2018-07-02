# MBT 8-26-2014

#
# Change these variables to determine what tests are run.
#

#CHANNEL_WIDTH           = 8

#RING_BYTES              = 10# 1

#NUM_CHANNELS            =   1 # 2 3 4 5 6 7 8 9 10 11 # 12 13 14 15
#CORE_0_PERIOD      =  2
#IO_MASTER_0_PERIOD =   6
#IO_MASTER_1_PERIOD =   2
#CORE_1_PERIOD      =   1

WIDTH_P = 1 2 3 4 5 8

export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export VCS_RELEASE=vcs/G-2012.09-SP1
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin
export DC_RELEASE    = syn/G-2012.06-SP5-4

TOP = ../../..

DESIGNWARE_DIR = $(SYNOPSYS_DIR)/$(DC_RELEASE)/dw/sim_ver
DESIGNWARE_FLAGS = -y $(DESIGNWARE_DIR) +incdir+$(DESIGNWARE_DIR) +incdir+$(TOP)/bsg_test +incdir+$(TOP)/bsg_misc +libext+.v



BSG_TESTME_FILES    = bsg_binary_plus_one_to_gray.v
BSG_TESTME_DIR      = $(TOP)/bsg_misc
BSG_MISC_FILES      =   bsg_cycle_counter.v bsg_defines.v bsg_scan.v
BSG_ASYNC_FILES     =
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =
BSG_FSB_FILES       =
BSG_GUTS_FILES      =

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.v bsg_nonsynth_clock_gen.v bsg_nonsynth_ascii_writer.v

#TEST_FILES = test_assembler.v
#TEST_MAIN = test_bsg_comm_link.v

TEST_MAIN=test_bsg.v

scan_params = WIDTH_P
ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) $(TEST_MAIN)

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

run.%: $(ALL_FILES)
	@echo $*
	- rm -rf simv csrc simv.daidir
	$(VCS_BIN)/vcs $(DESIGNWARE_FLAGS) -PP -notice -full64 +lint=all,noVCDE +v2k -sverilog -timescale=100ps/10ps $(filter-out small-clean,$^) $(subst @, ,$*) +vcs+loopreport +define+BSG_IP_CORES_UNIT_TEST
	./simv # | tee $@

log@%: small_clean

dve:
	$(DVE_BIN)/dve -full64 -vpd vcdplus.vpd &

%.echo:
	echo $($*)

clean:
	-rm log@*
	- rm -rf simv csrc simv.daidir DVEfiles vcdplus.vpd ucli.key

small-clean:
	- rm -rf simv csrc simv.daidir

bsg_scatter_gather.v: bsg_scatter_gather.py
	./$< > $@

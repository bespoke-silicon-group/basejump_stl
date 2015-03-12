# MBT 8-26-2014

#
# Change these variables to determine what tests are run.
#

CHANNEL_WIDTH           = 8

RING_BYTES              = 10# 1

NUM_CHANNELS            =   1 # 2 3 4 5 6 7 8 9 10 11 # 12 13 14 15
CORE_0_PERIOD      =  2
IO_MASTER_0_PERIOD =   6
IO_MASTER_1_PERIOD =   2
CORE_1_PERIOD      =   1



export LM_LICENSE_FILE = 27000@bbfs-00.calit2.net
export SYNOPSYS_DIR=/gro/cad/synopsys
export VCS_RELEASE=vcs/G-2012.09-SP1
export VCS_HOME = $(SYNOPSYS_DIR)/$(VCS_RELEASE)
export VCS_BIN = $(VCS_HOME)/bin
export DVE_BIN = $(VCS_HOME)/bin
export DC_RELEASE    = syn/G-2012.06-SP5-4

TOP = ../../..

MURN_INCLUDE_DIR = $(HOME)/raw/murn/code/include
DESIGNWARE_DIR = $(SYNOPSYS_DIR)/$(DC_RELEASE)/dw/sim_ver
DESIGNWARE_FLAGS = -y $(DESIGNWARE_DIR) +incdir+$(DESIGNWARE_DIR) +incdir+$(MURN_INCLUDE_DIR) +incdir+$(TOP)/bsg_test +incdir+$(TOP)/bsg_misc +libext+.v



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


ALL_FILES = $(MURN_INCLUDE_DIR)/rnet_common.v  $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) $(foreach x,$(BSG_TESTME_FILES),$(BSG_TESTME_DIR)/$(x)) $(TEST_MAIN)


all.log: $(ALL_FILES)
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

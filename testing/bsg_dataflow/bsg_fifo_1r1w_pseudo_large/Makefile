# MBT 8-26-2014

#
# Change these variables to determine what tests are run.
#

CHANNEL_WIDTH           = 8
RING_BYTES              = 10# 1
NUM_CHANNELS            =   1 # 2 3 4 5 6 7 8 9 10 11 # 12 13 14 15

ifeq (0,1)
CORE_0_PERIOD      =   2  6 20 200
IO_MASTER_0_PERIOD =    2 6 20 200
IO_MASTER_1_PERIOD =    2 6 20 200
CORE_1_PERIOD      =    2 6 20 200
else
CORE_0_PERIOD      =  2
IO_MASTER_0_PERIOD =   6
IO_MASTER_1_PERIOD =   2
CORE_1_PERIOD      =   1
endif


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



BSG_HYPOT_FILES     = 
BSG_MISC_FILES      =   bsg_defines.v bsg_circular_ptr.v bsg_cycle_counter.v bsg_encode_one_hot.v
BSG_ASYNC_FILES     = 
BSG_COMM_LINK_FILES =
BSG_DATAFLOW_FILES  =  bsg_fifo_1r1w_pseudo_large.v bsg_fifo_1rw_large.v bsg_two_fifo.v bsg_round_robin_n_to_1.v 
BSG_FSB_FILES       =
BSG_GUTS_FILES      =
BSG_MEM_FILES       = bsg_mem_1r1w.v bsg_mem_1rw_sync.v

BSG_TEST_FILES =  bsg_nonsynth_reset_gen.v bsg_nonsynth_clock_gen.v

TEST_MAIN=test_bsg_fifo_1r1w_pseudo_large.v


ALL_FILES = $(foreach x,$(BSG_MISC_FILES),$(TOP)/bsg_misc/$(x)) $(foreach x,$(BSG_ASYNC_FILES),$(TOP)/bsg_async/$(x)) $(foreach x,$(BSG_FSB_FILES),$(TOP)/bsg_fsb/$(x)) $(foreach x,$(BSG_GUTS_FILES),$(TOP)/bsg_guts/$(x)) $(foreach x,$(BSG_COMM_LINK_FILES),$(TOP)/bsg_comm_link/$(x)) $(foreach x,$(BSG_DATAFLOW_FILES),$(TOP)/bsg_dataflow/$(x)) $(foreach x,$(BSG_TEST_FILES),$(TOP)/bsg_test/$(x)) $(foreach x,$(BSG_MEM_FILES),$(TOP)/bsg_mem/$(x)) $(BSG_HYPOT_FILES) $(TEST_MAIN)


# example CHANNEL_WIDTH = 3 4 >===replicate_defines==> +define+CHANNEL_WIDTH=3 +define+CHANNEL_WIDTH=4
replicate_defines = $(foreach x,$($(1)),+define+$(1)=$(x))
bicross=$(foreach x,$(1),$(foreach y,$(2),$(x)@$(y)))
tricross=$(call bicross,$(1),$(call bicross,$(2),$(3)))

ALL_ALL=$(call tricross,$(call replicate_defines,CHANNEL_WIDTH),$(call replicate_defines,RING_BYTES),$(call replicate_defines,NUM_CHANNELS))
ALL_ALL_ALL=$(call tricross,$(ALL_ALL),$(call replicate_defines,CORE_0_PERIOD),$(call replicate_defines,IO_MASTER_0_PERIOD))
ALL_ALL_ALL2=$(call bicross,$(ALL_ALL_ALL),$(call replicate_defines,CORE_1_PERIOD))
ALL_ALL_ALL_ALL=$(call tricross,log,$(ALL_ALL_ALL2),$(call replicate_defines,IO_MASTER_1_PERIOD))

$(warning $(ALL_ALL_ALL))
$(warning Running $(ALL_ALL_ALL_ALL))

all: $(ALL_ALL_ALL_ALL)
	grep DONE log@*

# stupid, we do not have a license for -xprop
# we make small-clean a dependency, because
# synopsys has some dependency bugs of some kind.
log@%: $(ALL_FILES)
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

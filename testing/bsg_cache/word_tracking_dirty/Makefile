# Check stores/atomics to untracked words after a flush, and a load that must
# preserve dirty state. Scan word tracking and response backpressure.
TOP = ../../..
BSG_TESTME_DIR = $(TOP)/bsg_cache
BSG_TESTME_FILES = bsg_cache_pkg.sv bsg_cache.sv
BSG_MISC_FILES = bsg_defines.sv
BSG_TEST_FILES = bsg_nonsynth_clock_gen.sv
TEST_MAIN = ../common/bsg_nonsynth_dma_model.sv test_bsg.sv
TEST_MODULE = test_bsg

WORD_TRACKING_P = 0 1
RESPONSE_INTERVAL_P = 1 4
scan_params = WORD_TRACKING_P RESPONSE_INTERVAL_P

# Propagate simulator failures through Makefile.sim's tee pipeline.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

BSG_IP_CORES_SIM_INCLUDE_DIRS += +incdir+$(TOP)/bsg_cache
BSG_IP_CORES_COMP += -y $(TOP)/bsg_misc -y $(TOP)/bsg_dataflow \
                    -y $(TOP)/bsg_mem -y $(TOP)/bsg_cache +libext+.sv+.v

ifeq ($(SIMULATOR),verilator)
BSG_IP_CORES_COMP += --top-module $(TEST_MODULE) --assert $(VERILATOR_FLAGS)
else ifeq ($(SIMULATOR),vcs)
BSG_IP_CORES_COMP += -top $(TEST_MODULE) $(VCS_FLAGS)
endif

# VCS can return zero after $fatal. Require the test's success marker as well
# as propagating nonzero simulator exit status through the tee pipeline.
run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) | /usr/bin/tee outfile
	grep -Fq '[BSG_FINISH]' outfile

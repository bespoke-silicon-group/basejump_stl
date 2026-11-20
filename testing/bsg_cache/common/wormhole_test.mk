# Common Makefile of the bsg_cache tests that put bsg_cache_dma_to_wormhole and
# bsg_nonsynth_wormhole_test_mem behind the cache: a testbench.sv with module
# testbench. Include it from the test's Makefile, after setting scan_params and
# the values of each parameter in it. It compiles and runs the test for each
# combination of those values, passing them as +define+.
TOP = ../../..
BSG_TESTME_DIR = $(TOP)/bsg_cache
BSG_TESTME_FILES = bsg_cache_pkg.sv bsg_cache.sv bsg_cache_dma_to_wormhole.sv
BSG_MISC_FILES = bsg_defines.sv
BSG_NOC_FILES = bsg_noc_pkg.sv
TEST_MAIN = ../common/bsg_nonsynth_wormhole_test_mem.sv testbench.sv
TEST_MODULE = testbench

# Propagate simulator failures through Makefile.sim's tee pipeline.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

BSG_IP_CORES_SIM_INCLUDE_DIRS += +incdir+$(TOP)/bsg_cache +incdir+$(TOP)/bsg_noc
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

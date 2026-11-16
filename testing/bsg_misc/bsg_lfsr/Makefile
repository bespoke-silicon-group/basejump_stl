# Check all automatic masks and the explicit-mask path in one simulation.
.DEFAULT_GOAL := check
TOP = ../../..
BSG_TESTME_DIR = $(TOP)/bsg_misc
BSG_TESTME_FILES = bsg_lfsr.sv
BSG_MISC_FILES = bsg_defines.sv
BSG_TEST_FILES = bsg_nonsynth_clock_gen.sv
TEST_MODULE = test_bsg
TEST_MAIN = $(TEST_MODULE).sv

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

ifeq ($(SIMULATOR),verilator)
BSG_IP_CORES_COMP += --top-module $(TEST_MODULE) --assert $(VERILATOR_FLAGS)
else ifeq ($(SIMULATOR),vcs)
BSG_IP_CORES_COMP += -top $(TEST_MODULE) $(VCS_FLAGS)
endif

.PHONY: check
check:
	$(BSG_IP_CORES_COMP) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) | /usr/bin/tee outfile
	grep -Fq '[BSG_FINISH] bsg_lfsr' outfile

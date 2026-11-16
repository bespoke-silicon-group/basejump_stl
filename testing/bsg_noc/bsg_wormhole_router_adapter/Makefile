# Round-trip packets with unequal payload/flit widths and backpressure, then
# require the input adapter's diagnostic for an out-of-range encoded length.
.DEFAULT_GOAL := check
TOP = ../../..
BSG_TESTME_DIR = $(TOP)/bsg_noc
BSG_TESTME_FILES = bsg_wormhole_router_adapter_in.sv bsg_wormhole_router_adapter_out.sv
BSG_MISC_FILES = bsg_defines.sv
BSG_TEST_FILES = bsg_nonsynth_clock_gen.sv
TEST_MODULE = test_bsg
TEST_MAIN = $(TEST_MODULE).sv

STALL_INTERVAL_P = 1 4
scan_params = STALL_INTERVAL_P

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

BSG_IP_CORES_SIM_INCLUDE_DIRS += +incdir+$(TOP)/bsg_noc
BSG_IP_CORES_COMP += -y $(TOP)/bsg_misc -y $(TOP)/bsg_dataflow \
                    -y $(TOP)/bsg_mem +libext+.sv+.v

ifeq ($(SIMULATOR),verilator)
BSG_IP_CORES_COMP += --top-module $(TEST_MODULE) --assert $(VERILATOR_FLAGS)
else ifeq ($(SIMULATOR),vcs)
BSG_IP_CORES_COMP += -top $(TEST_MODULE) $(VCS_FLAGS)
endif

.PHONY: check invalid-length
check: all
	$(MAKE) invalid-length

# Also require a success marker: VCS can return zero after $fatal.
run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) | /usr/bin/tee outfile
	grep -Fq '[BSG_FINISH]' outfile

# Verilator terminates on the assertion; VCS may report it and continue.
# Match the adapter's diagnostic, not a generic simulator failure or the
# downstream counter's overflow diagnostic.
invalid-length: TEST_MODULE = test_invalid_len
invalid-length:
	$(BSG_IP_CORES_COMP) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) > outfile 2>&1 || true
	cat outfile
	grep -Fq 'Packet received with len: 3 >= max_num_flits: 00000003' outfile

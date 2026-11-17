# Channel tunnel with explicit credit decimation: traffic at small credit
# counts, the documented sizing rule, and rejection of invalid parameters
# during elaboration.

.DEFAULT_GOAL := check
.NOTPARALLEL:

TOP = ../../..

BSG_TESTME_DIR = $(TOP)/bsg_dataflow
BSG_TESTME_FILES = bsg_channel_tunnel.sv
BSG_MISC_FILES = bsg_defines.sv
BSG_TEST_FILES = bsg_nonsynth_clock_gen.sv

TEST_MODULE = test_bsg
TEST_MAIN = $(TEST_MODULE).sv

STALL_INTERVAL_P = 1 4
scan_params = STALL_INTERVAL_P

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

BSG_IP_CORES_COMP += -y $(TOP)/bsg_misc -y $(TOP)/bsg_dataflow \
                    -y $(TOP)/bsg_mem +libext+.sv+.v

# -Werror-USERERROR: with Makefile.sim's --Wno-fatal, Verilator otherwise
# reports a failed BSG_ELAB_CHECK as a warning and carries on.
ifeq ($(SIMULATOR),verilator)
BSG_IP_CORES_COMP += --top-module $(TEST_MODULE) --assert -Werror-USERERROR $(VERILATOR_FLAGS)
else ifeq ($(SIMULATOR),vcs)
BSG_IP_CORES_COMP += -top $(TEST_MODULE) $(VCS_FLAGS)
endif

.PHONY: check bad-decimation bad-width

check: all
	$(MAKE) bad-decimation
	$(MAKE) bad-width

# Also require a success marker: VCS can return zero after $fatal.
run.%:
	$(BSG_IP_CORES_COMP) $(subst @, ,$*) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES)
	$(BSG_IP_CORES_ELAB) $(TEST_MODULE)
	$(BSG_IP_CORES_SIM) | /usr/bin/tee outfile
	grep -Fq '[BSG_FINISH]' outfile

# Negative tests require both a failed build and the tunnel's own diagnostic.
# Do not run the simulator: a run-time assertion cannot satisfy this check.
bad-decimation: TEST_MODULE = test_bad_decimation
bad-decimation: diagnostic = bad params; remote_credits_p=8 cannot support lg_credit_decimation_p=4

bad-width: TEST_MODULE = test_bad_width
bad-width: diagnostic = bad params; channel width (4) must be at least wide enough to route back credits (8)

bad-decimation bad-width:
	@status=0; { $(BSG_IP_CORES_COMP) $(BSG_IP_CORES_SIM_INCLUDE_DIRS) $(ALL_FILES) \
	  && { $(BSG_IP_CORES_ELAB) $(TEST_MODULE); }; } > outfile 2>&1 || status=$$?; \
	  cat outfile; \
	  if [ $$status -eq 0 ]; then echo '[BSG_ERROR] invalid parameters elaborated'; exit 1; fi; \
	  grep -Fq '$(diagnostic)' outfile; \
	  status=$$?; if [ $$status -ne 0 ]; then exit $$status; fi; \
	  echo '[BSG_PASS] $@ rejected during elaboration'

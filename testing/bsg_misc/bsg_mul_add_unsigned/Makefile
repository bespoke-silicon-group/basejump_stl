# Michael Bedford Taylor & OpenAI Codex (AI-generated).
# Generic: make SIMULATOR=verilator
# FPGA: make SIMULATOR=verilator PIPELINE_P="3 5" \
#         BSG_TESTME_DIR=../../../hard/ultrascale_plus/bsg_misc
TOP = ../../..
BSG_TESTME_DIR ?= $(TOP)/bsg_misc
BSG_TESTME_FILES = bsg_mul_add_unsigned.sv
BSG_MISC_FILES = bsg_defines.sv bsg_dff.sv bsg_dff_chain.sv
BSG_TEST_FILES = bsg_nonsynth_clock_gen.sv
TEST_MAIN = test_bsg.sv
TEST_MODULE = test_bsg

PIPELINE_P = 0 1 2 3 5
scan_params = PIPELINE_P

# Propagate simulator failures through Makefile.sim's tee pipeline.
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

include ../../Makefile.sim

ifeq ($(SIMULATOR),verilator)
BSG_IP_CORES_COMP += --top-module $(TEST_MODULE) --assert
endif

# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

# Cadenv Include
include /home/projects/ee478.2024spr/cadenv/cadenv_ee.mk

# CAD Tool Paths
VCS_BIN = $(VCS_HOME)/bin
VERDI_BIN = $(VERDI_HOME)/bin
VCS_BIN_DIR = $(VCS_BIN)
export PATH:=$(PATH):$(VCS_BIN):$(VERDI_BIN)

# VCS Arguments
EXTRA_ARGS += +v2k -l vcs.log
EXTRA_ARGS += -debug_pp +vcs+vcdpluson
EXTRA_ARGS += +lint=all,noSVA-UA,noSVA-NSVU,noVCDE,noNS -assert svaext
EXTRA_ARGS += -cm line+fsm+branch+cond+tgl
EXTRA_ARGS += -kdb -debug_access+all

# defaults
SIM ?= vcs
TOPLEVEL_LANG ?= verilog

# basejump_stl path
export BASEJUMP_STL_DIR = $(shell git rev-parse --show-toplevel)/../basejump_stl

# basejump_stl verilog header include path
EXTRA_ARGS += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc

# basejump_stl verilog filelist
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_hardened.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_sync.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_sync_synth.sv
VERILOG_SOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_imul_iterative.sv

# testbench verilog filelist
VERILOG_SOURCES += $(PWD)/bsg_imul_iterative_wrapper.sv
VERILOG_SOURCES += $(PWD)/bsg_imul_iterative_cov.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = bsg_imul_iterative_wrapper

# MODULE is the basename of the Python test file
MODULE = bsg_imul_iterative_testbench

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim


# VERDI open waveform
ee-verdi:
	verdi -ssf novas.fsdb &

# VERDI open coverages
ee-verdi-cov:
	verdi -cov -covdir sim_build/simv.vdb &

# **DEPRECATED** DVE open waveform
ee-dve:
	dve -full64 -vpd vcdplus.vpd &

# **DEPRECATED** DVE open coverages
ee-dve-cov:
	dve -full64 -cov -covdir sim_build/simv.vdb &

# Clean simulation files
ee-clean:
	make clean
	rm -rf __pycache__ DVEfiles vcs.log vcdplus.vpd results.xml
	rm -rf verdiLog vdCovLog novas.conf novas.fsdb novas.rc novas_dump.log

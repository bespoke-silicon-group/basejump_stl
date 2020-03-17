export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BSG_CADENV_DIR)/cadenv.mk

TESTS := default

.PHONY: all clean $(TESTS)

all: $(TESTS)

VSOURCES := testbench.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1rw_sync_mask_write_byte_dma.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1rw_sync_assoc.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1rw_sync_mask_write_byte_assoc.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_fsb/bsg_fsb_node_trace_replay.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.v

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test

CXXFLAGS = -std=c++11 -D_GNU_SOURCE -Wall -fPIC -shared
CXXFLAGS += -DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)
CXXSOURCES := $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp

libdmamem.so: $(CXXSOURCES)
	$(CXX) $(CXXFLAGS) $(CXXSOURCES) -o $@

simv: $(VSOURCES)
	vcs +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		+define+trace_file=$@.trace \
		+define+rom_file=$@.tr \
		$(INCDIR) \
		-sverilog -full64 -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log \
		$(VSOURCES)

test.tr: tracegen.py
	python3 $< > $@

default: simv libdmamem.so test.tr
	./$< -l $@.log -sv_root $(CURDIR) -sv_lib libdmamem

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f simv vcs.log vcdplus.vpd vc_hdrs.h ucli.key
	rm -rf csrc simv.daidir DVEfiles
	rm -rf stack.info.*
	rm -f *.tr
	rm -f *.trace
	rm -f *~
	rm -f *.so
	rm -f *.simv

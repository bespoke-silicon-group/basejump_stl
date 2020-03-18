export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BSG_CADENV_DIR)/cadenv.mk

# for building tests
test_basename_from_data_addr_width = test_$(strip $(1))_$(strip $(2))
data_width_from_test_basename      = $(word 2,$(subst _, ,$(1)))
addr_width_from_test_basename      = $(word 3,$(subst _, ,$(1)))

# add some new tests here
TESTS := $(call test_basename_from_data_addr_width, 8,   10)
TESTS := $(call test_basename_from_data_addr_width, 16,  10)
TESTS += $(call test_basename_from_data_addr_width, 512, 10)
TESTS += $(call test_basename_from_data_addr_width, 512, 20)
TESTS += $(call test_basename_from_data_addr_width, 256, 20)
TESTS += $(call test_basename_from_data_addr_width, 256, 16)

ROMS  := $(foreach test, $(TESTS), $(test).tr)

.PHONY: all clean $(TESTS) debug

all: $(TESTS)

VSOURCES := testbench.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1rw_sync_mask_write_byte_dma.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_fsb/bsg_fsb_node_trace_replay.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.v

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test

CXXFLAGS = -std=c++11 -D_GNU_SOURCE -Wall -fPIC -shared
CXXFLAGS += -DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)
CXXSOURCES := $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp
CXXSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.hpp

libdmamem.so: $(CXXSOURCES)
	$(CXX) $(CXXFLAGS) $(filter %.cpp, $^) -o $@

$(TESTS): %: %.tr
$(TESTS): libdmamem.so $(VSOURCES)
	vcs +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		+define+DATA_WIDTH=$(call data_width_from_test_basename,$@) \
		+define+ADDR_WIDTH=$(call addr_width_from_test_basename,$@) \
		+define+ROM_FILE=$(filter %.tr, $^) \
		$(INCDIR) \
		-sverilog -full64 -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log \
		$(filter %.v, $^)
	./simv -l simv.log -sv_root $(CURDIR) -sv_lib libdmamem \
	2>&1 | tee simv.full.log

$(ROMS): %.tr: tracegen.py
	python3 $< \
	$(call data_width_from_test_basename,$(basename $@)) \
	$(call addr_width_from_test_basename,$(basename $@)) \
	> $@

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
	rm -f *.log

debug:
	@echo $(call test_basename_from_data_addr_width, 8, 10) # test_8_10
	@echo $(basename $(call test_basename_from_data_addr_width, 8, 10).tr) # test_8_10
	@echo $(call data_width_from_test_basename, $(call test_basename_from_data_addr_width, 8, 10)) # 8
	@echo $(call addr_width_from_test_basename, $(call test_basename_from_data_addr_width, 8, 10)) # 10

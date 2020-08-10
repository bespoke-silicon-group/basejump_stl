export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
export BASEJUMP_STL_DIR = $(abspath ../../..)
include $(BSG_CADENV_DIR)/cadenv.mk

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test

CFLAGS += -CFLAGS "-std=c++11 -g -Wall"
CFLAGS += -CFLAGS "-fPIC"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/src"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/headers"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/fmt/include"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/bsg_test"
CFLAGS += -CFLAGS "-I$(BASEJUMP_STL_DIR)/bsg_mem"
CFLAGS += -CFLAGS "-DFMT_HEADER_ONLY=1"
CFLAGS += -CFLAGS "-DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)"

DRAMS := hbm2_8gb_x128 hbm2_4gb_x128

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_reduce.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_fsb/bsg_fsb_node_trace_replay.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3_pkg.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_map.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_unmap.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v
VSOURCES += testbench.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3.cpp
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp

VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/bankstate.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/channel_state.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/command_queue.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/common.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/configuration.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/controller.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/dram_system.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/hmc.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/memory_system.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/refresh.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/simple_stats.cc
VSOURCES += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/timing.cc

all: $(DRAMS)

$(DRAMS): %: %.tr
$(DRAMS): $(VSOURCES)
	vcs -R +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp g++ $(CFLAGS) \
		$(INCDIR) \
		+define+dram_pkg=bsg_dramsim3_$@_pkg \
		+define+trace_file=$@.trace \
		+define+rom_file=$@.tr \
		-sverilog -full64  -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log $(VSOURCES)

$(foreach dram, $(DRAMS), $(dram).tr): hbm_trace_gen.py
	python hbm_trace_gen.py $(@:.tr=) > $@

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -f simv vcs.log vcdplus.vpd vc_hdrs.h ucli.key
	rm -rf csrc simv.daidir DVEfiles
	rm -rf stack.info.*
	rm -f *.tr
	rm -f *.trace
	rm -f *~

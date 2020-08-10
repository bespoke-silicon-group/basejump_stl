export BASEJUMP_STL_DIR = $(abspath ../../..)
export BSG_CADENV_DIR = $(abspath ../../../../bsg_cadenv)
include $(BSG_CADENV_DIR)/cadenv.mk

INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_misc
INCDIR += +incdir+$(BASEJUMP_STL_DIR)/bsg_test


VCS_FLAGS = -full64 +lint=all,noSVA-UA,noSVA-NSVU,noVCDE +v2k -cpp g++
VCS_FLAGS += -sverilog -full64 -timescale=1ps/1ps +vcs+vcdpluson

SIMV = $(abspath simv)

BENCHMARKS = random_full constrained_random unit unit_load unit_load_conflict

all: run_all

run_all: $(addsuffix .run, $(BENCHMARKS))



CXXFLAGS = -std=c++11 -D_GNU_SOURCE -Wall -fPIC -shared
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/src
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/headers
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/fmt/include
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/bsg_mem
CXXFLAGS += -DFMT_HEADER_ONLY=1
CXXFLAGS += -DCMD_TRACE
CXXFLAGS += -DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)
DRAMSIM3_SRC =  $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/bankstate.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/channel_state.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/command_queue.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/common.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/configuration.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/controller.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/dram_system.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/hmc.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/memory_system.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/refresh.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/simple_stats.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/imports/DRAMSim3/src/timing.cc
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3.cpp
DRAMSIM3_SRC += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_dma.cpp


VSOURCES := $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_trace_replay.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3_pkg.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_map.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_unmap.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v
VSOURCES += testbench.v

libdramsim3.so: $(DRAMSIM3_SRC)
	$(CXX) $(CXXFLAGS) -o libdramsim3.so $(DRAMSIM3_SRC)

simv: $(VSOURCES)
	vcs $(VCS_FLAGS) -l vcs.log $(INCDIR) $(VSOURCES)

out/%/trace.tr: %.py
	mkdir -p out
	mkdir -p out/$*
	python $*.py > $@

%.run: simv libdramsim3.so out/%/trace.tr
	(cd out/$*; $(SIMV) -l simv.log -sv_root $(CURDIR) -sv_lib libdramsim3)

%.dve:
	dve -full64 -vpd out/$*/vcdplus.vpd &

summary:
	@$(foreach benchmark, $(BENCHMARKS), grep -H --color -e "BSG_FINISH" -e "BSG_FATAL" \
		-e "Error" -e "BSG_ERROR" out/$(benchmark)/simv.log;)

clean:
	rm -rf csrc simv.daidir simv ucli.key vcdplus.vpd vc_hdrs.h DVEfiles
	rm -f vcs.log bsg_nonsynth_dramsim3_trace.txt dramsim3epoch.json
	rm -f trace.tr *.trace *.pyc
	rm -rf out
	rm -f libdramsim3.so

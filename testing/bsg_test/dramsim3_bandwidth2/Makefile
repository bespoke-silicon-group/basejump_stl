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
CFLAGS += -CFLAGS "-DFMT_HEADER_ONLY=1"
CFLAGS += -CFLAGS "-DCMD_TRACE"
CFLAGS += -CFLAGS "-DBASEJUMP_STL_DIR=$(BASEJUMP_STL_DIR)"

# test parameter
NUM_CACHE_P ?= 1
BLOCK_SIZE_IN_WORDS_P ?= 8
DMA_DATA_WIDTH_P ?= 32
TRACE_GEN ?= stream_read

#NUMS = $(shell seq 0 `expr $(NUM_CACHE_P) - 1`)
#TRACE_ROMS = $(addsuffix .tr, $(addprefix trace_, $(NUMS)))
VCS_DEFINE =  +define+NUM_CACHE_P=$(NUM_CACHE_P)
VCS_DEFINE += +define+BLOCK_SIZE_IN_WORDS_P=$(BLOCK_SIZE_IN_WORDS_P)
VCS_DEFINE += +define+DMA_DATA_WIDTH_P=$(DMA_DATA_WIDTH_P)
VCS_DEFINE += +define+TRACE=$(TRACE_GEN).tr


CXXFLAGS = -std=c++11 -D_GNU_SOURCE -Wall -fPIC -shared
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/src
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/headers
CXXFLAGS += -I$(BASEJUMP_STL_DIR)/imports/DRAMSim3/ext/fmt/include
CXXFLAGS += -DFMT_HEADER_ONLY=1
CXXFLAGS += -DCMD_TRACE
#CXXFLAGS += -DDEBUG
#CXXFLAGS += -DSTALL_TRACE
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
run: libdramsim3.so $(TRACE_GEN).tr simv
	./simv -l simv.log -sv_root $(CURDIR) -sv_lib libdramsim3

libdramsim3.so:
	$(CXX) $(CXXFLAGS) -o libdramsim3.so $(DRAMSIM3_SRC)

$(TRACE_GEN).tr: $(TRACE_GEN).py
	python $(TRACE_GEN).py $(NUM_CACHE_P) $(BLOCK_SIZE_IN_WORDS_P) > $@

simv:
	vcs +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp g++ $(CFLAGS) $(INCDIR) $(VCS_DEFINE) \
		-sverilog -full64 -f sv.include -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf out/
	rm -rf csrc simv.daidir simv ucli.key vcdplus.vpd vc_hdrs.h DVEfiles simv.log *.pyc
	rm -f vcs.log bsg_nonsynth_dramsim3_trace.txt dramsim3epoch.json
	rm -f *.tr *.trace miss_latency.txt

latency:
	python3 miss_latency.py

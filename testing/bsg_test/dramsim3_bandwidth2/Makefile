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

libdramsim3.so: $(DRAMSIM3_SRC)
	$(CXX) $(CXXFLAGS) -o libdramsim3.so $(DRAMSIM3_SRC)

$(TRACE_GEN).tr: $(TRACE_GEN).py
	python $(TRACE_GEN).py $(NUM_CACHE_P) $(BLOCK_SIZE_IN_WORDS_P) > $@

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_clear_up.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en_bypass.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_priority_encode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_priority_encode_one_hot_out.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_encode_one_hot.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode_with_v.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_one_hot.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_scan.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_expand_bitmask.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_segmented.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_lru_pseudo_tree_decode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_lru_pseudo_tree_encode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_round_robin_arb.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_crossbar_o_by_i.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_trace_replay.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3_pkg.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_map.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_unmap.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_two_fifo.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_one_fifo.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_n_to_1.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_1_to_n.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_parallel_in_serial_out.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_serial_in_parallel_out_full.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_async_fifo.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_async_ptr_gray.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_launch_sync_sync.v

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_synth.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_synth.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_byte_synth.v


VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_pkg.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_miss.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_dma.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_sbuf.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_sbuf_queue.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_decode.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_rx.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_rx_reorder.v
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_tx.v

VSOURCES += $(BASEJUMP_STL_DIR)/testing/bsg_cache/regression_v2/basic_checker.v
VSOURCES += cache_miss_counter.v
VSOURCES += vcache_blocking.v
VSOURCES += testbench.v

simv: $(VSOURCES) $(TRACE_GEN).tr
	vcs +v2k +lint=all,noSVA-UA,noSVA-NSVU,noVCDE \
		-cpp g++ $(CFLAGS) $(INCDIR) $(VCS_DEFINE) \
		-sverilog -full64 -timescale=1ps/1ps +vcs+vcdpluson -l vcs.log $(VSOURCES)

dve:
	dve -full64 -vpd vcdplus.vpd &

clean:
	rm -rf out/
	rm -rf csrc simv.daidir simv ucli.key vcdplus.vpd vc_hdrs.h DVEfiles simv.log *.pyc
	rm -f vcs.log bsg_nonsynth_dramsim3_trace.txt dramsim3epoch.json
	rm -f *.tr *.trace miss_latency.txt
	rm -f libdramsim3.so

latency:
	python3 miss_latency.py

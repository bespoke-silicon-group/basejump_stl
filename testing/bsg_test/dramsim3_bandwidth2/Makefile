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

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_defines.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_counter_clear_up.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_circular_ptr.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en_bypass.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_en.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_dff_reset.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_priority_encode.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_priority_encode_one_hot_out.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_encode_one_hot.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_decode_with_v.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_one_hot.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_scan.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_expand_bitmask.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_mux_segmented.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_lru_pseudo_tree_decode.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_lru_pseudo_tree_encode.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_round_robin_arb.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_misc/bsg_crossbar_o_by_i.sv

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_clock_gen.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_reset_gen.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_test_rom.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_trace_replay.sv

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_dramsim3_pkg.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_map.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_test/bsg_nonsynth_dramsim3_unmap.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_nonsynth_mem_1r1w_sync_mask_write_byte_dma.sv

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_1r1w_small_unhardened.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_fifo_tracker.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_two_fifo.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_one_fifo.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_n_to_1.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_round_robin_1_to_n.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_parallel_in_serial_out.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_dataflow/bsg_serial_in_parallel_out_full.sv

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_async_fifo.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_async_ptr_gray.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_async/bsg_launch_sync_sync.sv

VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1r1w_synth.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_synth.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_bit.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_bit_synth.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_byte.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_mem/bsg_mem_1rw_sync_mask_write_byte_synth.sv


VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_pkg.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_miss.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_dma.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_sbuf.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_buffer_queue.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_decode.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_rx.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_rx_reorder.sv
VSOURCES += $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_to_test_dram_tx.sv

VSOURCES += $(BASEJUMP_STL_DIR)/testing/bsg_cache/regression_v2/basic_checker.sv
VSOURCES += cache_miss_counter.sv
VSOURCES += vcache_blocking.sv
VSOURCES += testbench.sv

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

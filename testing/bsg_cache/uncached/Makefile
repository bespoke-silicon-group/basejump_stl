BASEJUMP_STL_DIR ?= $(abspath ../../..)
VERILATOR ?= verilator
DMA_RATIO_P ?= 1
WORD_TRACKING_P ?= 1
STALL_P ?= 0
BUFFER_RETURN_P ?= 1
ZERO_LATENCY_P ?= 0
SETS_P ?= 128
WAYS_P ?= 8
BLOCK_SIZE_IN_WORDS_P ?= 8
ADDR_WIDTH_P ?= 16
BUILD_DIR ?= $(CURDIR)/obj_dir

.PHONY: test
test:
	mkdir -p $(BUILD_DIR)
	$(VERILATOR) --binary --timing --assert --top-module testbench -j 4 \
	  -Wno-fatal -Wno-PINMISSING -Wno-TIMESCALEMOD --Mdir $(BUILD_DIR) \
	  -Gdma_ratio_p=$(DMA_RATIO_P) -Gword_tracking_p=$(WORD_TRACKING_P) \
	  -Gstall_p=$(STALL_P) -Gbuffer_return_p=$(BUFFER_RETURN_P) \
	  -Gzero_latency_p=$(ZERO_LATENCY_P) \
	  -Gsets_p=$(SETS_P) -Gways_p=$(WAYS_P) -Gblock_size_in_words_p=$(BLOCK_SIZE_IN_WORDS_P) \
	  -Gaddr_width_p=$(ADDR_WIDTH_P) \
	  -I$(BASEJUMP_STL_DIR)/bsg_misc -I$(BASEJUMP_STL_DIR)/bsg_cache -I$(BASEJUMP_STL_DIR)/bsg_noc \
	  -y $(BASEJUMP_STL_DIR)/bsg_misc -y $(BASEJUMP_STL_DIR)/bsg_mem \
	  -y $(BASEJUMP_STL_DIR)/bsg_dataflow -y $(BASEJUMP_STL_DIR)/bsg_cache \
	  $(BASEJUMP_STL_DIR)/bsg_noc/bsg_noc_pkg.sv $(BASEJUMP_STL_DIR)/bsg_cache/bsg_cache_pkg.sv \
	  ../common/bsg_nonsynth_wormhole_test_mem.sv testbench.sv
	$(BUILD_DIR)/Vtestbench

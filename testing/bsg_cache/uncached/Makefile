# Uncached word requests through bsg_cache_dma_to_wormhole to an IO endpoint.
# Each parameter takes a list of values, and the test runs for every
# combination. This default scan is 16 runs; the full one of README.md is
#   make DMA_RATIO_P="1 2 4 8" WORD_TRACKING_P="0 1"
DMA_RATIO_P ?= 1 4
WORD_TRACKING_P ?= 1
STALL_P ?= 0 1
BUFFER_RETURN_P ?= 0 1
ZERO_LATENCY_P ?= 0 1
# cache geometry: one value each
SETS_P ?= 128
WAYS_P ?= 8
BLOCK_SIZE_IN_WORDS_P ?= 8
ADDR_WIDTH_P ?= 16
scan_params = DMA_RATIO_P WORD_TRACKING_P STALL_P BUFFER_RETURN_P ZERO_LATENCY_P
scan_params += SETS_P WAYS_P BLOCK_SIZE_IN_WORDS_P ADDR_WIDTH_P
include ../common/wormhole_test.mk

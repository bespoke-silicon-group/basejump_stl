# Random cached and uncached requests through bsg_cache_dma_to_wormhole,
# checked against a reference model. See README.md.
# Each parameter takes a list of values, and the test runs for every
# combination: eight runs by default.
WORD_TRACKING_P ?= 0 1
DMA_RATIO_P ?= 1 4
BUFFER_RETURN_P ?= 0 1
ZERO_LATENCY_P ?= 1
# cache geometry, seed and requests per phase: one value each by default
SETS_P ?= 4
WAYS_P ?= 2
BLOCK_SIZE_IN_WORDS_P ?= 8
SEED_P ?= 1
OPS_P ?= 20000
scan_params = WORD_TRACKING_P DMA_RATIO_P BUFFER_RETURN_P ZERO_LATENCY_P
scan_params += SETS_P WAYS_P BLOCK_SIZE_IN_WORDS_P SEED_P OPS_P
include ../common/wormhole_test.mk

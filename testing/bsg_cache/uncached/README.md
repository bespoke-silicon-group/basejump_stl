# Uncached word access

Run `make test` with Verilator. The test connects the vcache to a dedicated
IO endpoint through `bsg_cache_dma_to_wormhole` and checks read/write data,
packet length, IO routing, unchanged cache tags, and cached/uncached accesses
to the same address.

Parameters: `DMA_RATIO_P=1/2/4/8`, `WORD_TRACKING_P=0/1`, `STALL_P=0/1`,
`BUFFER_RETURN_P=0/1`, and `ZERO_LATENCY_P=0/1`. The last option returns the IO
response header in the same cycle that its request address is accepted.
`SETS_P`, `WAYS_P`, `ADDR_WIDTH_P`, and `BLOCK_SIZE_IN_WORDS_P` select cache geometry; the DMA
ratio must divide the block size. `BUILD_DIR` selects the build directory.
For example:

```
make test DMA_RATIO_P=2 WORD_TRACKING_P=0 STALL_P=1 BUFFER_RETURN_P=0 ZERO_LATENCY_P=1
```

Uncached operations use 32-bit cache words. A wider DMA beat carries the IO
word in its low 32 bits. `dest_io_wh_cord_i` selects the IO endpoint; normal
cached traffic continues to use `dest_wh_cord_i`.

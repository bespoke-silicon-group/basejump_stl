# Random cached and uncached requests

`../uncached` sends uncached requests while the cache has nothing else to do:
all its cached requests hit, and the IO endpoint is the only one behind the
cache. This test covers the rest. Uncached requests run between and around
fills, evictions and flushes, and a reference model predicts every response.

## Setup

`bsg_cache` sits on `bsg_cache_dma_to_wormhole`. The testbench routes each
packet by the coordinate in its header: to a block memory at `dest_wh_cord_i`
or to an IO memory at `dest_io_wh_cord_i`, both `bsg_nonsynth_wormhole_test_mem`.
Both directions of the link and the cache output stall at random.

Cached requests use four times as many words as the cache holds, so lines are
evicted all the time. They are loads and stores of every size, masked loads
and stores, AMOSWAP and AMOOR, AFL, AFLINV and TAGFL. With more than one set,
the last set is kept out of their address range and used for TAGST: no line
of it is ever valid, so a TAGST with an invalid tag can come at any point.

## Checks

- Every response is compared with the reference model: a byte array for
  cached requests and a word array for uncached ones.
- At the end every word is read back. Cached words are read after their line
  has been flushed and invalidated, so they come from the block memory.
- Every packet on the request link is checked: destination, the `uncached_op`
  flag, opcode and length; and for uncached packets the order, the address
  and the data, against the requests issued.
- No request, response or flit moving for 200000 cycles is a failure.

## Phases

One run is five phases of `OPS_P` requests each:

| Phase | Uncached | Flushes | TAGST | Stalls (request link, response link, output) |
| --- | --- | --- | --- | --- |
| 0 | 30% | 5% | none | none |
| 1 | 30% | 5% | 8% | 30%, 30%, 30% |
| 2 | 60% | 5% | none | 60%, 10%, 50%, requests back to back |
| 3 | 10% | 15% | 8% | 20%, 50%, 20% |
| 4 | 30% | 5% | none | output 80%, requests back to back |

## Running

Run `make` for VCS or `make SIMULATOR=verilator`. Each parameter is a Makefile
variable that holds a list of values, and the test runs once for every
combination: eight runs by default.

| Parameter | Default | Meaning |
| --- | --- | --- |
| `WORD_TRACKING_P` | `0 1` | word tracking in the cache |
| `DMA_RATIO_P` | `1 4` | DMA data width in words; must divide the block size |
| `BUFFER_RETURN_P` | `0 1` | `buffer_return_p` of the adapter |
| `ZERO_LATENCY_P` | `1` | the IO memory answers a read in the cycle of its address flit |
| `SETS_P`, `WAYS_P`, `BLOCK_SIZE_IN_WORDS_P` | `4`, `2`, `8` | cache geometry |
| `SEED_P` | `1` | seed of the requests and of the stalls |
| `OPS_P` | `20000` | requests per phase |

For example, more seeds on another geometry:

```
make SIMULATOR=verilator SEED_P="1 2 3 4" SETS_P=2 WAYS_P=4 BLOCK_SIZE_IN_WORDS_P=4
```

A failure prints `[BSG_ERROR]` with the request, the expected and the actual
response, the cycle and the seed. `+seed=` and `+ops=` on the simulator command
line override `SEED_P` and `OPS_P` without recompiling.

## What it has caught

Each of these changes to the RTL makes the default scan fail:

- letting the store buffer drain while an uncached request is in tv and tl
  holds a load (all eight runs);
- the same for the track buffer (the four runs with word tracking);
- taking an uncached load's word from the block offset of its address instead
  of the low word of the DMA beat (the four runs with `DMA_RATIO_P=4`).

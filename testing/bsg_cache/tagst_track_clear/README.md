This regression checks that `TAGST` clears the track bits of the way it
writes, so a line set up with `TAGST` starts with no word present, as after a
store-miss allocation. It needs word tracking.

Each case first puts known data in memory, then leaves a way holding a fully
tracked line, and reuses that way with `TAGST`:

- A1: a load from the new line must fill from memory.
- A2: a full-word store to the new line, then `AFLINV`, must write back only
  that word; memory keeps the line's other words.
- A3: a byte store to the new line must merge with the word from memory, and
  `AFLINV` must keep the line's other words.

A load that misses returns its word straight from the refill, so A1 reads the
word a second time to check the copy the cache kept.

No store is issued just before a `TAGST`. `TAGST` does not wait for the store
and track buffers, so a buffered store to the same line could mark its word
present again after the clear.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile runs with word tracking on and scans response acceptance every
cycle or every fourth cycle. Geometry is fixed at 32-bit words, 8 words per
line, 2 sets, and 4 ways. A successful run prints `[BSG_FINISH]`.

Without the fix, the new lines keep the old lines' track bits: A1 returns the
old line's data, and A2 and A3 write the old line's words over memory.

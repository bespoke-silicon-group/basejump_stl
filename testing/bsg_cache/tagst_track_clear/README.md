This regression checks that `TAGST` clears the track bits of the way it
writes, so a line set up with `TAGST` starts with no word present, as after a
store-miss allocation. It needs word tracking.

With word tracking off there are no track bits to clear: a line set up with
`TAGST` holds whatever data its way held before. Case C of `../tagst_interlock`
relies on that.

Each case first puts known data in memory, then leaves a way holding a fully
tracked line with other data, and reuses that way with `TAGST`:

- A1: a load from the new line must fill from memory.
- A2: a full-word store to the new line, then `AFLINV`, must write back only
  that word; memory keeps the line's other words.
- A3: a byte store to the new line must merge with the word from memory, and
  `AFLINV` must keep the line's other words.
- B: a store hit just ahead of a `TAGST` that renames its line. The store's
  track bit must not reach the renamed line, so a load from it fills from
  memory. This also depends on `TAGST` waiting for the requests ahead of it
  (see `../tagst_interlock`).

A load that misses returns its word straight from the refill, so A1 and B
read the word a second time to check the copy the cache kept.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile runs with word tracking on and scans response acceptance every
cycle or every fourth cycle. Geometry is fixed at 32-bit words, 8 words per
line, 2 sets, and 4 ways. A successful run prints `[BSG_FINISH]`.

Without the fix, the new lines keep the old lines' track bits: A1 returns the
old line's data, and A2 and A3 write the old line's words over memory. If
`TAGST` does not wait for the store ahead of it, B's second load returns the
stored word.

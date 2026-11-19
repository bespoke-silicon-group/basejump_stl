This regression checks that `TAGST` takes effect only after the requests
ahead of it have finished, including stores still in the store buffer.

`TAGST` writes a tag directly as it enters the pipeline, outside the miss
handler. The cache now holds it while any other request is in the pipeline
or the store or track buffer holds an entry. TAGSTs can still follow each
other back to back. The cases:

- A: a load miss just ahead of a `TAGST` to the way the miss will fill. The
  fill must not overwrite the tag `TAGST` wrote; `TAGLA` reads it back.
- B: the same with a store miss.
- C (word tracking off): a store hit just ahead of a `TAGST` that renames its
  line. The store must land before the rename, so the renamed line holds it.
  With word tracking on, this case is in `../tagst_track_clear`.
- D: an `AFLINV` of a dirty line just ahead of a `TAGST` to its way. The flush
  must still write the line back, and must not clear the valid bit the `TAGST`
  sets; `TAGLV` and a load read both back.
- With every response taken at once, the initial tag sweep must be accepted
  one `TAGST` per cycle.

After the last response the test waits for further responses; any extra
response terminates with `$fatal`.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile scans word tracking off/on and response acceptance every cycle or
every fourth cycle. Geometry is fixed at 32-bit words, 8 words per line, 2 sets,
and 4 ways. A successful run prints `[BSG_FINISH]`.

Without the interlock, A and B read back the missing line's tag instead of the
one `TAGST` wrote, and C reads the word from before the store. D reads the way
back invalid, and with word tracking on the flush writes nothing back: it
reads the track bits after the `TAGST` has cleared them. An interlock that
also held a `TAGST` behind earlier `TAGST`s fails the sweep check.

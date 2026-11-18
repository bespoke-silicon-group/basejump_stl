This regression checks that `TAGST` clears only the dirty bit of the way it
writes. The other ways in the set may hold lines that have not been written
back, and they must stay dirty.

Case A fills all four ways of a set with dirty lines, then uses `TAGST` to
invalidate way 2. `AFLINV` and a reload must return the data stored in the
other three lines; the line in way 2 is discarded, as `TAGST` intends. Case B
is a control: a `TAGST` that retags a dirty way must still clear that way's
dirty bit, so its old data is never written to the new tag's address.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile scans word tracking off/on and response acceptance every cycle or
every fourth cycle. Geometry is fixed at 32-bit words, 8 words per line, 2 sets,
and 4 ways. The test clears every tag before issuing requests and compares
reloads against explicit expected values. A mismatch, unexpected response, or
timeout terminates with `$fatal`; a successful run prints `[BSG_FINISH]`.

Without the fix, `TAGST` clears the dirty bits of every way in the set, so case
A loses all three surviving lines.

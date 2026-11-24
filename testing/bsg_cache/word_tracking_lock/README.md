This regression checks that a tracking miss keeps the lock bit of its line.

With word tracking, a full-word store to a line that is not in the cache
allocates the line without fetching it, and only the stored word is tracked.
`ALOCK` can lock such a line. A later load, atomic or partial store to one of
its untracked words is a tracking miss: the cache fetches the missing words
into the same way. The line must still be locked afterwards.

| Case | What it does | What is checked |
| --- | --- | --- |
| A | load of an untracked word of a locked line | the lock bit, the fetched word, the tracked word |
| B | atomic swap on an untracked word of a locked line | the lock bit, the old and the new value |
| C | byte store to an untracked word of a locked line | the lock bit, the stored byte |
| D | three more lines in the set of A to C, which has one way left | the three locked lines are still in their ways |
| E | controls | `ALOCK` of a line that is not in the cache locks it; `AUNLOCK` unlocks it; a tracking miss of a line that is not locked leaves it unlocked |

The lock bit is read with `TAGLV`, and the line of a way with `TAGLA`. The test
uses the unmodified DMA model from `../common`.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile scans word tracking off/on and response acceptance every cycle or
every fourth cycle. Geometry is fixed at 32-bit words, 8 words per line, 2 sets,
and 4 ways. The test clears every tag before issuing requests and compares
every checked response against an explicit expected value. A mismatch,
unexpected response, or timeout terminates with `$fatal`; a successful run
prints `[BSG_FINISH]`.

Without the fix, word tracking enabled clears the lock bit in cases A, B and C,
and case D then finds other lines in the ways that were locked. Word tracking
disabled has no tracking misses and is a passing control.

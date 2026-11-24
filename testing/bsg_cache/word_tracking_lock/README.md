This regression checks that a tracking miss keeps the lock bit of its line,
and that a way taken out of use with `TAGST` stays out of use.

With word tracking, a full-word store to a line that is not in the cache
allocates the line without fetching it, and only the stored word is tracked.
`ALOCK` can lock such a line. A later load, atomic or partial store to one of
its untracked words is a tracking miss: the cache fetches the missing words
into the same way. The line must still be locked afterwards.

`TAGST` writes a lock bit too: bit 30 of its data, next to the valid bit in
bit 31. A way written invalid and locked is out of use, which is how a way
with a defect in its memory is avoided: no request hits it, and no line is
placed in it.

| Case | What it does | What is checked |
| --- | --- | --- |
| A | load of an untracked word of a locked line | the lock bit, the fetched word, the tracked word |
| B | atomic swap on an untracked word of a locked line | the lock bit, the old and the new value |
| C | byte store to an untracked word of a locked line | the lock bit, the stored byte |
| D | three more lines in the set of A to C, which has one way left | the three locked lines are still in their ways |
| E | controls | `ALOCK` of a line that is not in the cache locks it; `AUNLOCK` unlocks it; a tracking miss of a line that is not locked leaves it unlocked |
| F | `TAGST` writes a line valid and locked, then a load of it, which is a tracking miss because `TAGST` clears the track bits | the lock bit, and at the end that the line is still in its way |
| G | `TAGST` writes a way invalid and locked; six more lines then go through the two ways that are left, with a tracking miss, `AFLINV`, a `TAGFL` of the locked way, and a load with the tag that `TAGST` wrote | the way is still locked and invalid, and still holds the tag from `TAGST`; the data of the other lines |

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

Without the fix, word tracking enabled clears the lock bit in cases A, B, C
and F, and cases D and F then find other lines in the ways that were locked.
Word tracking disabled has no tracking misses and is a passing control. Case G
passes with or without the fix: a way that is invalid is never hit, so it has
no tracking misses. It is there to keep it that way.

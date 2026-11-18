This regression checks that a `TAGST` arriving while the cache finishes a miss
does not make it repeat the request waiting behind the miss.

During a miss the tl stage cannot accept a `TAGST`. When the miss completes,
the tv stage takes the tl stage's request, so the tl stage must be emptied even
though it accepts nothing new. Otherwise that request runs through tv twice: it
returns an extra response, and an atomic is applied twice.

Case A puts `AMOADD_W` behind a store miss, with a `TAGST` next in line. The
add must return the old value once and leave memory incremented once. Case B
does the same with a load behind the miss. After the last response the test
waits for further responses; any extra response terminates with `$fatal`.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The Makefile scans word tracking off/on and response acceptance every cycle or
every fourth cycle. Geometry is fixed at 32-bit words, 8 words per line, 2 sets,
and 4 ways, with arithmetic atomics enabled. A successful run prints
`[BSG_FINISH]`.

Without the fix, case A's add runs twice and the responses after it are offset.

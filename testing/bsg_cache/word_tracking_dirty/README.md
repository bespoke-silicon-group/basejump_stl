This regression checks that a store or atomic to an untracked word marks its
cache line dirty, including after `AFL` has written the line back without
invalidating it. A later `AFLINV` and reload must preserve the new data.

The test covers masked stores, byte stores, and atomic swap (including its
returned old value). Controls check a full-word store, a masked store without
the intervening flush, and a load tracking miss that must preserve an already
dirty line. It uses the unmodified DMA model from `../common`.

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
The Makefile requires that success marker, since VCS can return status zero
even after `$fatal`.

Without the dirty-bit fix, word tracking enabled loses the masked store, byte
store, and atomic-swap update. Word tracking disabled is a passing control.

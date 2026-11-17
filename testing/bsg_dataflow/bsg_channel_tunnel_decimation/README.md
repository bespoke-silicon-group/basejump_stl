This regression checks `bsg_channel_tunnel` with `lg_credit_decimation_p`
given explicitly, as the module now requires. D below is
`2**lg_credit_decimation_p`, the accumulated-credit threshold that makes a
return eligible. A return can carry more than D credits.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The positive test wires two tunnels back to back and runs twice, with the
shared link and the consumers moving every cycle and every fourth cycle.

Traffic: 64 words per channel in each direction on two channels, for each
setting below. Every word is checked whenever it is valid, and every stream
must complete.

| `remote_credits_p` | `lg_credit_decimation_p` | D |
|---|---|---|
| 1, 2 | 0 | 1 |
| 2, 3 | 1 | 2 |
| 5, 7 | 2 | 4 |
| 8, 15 | 3 | 8 |
| 16, 32 | 4 | 16 |

The first value in each row is the smallest the decimation allows, or close
to it. Credit counts below 16 are the ones the removed default got wrong.

Sizing: one channel offers a word every cycle and the far side takes each
word at once. For D = 1, 2, 4 and 8, `remote_credits_p = D + 2` must deliver
1000 words in 1000 cycles and `D + 1` must deliver fewer. The 2 is the round
trip of two directly wired tunnels, so this is the header's rule
`remote_credits_p >= round_trip_latency_cycles + D` with nothing in between.
If the tunnel's latency changes, remeasure the bound used by this test.

Each positive run must print `[BSG_FINISH]`; a zero exit status alone is not
enough. A mismatch, an extra word or a timeout ends the run with `$fatal`.

The default target also runs two negative tests, `bad-decimation`
(`remote_credits_p=8` with `lg_credit_decimation_p=4`) and `bad-width`
(`width_p=4`, too narrow to carry two 4-bit credit counts). Elaboration must
fail with a nonzero build status, and the tunnel's own "bad params" diagnostic
must appear in the output; a generic tool error does not count. These tests
do not run the simulator. Under Verilator the build uses
`-Werror-USERERROR`, because `Makefile.sim` passes `--Wno-fatal` and a failed
`BSG_ELAB_CHECK` would otherwise be only a warning.

Use `make SIMULATOR=... all` for only the positive tests, or
`make SIMULATOR=... bad-decimation` and `make SIMULATOR=... bad-width` for
the negative ones. Optional `VERILATOR_FLAGS` and `VCS_FLAGS` are passed to
the selected compiler.

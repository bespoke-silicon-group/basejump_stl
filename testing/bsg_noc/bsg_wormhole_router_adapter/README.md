This regression checks the packet serializer/deserializer together. The payload
parameter describes the body of the entire packet; the link transfers one
`flit_width_p` word at a time. Packet format remains `{payload, len, cord}`.

Run either simulator from this directory:

```
make SIMULATOR=verilator
make SIMULATOR=vcs
```

The positive test sends 32 packets through each geometry below, both without
stalls and with link transfers/output acceptance enabled every fourth cycle.
Four coordinate bits and four length bits are used throughout. All packets use
the maximum legal encoded length, which is the flit count minus one.

| Payload bits | Flit bits | Packet bits | Flits |
|---|---|---|---|
| 16 | 32 | 24 | 1 |
| 4 | 16 | 12 | 1 |
| 16 | 8 | 24 | 3 |
| 16 | 16 | 24 | 2 |
| 17 | 8 | 25 | 4 |

The test checks every valid output, including cycles when it is stalled, and
fails on corruption, extra packets, or timeout. Each positive run must print
`[BSG_FINISH]`; a zero simulator exit status alone is insufficient. Before the
port-width fix, the first two geometries lose upper packet bits.

The default target also runs `invalid-length`. That test requests four flits
from storage for three and requires the input adapter's specific length error.
The link is stalled to avoid an unrelated downstream counter error. Verilator
normally terminates on the assertion; VCS may report it and continue. Before
the length-bound fix, the required diagnostic is absent and this target fails.

Use `make SIMULATOR=... all` for only the positive tests, or
`make SIMULATOR=... invalid-length` for only the negative test. Optional
`VERILATOR_FLAGS` and `VCS_FLAGS` are passed to the selected compiler.

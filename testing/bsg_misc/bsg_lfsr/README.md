The automatic 32-bit mask uses taps 31, 29, 25, and 24 (`32'ha3000000`).
From any nonzero seed it has period 4,294,967,295. The previous mask,
`32'ha6000000`, repeats after 91,203,791 advances from seed 1. Callers that
need to retain that sequence can explicitly set `xor_mask_p=32'ha6000000`.

Run from this directory with the selected simulator on `PATH`:

```sh
make SIMULATOR=vcs check
make SIMULATOR=verilator check
```

The test checks the actual automatic masks for widths 32, 60, and 64 using
GF(2) polynomial exponentiation and every distinct prime factor of each
maximal period. It then compares 2,000 RTL cycles against reference sequences,
including reset, stalls, a mid-run reset, a second 32-bit seed, and an explicit
override preserving the old mask. It does not simulate all 2^32-1 advances.

Failures call `$fatal`; the Makefile also requires the final `[BSG_FINISH]`
marker, since a simulator may return zero after `$fatal`. `VCS_FLAGS` and
`VERILATOR_FLAGS` can supply additional compiler or build options.

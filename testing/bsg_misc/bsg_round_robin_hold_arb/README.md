`hold_on_sr_p=1` preserves the priority pointer when the only requester is
the highest-priority input, `(last + 1) % inputs_p`. The generator previously
reversed the requester bit index in this comparison. For example, with four
inputs and pointer 0, it held for requester 2 instead of requester 1.

The hold logic decodes the pointer with `inputs_p'(1) << last_r`, rotates
that one-hot vector left by one bit, and compares the entire request vector
against it. The rotation handles wraparound at every width; a separate
one-input branch avoids an empty part-select. The validity check prevents
an unused pointer encoding from matching an idle request vector.

Run from this directory with the selected simulator on `PATH`:

```sh
make SIMULATOR=vcs check
make SIMULATOR=verilator check
```

The test covers every supported input count (1 through 24), with ordinary,
hold-on-single-request, and reset-on-single-request arbitration. It checks
each pointer position against each lone requester with grants disabled,
with backpressure, and with acceptance. An all-request probe observes the
resulting priority through public outputs. It also checks idle cycles,
1,024 deterministic random cycles per instance, and a mid-run reset.
Selection, grant gating, validity, and valid tags are compared against a
cyclic priority search; the test does not inspect internal DUT state.

The Makefile verifies that the generator reproduces the committed RTL.
Failures call `$fatal`, and a successful run must print the `[BSG_FINISH]`
marker. `VCS_FLAGS` and `VERILATOR_FLAGS` accept additional build options.

To regenerate the RTL from the repository root:

```sh
python3 bsg_misc/bsg_round_robin_arb.py 24 > bsg_misc/bsg_round_robin_arb.sv
```

Run `make test` to check the C++ DPI clock scheduler against an integer edge
schedule. Cases cover a single clock, different periods, coincident clocks,
and three clocks. Coincident callbacks are compared without imposing an order.

Set `CXX=clang++` or `CXX=g++` to select a compiler. `VERILATOR_ROOT` optionally
selects Verilator's real `svdpi.h`; otherwise the test supplies the two DPI
scope declarations it uses. Scope callbacks are simulated, so no RTL build
or simulator executable is needed. Standard-library assertions remain enabled
to catch empty priority-queue accesses. Build outputs use a temporary directory.

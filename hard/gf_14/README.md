# GF14 Hard Directory

This directory contains hardened (process specific) variants of basejump_stl
RTL modules. These modules should be swapped with the RTL modules of the same
name during the chip implementation flow.

## Special Attributes

Cell instances with the `*DONT_TOUCH*` in the name should get a dont_touch
attribute applied to these instances in the backend flow.

All instances of library cell `*SYNC*DFF*` should automatically get a dont_touch
attribute (regardless of the instance name).

Cell instances with the `*NO_CLOCK_GATE*` in the name should get an attribute
to prevent clock gating on this module/cell.


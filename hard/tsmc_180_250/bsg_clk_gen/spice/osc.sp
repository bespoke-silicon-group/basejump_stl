* MBT 10/5/2016
* note: this spice file is only for verifying the frequency of the different 
* settings of the oscillator. it does not model the atomic update of new
* settings or the downsampler.
*

* 250nm TT 25C 2.5V fast=2.1ns slow=4.4ns
* 2.10 2.16 2.24 2.33 2.40 2.46 2.54 2.62 2.69 2.75 2.83 2.92 3.00 3.05 3.14 3.22
* 3.29 3.35 3.43 3.51 3.58 3.64 3.72 3.80 3.88 3.94 4.02 4.10 4.18 4.24 4.32 4.40
*
* 180nm TT 25C 1.8V fast=1.42ns slow=3.10ns
* 1.42 1.47 1.54 1.60 1.63 1.68 1.75 1.81 1.85 1.90 1.97 2.03 2.06 2.11 2.18 2.24
* 2.27 2.32 2.39 2.45 2.48 2.53 2.6  2.67 2.7  2.75 2.82 2.88 2.92 2.96 3.04 3.10

* 180nm TT 125C 1.8V fast=1.64ns slow=3.58ns
* 1.64 1.70 1.78 1.85 1.89 1.94 2.02 2.10 2.14 2.19 2.28 2.35 2.38 2.44 2.52 2.59
* 2.62 2.68 2.76 2.83 2.87 2.93 3.01 3.08 3.12 3.18 3.26 3.33 3.37 3.42 3.50 3.58

* 180nm SS 125C 1.62V fast=2.37ns slow=5.05ns
* 2.37 2.45 2.56 2.66 2.71 2.79 2.90 3.00 3.06 3.14 3.25 3.35 3.40 3.48 3.59 3.69
* 3.74 3.81 3.92 4.02 4.07 4.15 4.26 4.36 4.42 4.50 4.61 4.71 4.76 4.84 4.95 5.05

* 180nm FF -40C 1.9V fast=0.978ps slow=2.20ns
* 0.978 1.01 1.06 1.11 1.13 1.17 1.22 1.27 1.29 1.32 1.38 1.42 1.44 1.48 1.53 1.58
* 1.60  1.63 1.69 1.73 1.75 1.79 1.84 1.89 1.91 1.94 2.00 2.04 2.06 2.10 2.15 2.20

* ADG

X1 n1 n0 CLKINVX2
X2 n2 n1 CLKINVX2
X211 n2a n1 CLKINVX4
X3 n3 n2 CLKINVX2
X4 n4 n3 CLKINVX2
X411 n4a n3 CLKINVX4
* instead of mux input load of .008pF
X412 n4a n3 CLKINVX2
X5 n5 n4 CLKINVX2
X6 n6 n5 CLKINVX2
X611 n6a n5 CLKINVX4
X7 n7 n6 CLKINVX2
X8 n8 n7 CLKINVX2
X6111 n8a n7 CLKINVX4

* we need this extra gate to provide the right load on this line
X6112 n8b n7 CLKINVX3

X8a n3000a n3000b n8 n3000c n3000d  DFFRX4

* on reset condition force s4mod high
X9a s4mod s4 c0 NAND2BX2

* we wire gnd to position 2 on mux
X9 n10 n8 n6 gnd n0 s4 s4mod MXI4X4

* CDG

X11 n11 n10 CLKINVX2
X12 n12 n11 CLKINVX2
X1211 n12a n11 CLKINVX4
X13 n13 n12 CLKINVX2
X14 n14 n13 CLKINVX2
X1411 n14a n13 CLKINVX4
X15 n15 n14 CLKINVX2
X16 n16 n15 CLKINVX2
X1611 n16a n15 CLKINVX4
X17 n17 n16 CLKINVX2
X18 n18 n17 CLKINVX2

X19 n20a n16 n14 n12 n10 s2 s3 MXI4X4

X19x n2000a n2000b n18 n2000x n2000w DFFRX4
X19y n2000c n2000d n18 n2000y n2000q DFFRX4

* FDT

X19a n20 n20a CLKINVX4

X20 n31 n20 CLKINVX2

X21 n32 n20 CLKINVX2
X21a n42 n32 CLKINVX3

X22 n33 n20 CLKINVX2
X22a n43 n33 CLKINVX3
X22b n43 n33 CLKINVX4

X23 n34 n20 CLKINVX2
X23a n44 n34 CLKINVX3
X23b n45 n34 CLKINVX4
X23c n46 n34 CLKINVX4

X77 n0 n34 n33 n32 n31 s0 s1 MXI4X4

X77a n2000a n2000b n0 n2001x n2001xx DFFRX4
X77b n2000c n2000d n0 n2001y n2001yy DFFRX4

X91 n100 n0 CLKBUFX8
X92 n101 n0 CLKBUFX8

*V1 S0  gnd SUPPLY
*V2 S1  gnd SUPPLY
*V3 S10 gnd SUPPLY
*V4 S11 gnd SUPPLY
*V5 S12 gnd SUPPLY

* sweep control inputs
*                initial peak  init_delay  rise   fall pulse   period
Vin1 c0 gnd PULSE 0     SUPPLY 1000ps        10ps    10ps 800ns 1600ns
Vin2 s5 gnd PULSE 0     SUPPLY 25000ps        10ps    10ps 320ns 640ns
Vin3 s4 gnd PULSE 0     SUPPLY 25000ps        10ps    10ps 160ns 320ns
Vin4 s3 gnd PULSE 0     SUPPLY 25000ps       10ps    10ps 80ns 160ns
Vin5 s2 gnd PULSE 0     SUPPLY 25000ps       10ps    10ps 40ns  80ns
Vin6 s1 gnd PULSE 0     SUPPLY 25000ps       10ps    10ps 20ns 40ns
Vin7 s0 gnd PULSE 0     SUPPLY 25000ps       10ps    10ps 10ns 20ns

.option nomod post
.option accurate
.option captable=1
.tran 1p 642ns

.end

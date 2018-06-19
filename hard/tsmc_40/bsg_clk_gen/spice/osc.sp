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

X1 n0 n1 vdd vss CKND2BWP * rev
X2 n1 n2 vdd vss CKND2BWP * rev
X211 n1 n2a vdd vss CKND4BWP * rev
X3 n2 n3 vdd vss CKND2BWP * rev
X4 n3 n4 vdd vss CKND2BWP * rev
X411 n3 n4a vdd vss CKND4BWP * rev
* instead of mux input load of .008pF
X412 n3 n4a vdd vss CKND2BWP * rev
X5 n4 n5 vdd vss CKND2BWP * rev
X6 n5 n6 vdd vss CKND2BWP * rev
X611 n5 n6a vdd vss CKND4BWP * rev
X7 n6 n7 vdd vss CKND2BWP * rev
X8 n7 n8 vdd vss CKND2BWP * rev
X6111 n7 n8a vdd vss CKND4BWP * rev

* we need this extra gate to provide the right load on this line
X6112 n7 n8b vdd vss CKND3BWP * rev

* D CP CDN Q QN VDD VSS   CDN=async clear; CP=clock pin

X8a n3000a n8 n3000b n3000c n3000d vdd vss  DFCND4BWP  * c8 is clockin (rev)

* on reset condition force s4mod high
X9a s4 c0 s4mod vdd vss IND2D2BWP * rev

* we wire gnd to position 2 on mux
X9 n8 n6 gnd n0 s4 s4mod n10 vdd vss MUX4ND4BWP * rev

* CDG

X11 n10 n11 vdd vss CKND2BWP  * rev
X12 n11 n12 vdd vss CKND2BWP  * rev
X1211 n11 n12a vdd vss CKND4BWP  * rev
X13 n12 n13 vdd vss CKND2BWP  * rev
X14 n13 n14 vdd vss CKND2BWP  * rev
X1411 n13 n14a vdd vss CKND4BWP  * rev
X15 n14 n15 vdd vss CKND2BWP  * rev
X16 n15 n16 vdd vss CKND2BWP  * rev
X1611 n15 n16a vdd vss CKND4BWP  * rev
X17 n16 n17 vdd vss CKND2BWP  * rev
X18 n17 n18 vdd vss CKND2BWP  * rev

X19 n16 n14 n12 n10 s2 s3 n20a vdd vss MUX4ND4BWP * out=n20a *rev

X19x n2000a n18 n2000b n2000x n2000w vdd vss DFCND4BWP
X19y n2000c n18 n2000d n2000y n2000q vdd vss DFCND4BWP

* FDT

X19a n20a n20 vdd vss CKND4BWP  * I0 in=n20a rev

X20 n20 n31 vdd vss CKND2BWP    * I1 in=n20 rev

X21  n20 n32 vdd vss CKND2BWP   * I2    in=n20 rev
X21a n32 n42 vdd vss CKND3BWP   * I2_1  in=n32 rev

X22  n20 n33 vdd vss CKND2BWP   * I3 in=n20 rev
X22a n33 n43 vdd vss CKND3BWP   * I3_1 in=n33 rev
X22b n33 n43 vdd vss CKND4BWP   * I3_2 in=n33 rev

X23 n20 n34  vdd vss CKND2BWP   * I4 in=n20 rev
X23a n34 n44 vdd vss CKND3BWP   * I4_1 in=n34 rev
X23b n34 n45 vdd vss CKND4BWP   * I4_2 in=n34 rev
X23c n34 n46 vdd vss CKND4BWP   * I4_3 in=n34 rev

X77 n34 n33 n32 n31 s0 s1 n0 vdd vss MUX4ND4BWP   * M2

*n0 is clock
X77a n2000a n0 n2000b n2001x n2001xx vdd vss DFCND4BWP * n2001xx, n2001x, n2000a is dummy
X77b n2000c n0 n2000d n2001y n2001yy vdd vss DFCND4BWP * n2001yy, n2001y, n2000c is dummy

X91 n0 n100 vdd vss CKBD8BWP * n100 is dummy load
X92 n0 n101 vdd vss CKBD8BWP * n101 is dummy load

*V1 S0  gnd SUPPLY
*V2 S1  gnd SUPPLY
*V3 S10 gnd SUPPLY
*V4 S11 gnd SUPPLY
*V5 S12 gnd SUPPLY

* sweep control inputs
*                initial peak  init_delay  rise   fall pulse   period
Vin1 c0 gnd PULSE 0     SUPPLY 1000ps       10ps    10ps 38ns 64ns
Vin3 s4 gnd PULSE 0     SUPPLY 5000ps       10ps    10ps 16ns 32ns
Vin4 s3 gnd PULSE 0     SUPPLY 5000ps       10ps    10ps 8ns 16ns
Vin5 s2 gnd PULSE 0     SUPPLY 5000ps       10ps    10ps 4ns  8ns
Vin6 s1 gnd PULSE 0     SUPPLY 5000ps       10ps    10ps 2ns 4ns
Vin7 s0 gnd PULSE 0     SUPPLY 5000ps       10ps    10ps 1ns 2ns

.option nomod post
.option accurate
.option captable=1
.tran 1p 40ns

.end

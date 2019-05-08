

* an output pin (PAD I OEN)
X1 n2 n1 vss PDT12DGZ


* bond pad
C1 n2 vsspst 2p

* bond wire
R0 n2 n2a 500m
L0 n2b n2a 4n



* parallel termination
R1 n2b vsspst 100
R2 n2b vd33 100


* an input pin (C PAD)
X0 n0 n2b PDDDGZ
C2 n2b vsspst 2p

* an output VDD2 with POC (VD33)
X2 vd33 PVDD2POC

* an output VSS2 (VSSPST)
X3 vsspst PVSS2DGZ

* a core VDD (VDD)
X4 vdd PVDD1DGZ

* a core VSS (VSS)
X5 vss PVSS1DGZ

Vin7 n1 gnd PULSE 0     SUPPLY 25000ps       200ps    200ps 3ns 6ns
.option nomod post
.option accurate
.option captable=1
.tran 1p 100ns

.end
* MBT 6/15/2019
* duty cycle 95/98ps -> 197/199ps SL cells
*
*
* ADT
* A VSS VDD Z VNW VPW

X1   n0 vss vdd  n1  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X2   n1 vss vdd  n2  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X211 n1 vss vdd  n2a vdd vss SC7P5T_CKINVX4_SSC14SL * rev
X3   n2 vss vdd  n3  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X4   n3 vss vdd  n4  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X411 n3 vss vdd  n4a vdd vss SC7P5T_CKINVX4_SSC14SL * rev

X412  n3 vss vdd  n4a vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X5    n4 vss vdd  n5  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X6    n5 vss vdd  n6  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X611  n5 vss vdd  n6a vdd vss SC7P5T_CKINVX4_SSC14SL * rev
X7    n6 vss vdd  n7  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X8    n7 vss vdd  n8  vdd vss SC7P5T_CKINVX2_SSC14SL * rev
X6111 n7 vss vdd  n8a vdd vss SC7P5T_CKINVX4_SSC14SL * rev

* we need this extra gate to provide the right load on this line
X6112 n7 vss vdd n8b vdd vss SC7P5T_CKINVX3_SSC14SL * rev

* D Flip-Flop with Async Clear
*                        D CP CDN            Q QN VDD VSS   CDN=async clear; CP=clock pin
* SC7P5T_DFFRQX4_SSC14SL D CLK RESET VSS VDD Q VNW VPW
X8a n3000a n8 n3000b vss vdd n3000c vdd vss   SC7P5T_DFFRQX4_SSC14SL  * c8 is clockin (rev)

V10 n3000a gnd SUPPLY
V11 n3000b gnd SUPPLY

* 2-input NAND, inverted A input
* on reset condition force s4mod high
* subckt IND2D2BWP A1 B1 ZN VDD VSS
* SC7P5T_ND2IAX2_SSC14SL A B VSS VDD Z VNW VPW
X9a s4 c0 vss vdd s4mod vdd vss  SC7P5T_ND2IAX2_SSC14SL * rev

* Inverting 4-input multiplexer
* we wire gnd to position 2 on mux
* MUX4ND4BWP I0 I1 I2 I3 S0 S1 ZN VDD VSS
* SC7P5T_MUXI4X4_SSC14SL S0 D0 D1 D2 D3 S1 VSS VDD Z VNW VPW
X9 s4 n8 n6 gnd n0 s4mod vss vdd n10 vdd vss SC7P5T_MUXI4X4_SSC14SL * rev

* CDT

X11 n10   vss vdd n11  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X12 n11   vss vdd n12  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X1211 n11 vss vdd n12a vdd vss SC7P5T_CKINVX4_SSC14SL  * rev
X13 n12   vss vdd n13  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X14 n13   vss vdd n14  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X1411 n13 vss vdd n14a vdd vss SC7P5T_CKINVX4_SSC14SL  * rev
X15 n14   vss vdd n15  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X16 n15   vss vdd n16  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X1611 n15 vss vdd n16a vdd vss SC7P5T_CKINVX4_SSC14SL  * rev
X17 n16   vss vdd n17  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev
X18 n17   vss vdd n18  vdd vss SC7P5T_CKINVX2_SSC14SL  * rev

* Inverting 4-input multiplexer
* SC7P5T_MUXI4X4_SSC14SL S0 D0 D1 D2 D3 S1 VSS VDD Z VNW VPW
* MUX4ND4BWP I0 I1 I2 I3 S0 S1 ZN VDD VSS
X19 s2 n16 n14 n12 n10 s3 vss vdd n20a vdd vss SC7P5T_MUXI4X4_SSC14SL * out=n20a *rev

* D Flip-Flop with Async Clear
* *                      D CP  CDN           Q QN VDD VSS   CDN=async clear; CP=clock pin
* SC7P5T_DFFRQX4_SSC14SL D CLK RESET VSS VDD Q VNW VPW
X19x n2000a n18 n2000b vss vdd n2000x vdd vss  SC7P5T_DFFRQX4_SSC14SL
X19y n2000c n18 n2000d vss vdd n2000y vdd vss  SC7P5T_DFFRQX4_SSC14SL

V12 n2000a gnd SUPPLY
V13 n2000b gnd SUPPLY
V14 n2000c gnd SUPPLY
V15 n2000d gnd SUPPLY
V16 n2000x gnd SUPPLY
V17 n2000y gnd SUPPLY

* FDT

X19a n20a vss vdd n20 vdd vss SC7P5T_CKINVX4_SSC14SL  * I0 in=n20a rev

X20  n20  vss vdd n31 vdd vss SC7P5T_CKINVX2_SSC14SL  * I1 in=n20 rev

X21  n20  vss vdd n32 vdd vss SC7P5T_CKINVX2_SSC14SL   * I2    in=n20 rev
X21a n32  vss vdd n42 vdd vss SC7P5T_CKINVX3_SSC14SL   * I2_1  in=n32 rev

X22  n20  vss vdd n33 vdd vss SC7P5T_CKINVX2_SSC14SL   * I3 in=n20 rev
X22a n33  vss vdd n43 vdd vss SC7P5T_CKINVX3_SSC14SL   * I3_1 in=n33 rev
X22b n33  vss vdd n43 vdd vss SC7P5T_CKINVX4_SSC14SL   * I3_2 in=n33 rev

X23  n20  vss vdd n34 vdd vss SC7P5T_CKINVX2_SSC14SL   * I4 in=n20 rev
X23a n34  vss vdd n44 vdd vss SC7P5T_CKINVX3_SSC14SL   * I4_1 in=n34 rev
X23b n34  vss vdd n45 vdd vss SC7P5T_CKINVX4_SSC14SL   * I4_2 in=n34 rev
X23c n34  vss vdd n46 vdd vss SC7P5T_CKINVX4_SSC14SL   * I4_3 in=n34 rev

* Inverting 4-input multiplexer
* MUX4ND4BWP I0 I1 I2 I3 S0 S1 ZN VDD VSS
* SC7P5T_MUXI4X4_SSC14SL S0 D0 D1 D2 D3 S1 VSS VDD Z VNW VPW
* X77 n34 n33 n32 n31 s0 s1 n0 vss vdd MUX4ND4BWP   * M2
X77 s0 n34 n33 n32 n31 s1 vss vdd n0 vdd vss SC7P5T_MUXI4X4_SSC14SL * M2

* D Flip-Flop with Async Clear
* n0 is clock
*                        D CP  CDN           Q QN VDD VSS   CDN=async clear; CP=clock pin
* SC7P5T_DFFRQX4_SSC14SL D CLK RESET VSS VDD Q    VNW VPW
X77a n2000a n0 n2000b vss vdd n2001x vdd vss SC7P5T_DFFRQX4_SSC14SL * n2001xx, n2001x, n2000a is dummy
X77b n2000c n0 n2000d vss vdd n2001y vdd vss SC7P5T_DFFRQX4_SSC14SL * n2001yy, n2001y, n2000c is dummy


* Non-inverting clock buffer
X91 n0  vss vdd n100 vdd vss SC7P5T_BUFX8_SSC14SL * n100 is dummy load; presumably simulates clock tree
X92 n0  vss vdd n101 vdd vss SC7P5T_BUFX8_SSC14SL * n101 is dummy load

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



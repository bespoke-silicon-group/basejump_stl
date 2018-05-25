* FO4 measurement circuit
* Rise             Fall           Average
* 2.8071627e-11    2.7804428e-11  2.79380275  (7 stages)
* 2.7988202e-11    2.7759264e-11  2.78737330  (5 stages)
* 3 stages does not go rail-to-rail

* Initial value for n0, this starts the osc
.ic v(clk0_o)=0.9V
.ic v(clk_o)=0.9V
.ic v(clk1_o)=0.9V
.ic v(clk2_o)=0.9V

Vrst reset_i 0 0.9

.subckt stage IN OUT VDD VSS
X1  IN OUT VDD VSS CKND1BWP
X2  IN N2  VDD VSS CKND1BWP

X21 N2 N21  VDD VSS CKND4BWP 
X3  IN  N3  VDD VSS CKND1BWP
X31 N3 N31  VDD VSS CKND4BWP 
X4  IN  N4  VDD VSS CKND1BWP
X41 N4 N41  VDD VSS CKND4BWP 
.ends stage

X0   clk0_o  clk0_o  VDD  VSS stage

X12  clk_o  n01    VDD  VSS stage
X13  n01    n02    VDD  VSS stage
X14  n02    clk_o VDD  VSS stage

X2  clk1_o  n11    VDD  VSS stage
X3  n11     n12    VDD  VSS stage
X4  n12     n13    VDD  VSS stage
X5  n13     n14    VDD  VSS stage
X6  n14    clk1_o  VDD  VSS stage

X22  clk2_o n21    VDD  VSS stage
X23  n21    n22    VDD  VSS stage
X24  n22    n23    VDD  VSS stage
X25  n23    n24    VDD  VSS stage
X26  n24    n25    VDD  VSS stage
X27  n25    n26    VDD  VSS stage
X28  n26    clk2_o VDD  VSS stage

* Transient analysis
.tran 0.1p 10n

.measure tpdr2    * rising prop delay, 10th edge
+ TRIG v(clk2_o) VAL='SUPPLY/2' FALL=10
+ TARG v(n21)   VAL='SUPPLY/2' RISE=10

.measure tpdf2    * falling prop delay, 10th edge
+ TRIG v(clk2_o) VAL='SUPPLY/2' RISE=10
+ TARG v(n21)   VAL='SUPPLY/2'  FALL=10

.measure tpdr1    * rising prop delay, 10th edge
+ TRIG v(clk1_o) VAL='SUPPLY/2' FALL=10
+ TARG v(n11)   VAL='SUPPLY/2' RISE=10

.measure tpdf1    * falling prop delay, 10th edge
+ TRIG v(clk1_o) VAL='SUPPLY/2' RISE=10
+ TARG v(n11)   VAL='SUPPLY/2'  FALL=10

.measure tpdr    * rising prop delay, 10th edge
+ TRIG v(clk_o) VAL='SUPPLY/2' FALL=10
+ TARG v(n01)   VAL='SUPPLY/2' RISE=10

.measure tpdf    * rising prop delay, 10th edge
+ TRIG v(clk_o) VAL='SUPPLY/2' RISE=10
+ TARG v(n01)   VAL='SUPPLY/2' FALL=10

.measure trise   * measure rise time, 10th edge
+ TRIG v(clk1_o) VAL='0.2*SUPPLY' RISE=10
+ TARG v(clk1_o) VAL='0.8*SUPPLY' RISE=10

.measure tfall   * measure fall time, 10th edge
+ TRIG v(clk1_o) VAL='0.8*SUPPLY' FALL=10
+ TARG v(clk1_o) VAL='0.2*SUPPLY' FALL=10

.end

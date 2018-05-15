#!/usr/bin/python

import sys;

print '''

module bsg_rp_tsmc_40_reduce_and_b4 (input [3:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b4)
// synopsys rp_fill(0 3 UX)
// synopsys rp_fill(0 1 UX)
NAND2X2 b01   (.A(i[0]),.B(i[1]),.Y(lo[0]));
// synopsys rp_fill(0 2 UX)
NR2D4BWP b0123 (.A(lo[0]),.B(lo[1]),.Y(o));
// synopsys rp_fill(0 3 UX)
NAND2X2 b23   (.A(i[2]),.B(i[3]),.Y(lo[1]));
// synopsys rp_endgroup (andr_b4)
endmodule

module bsg_rp_tsmc_40_reduce_and_b6 (input [5:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b6 )
// synopsys rp_fill(0 4 UX)
// synopsys rp_fill(0 2 UX)
NAND3X2 b012   (.A(i[0]),.B(i[1]),.C(i[2]),.Y(lo[0]));
// synopsys rp_fill(0 3 UX)
NR2D4BWP b012345 (.A(lo[0]),.B(lo[1]),.Y(o));
// synopsys rp_fill(0 4 UX)
NAND3X2 b345   (.A(i[3]),.B(i[4]),.C(i[5]),.Y(lo[1]));
// synopsys rp_endgroup (andr_b6)
endmodule

module bsg_rp_tsmc_40_reduce_and_b8 (input [7:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b8 )
// synopsys rp_fill(0 8 UX)
// synopsys rp_fill(0 2 UX)
ND4D2BWP b0123   (.A1(i[0]),.A2(i[1]),.A3(i[2]),.A4(i[3]),.ZN(lo[0]));
// synopsys rp_fill(0 4 UX)
NR2D4BWP b01234567 (.A1(lo[0]),.A2(lo[1]),.ZN(o));
// synopsys rp_fill(0 5 UX)
ND4D2BWP b4567   (.A1(i[4]),.A2(i[5]),.A3(i[6]),.A4(i[7]),.ZN(lo[1]));
// synopsys rp_endgroup (andr_b8)
endmodule

module bsg_rp_tsmc_40_reduce_and_b9 (input [8:0] i, output o);
wire [2:0] lo;
// synopsys rp_group    (andr_b9 )
// synopsys rp_fill(0 9 UX)
// synopsys rp_fill(0 2 UX)
NAND3X2 b012   (.A(i[0]),.B(i[1]),.C(i[2]),.Y(lo[0]));
// synopsys rp_fill(0 3 UX)
NOR3X4 b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.Y(o));
// synopsys rp_fill(0 4 UX)
NAND3X2 b345   (.A(i[3]),.B(i[4]),.C(i[5]),.Y(lo[1]));
// synopsys rp_fill(0 7 UX)
NAND3X2 b678   (.A(i[6]),.B(i[7]),.C(i[8]),.Y(lo[2]));
// synopsys rp_endgroup (andr_b9)
endmodule

module bsg_rp_tsmc_40_reduce_and_b12 (input [11:0] i, output o);
wire [2:0] lo;
// synopsys rp_group    (andr_b12 )
// synopsys rp_fill(0 12 UX)
// synopsys rp_fill(0 2  UX)
ND4D2BWP b0123   (.A(i[0]),.B(i[1]),.C(i[2]),.D(i[3]),.Y(lo[0]));
// synopsys rp_fill(0 3  UX)
NOR3X4 b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.Y(o));
// synopsys rp_fill(0 4  UX)
ND4D2BWP b4567   (.A(i[4]),.B(i[5]),.C(i[6]),.D(i[7]),.Y(lo[1]));
// synopsys rp_fill(0 7  UX)
ND4D2BWP b89AB   (.A(i[8]),.B(i[9]),.C(i[10]),.D(i[11]),.Y(lo[2]));
// synopsys rp_endgroup (andr_b12)
endmodule

module bsg_rp_tsmc_40_reduce_and_b16 (input [15:0] i, output o);
wire [3:0] lo;
// synopsys rp_group    (andr_b16 )
// synopsys rp_fill(0 16 UX)
// synopsys rp_fill(0 2  UX)
ND4D2BWP b0123   (.A(i[0]),.B(i[1]),.C(i[2]),.D(i[3]),.Y(lo[0]));
// synopsys rp_fill(0 6  UX)
ND4D2BWP b4567   (.A(i[4]),.B(i[5]),.C(i[6]),.D(i[7]),.Y(lo[1]));
// synopsys rp_fill(0 7  UX)
NOR4X4 b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.D(lo[3]),.Y(o));
// synopsys rp_fill(0 9  UX)
ND4D2BWP b89AB   (.A1(i[8]),.A2(i[9]),.A3(i[10]),.A4(i[11]),.ZN(lo[2]));
// synopsys rp_fill(0 13  UX)
ND4D2BWP bCDEF   (.A1(i[12]),.A2(i[13]),.A3(i[14]),.A4(i[15]),.ZN(lo[3]));
// synopsys rp_endgroup (andr_b16)
endmodule


''';

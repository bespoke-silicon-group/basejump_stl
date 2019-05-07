#!/usr/bin/python

import sys;

print '''

module bsg_rp_gf_14_reduce_and_b4 (input [3:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b4)
// synopsys rp_fill(0 3 UX)
// synopsys rp_fill(0 1 UX)
SC7P5T_ND2X2_SSC14SL b01   (.A(i[0]),.B(i[1]),.Z(lo[0]));
// synopsys rp_fill(0 2 UX)
SC7P5T_NR2X4_SSC14SL b0123 (.A(lo[0]),.B(lo[1]),.Z(o));
// synopsys rp_fill(0 3 UX)
SC7P5T_ND2X2_SSC14SL b23   (.A(i[2]),.B(i[3]),.Z(lo[1]));
// synopsys rp_endgroup (andr_b4)
endmodule

module bsg_rp_gf_14_reduce_and_b6 (input [5:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b6 )
// synopsys rp_fill(0 4 UX)
// synopsys rp_fill(0 2 UX)
SC7P5T_ND3X2_SSC14SL b012   (.A(i[0]),.B(i[1]),.C(i[2]),.Z(lo[0]));
// synopsys rp_fill(0 3 UX)
SC7P5T_NR2X4_SSC14SL b012345 (.A(lo[0]),.B(lo[1]),.Z(o));
// synopsys rp_fill(0 4 UX)
SC7P5T_ND3X2_SSC14SL b345   (.A(i[3]),.B(i[4]),.C(i[5]),.Z(lo[1]));
// synopsys rp_endgroup (andr_b6)
endmodule

module bsg_rp_gf_14_reduce_and_b8 (input [7:0] i, output o);
wire [1:0] lo;
// synopsys rp_group    (andr_b8 )
// synopsys rp_fill(0 8 UX)
// synopsys rp_fill(0 2 UX)
SC7P5T_ND4X2_SSC14SL b0123   (.A(i[0]),.B(i[1]),.C(i[2]),.D(i[3]),.Z(lo[0]));
// synopsys rp_fill(0 4 UX)
SC7P5T_NR2X4_SSC14SL b01234567 (.A(lo[0]),.B(lo[1]),.Z(o));
// synopsys rp_fill(0 5 UX)
SC7P5T_ND4X2_SSC14SL b4567   (.A(i[4]),.B(i[5]),.C(i[6]),.D(i[7]),.Z(lo[1]));
// synopsys rp_endgroup (andr_b8)
endmodule

module bsg_rp_gf_14_reduce_and_b9 (input [8:0] i, output o);
wire [2:0] lo;
// synopsys rp_group    (andr_b9 )
// synopsys rp_fill(0 9 UX)
// synopsys rp_fill(0 2 UX)
SC7P5T_ND3X2_SSC14SL b012   (.A(i[0]),.B(i[1]),.C(i[2]),.Z(lo[0]));
// synopsys rp_fill(0 3 UX)
SC7P5T_NR3X4_SSC14SL b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.Z(o));
// synopsys rp_fill(0 4 UX)
SC7P5T_ND3X2_SSC14SL b345   (.A(i[3]),.B(i[4]),.C(i[5]),.Z(lo[1]));
// synopsys rp_fill(0 7 UX)
SC7P5T_ND3X2_SSC14SL b678   (.A(i[6]),.B(i[7]),.C(i[8]),.Z(lo[2]));
// synopsys rp_endgroup (andr_b9)
endmodule

module bsg_rp_gf_14_reduce_and_b12 (input [11:0] i, output o);
wire [2:0] lo;
// synopsys rp_group    (andr_b12 )
// synopsys rp_fill(0 12 UX)
// synopsys rp_fill(0 2  UX)
SC7P5T_ND4X2_SSC14SL b0123   (.A(i[0]),.B(i[1]),.C(i[2]),.D(i[3]),.Z(lo[0]));
// synopsys rp_fill(0 3  UX)
SC7P5T_NR3X4_SSC14SL b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.Z(o));
// synopsys rp_fill(0 4  UX)
SC7P5T_ND4X2_SSC14SL b4567   (.A(i[4]),.B(i[5]),.C(i[6]),.D(i[7]),.Z(lo[1]));
// synopsys rp_fill(0 7  UX)
SC7P5T_ND4X2_SSC14SL b89AB   (.A(i[8]),.B(i[9]),.C(i[10]),.D(i[11]),.Z(lo[2]));
// synopsys rp_endgroup (andr_b12)
endmodule

module bsg_rp_gf_14_reduce_and_b16 (input [15:0] i, output o);
wire [3:0] lo;
// synopsys rp_group    (andr_b16 )
// synopsys rp_fill(0 16 UX)
// synopsys rp_fill(0 2  UX)
SC7P5T_ND4X2_SSC14SL b0123   (.A(i[0]),.B(i[1]),.C(i[2]),.D(i[3]),.Z(lo[0]));
// synopsys rp_fill(0 6  UX)
SC7P5T_ND4X2_SSC14SL b4567   (.A(i[4]),.B(i[5]),.C(i[6]),.D(i[7]),.Z(lo[1]));
// synopsys rp_fill(0 7  UX)
SC7P5T_NR4X4_SSC14SL b012345678 (.A(lo[0]),.B(lo[1]),.C(lo[2]),.D(lo[3]),.Z(o));
// synopsys rp_fill(0 9  UX)
SC7P5T_ND4X2_SSC14SL b89AB   (.A(i[8]),.B(i[9]),.C(i[10]),.D(i[11]),.Z(lo[2]));
// synopsys rp_fill(0 13  UX)
SC7P5T_ND4X2_SSC14SL bCDEF   (.A(i[12]),.B(i[13]),.C(i[14]),.D(i[15]),.Z(lo[3]));
// synopsys rp_endgroup (andr_b16)
endmodule


''';

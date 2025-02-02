
from __future__ import print_function
import sys

num_rows_p = int(sys.argv[1])
num_cols_p = int(sys.argv[2])
num_dly_p  = int(sys.argv[3])

num_els_p = num_rows_p*num_cols_p

print("""
// ## AUTOGENERATED; DO NOT MODIFY
// ## num_rows_p = {num_rows_p}
// ## num_cols_p = {num_cols_p}
// ## num_dly_p = {num_dly_p}
""".format(num_rows_p=num_rows_p, num_cols_p=num_cols_p, num_dly_p=num_dly_p))

print("""
module bsg_rp_clk_gen_osc_v3_row
 (input    async_reset_neg_i
  , input  async_set_neg_i
  , input  clkgate_i
  , input  clkdly_i
  , input  clkfb_i
  , input  ctl_i
  , output clk_o
  );

  wire lobit, hibit;
  sky130_fd_sc_hd__conb_1 T0 (.HI(hibit), .LO(lobit));

  wire ctl_r;
  sky130_fd_sc_hd__dfbbp_1 D0 (.Q(ctl_r), .Q_N(), .CLK(clkgate_i), .D(ctl_i), .RESET_B(async_reset_neg_i), .SET_B(async_set_neg_i));
  wire ctl_en;
  sky130_fd_sc_hd__nand2_1 N0 (.Y(ctl_en), .A(clkdly_i), .B(ctl_r));

  wire fb;
  sky130_fd_sc_hd__nand2_1 N1 (.Y(fb), .A(clkfb_i), .B(hibit));
  wire clk;
  sky130_fd_sc_hd__nand2_1 N2 (.Y(clk), .A(fb), .B(ctl_en));

  assign #50ps clk_o = clk;

endmodule
""")

print("""
module bsg_rp_clk_gen_osc_v3_col
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input clkfb_i
   , input [{num_rows_p}-1:0] ctl_one_hot_i
   , output clk_o
   );

  wire lobit, hibit;
  sky130_fd_sc_hd__conb_1 T0 (.HI(hibit), .LO(lobit));

  // Size to 1/4 of column load
  wire clkgate_inv;
  sky130_fd_sc_hd__inv_1 I0 (.Y(clkgate_inv), .A(clkgate_i));

  wire clkdly_inv;
  sky130_fd_sc_hd__inv_1 I1 (.Y(clkdly_inv), .A(clkdly_i));

  wire async_reset_neg;
  sky130_fd_sc_hd__inv_1 I2 (.Y(async_reset_neg), .A(async_reset_i));

  wire [{num_rows_p}:0] clkfb;
  assign clkfb[0] = clkfb_i;

  wire [{num_rows_p}-1:0] async_reset_neg_li, async_set_neg_li;
""".format(num_rows_p=num_rows_p))

for i in range(0, num_rows_p):
  if i == 0:
    print("""
      assign async_reset_neg_li[{i}] = hibit;
      assign async_set_neg_li[{i}]   = async_reset_neg;
    """.format(i=i))
  else:
    print("""
      assign async_reset_neg_li[{i}] = async_reset_neg;
      assign async_set_neg_li[{i}]   = hibit;
    """.format(i=i))

  print("""
      bsg_rp_clk_gen_osc_v3_row row_{i}_BSG_DONT_TOUCH
        (.async_reset_neg_i(async_reset_neg_li[{i}])
         ,.async_set_neg_i(async_set_neg_li[{i}])
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[{i}])
         ,.ctl_i(ctl_one_hot_i[{i}])
         ,.clk_o(clkfb[{ip1}])
         );
""".format(i=i, ip1=i+1))

print("""
  assign clk_o = clkfb[{num_rows_p}];

endmodule
""".format(num_rows_p=num_rows_p))


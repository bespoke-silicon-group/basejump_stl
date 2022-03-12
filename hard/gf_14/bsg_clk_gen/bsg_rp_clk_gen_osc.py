
from __future__ import print_function
import sys

num_rows_p = int(sys.argv[1])
num_cols_p = int(sys.argv[2])
num_dly_p  = int(sys.argv[3])

print("""
// ## AUTOGENERATED; DO NOT MODIFY
// ## num_rows_p = {num_rows_p}
// ## num_cols_p = {num_cols_p}
// ## num_dly_p = {num_dly_p}
""".format(num_rows_p=num_rows_p, num_cols_p=num_cols_p, num_dly_p=num_dly_p))

print("""
module bsg_rp_clk_gen_osc_row_first
 (input    async_reset_i
  , input  clkgate_i
  , input  clkdly_i
  , input  ctl_i
  , output clk_o
  );

  wire ctl_r;
  SC7P5T_DFFSQX2_SSC14SL D0 (.Q(ctl_r), .CLK(clkgate_i), .D(ctl_i), .SET(async_reset_i));

  wire ctl_en;
  SC7P5T_CKND2X2_SSC14SL N0 (.Z(ctl_en), .CLK(clkdly_i), .EN(ctl_r));

  wire hibit;
  SC7P5T_TIEHIX2_SSC14SL T0 (.Z(hibit));
  wire lobit;
  SC7P5T_TIELOX2_SSC14SL T1 (.Z(lobit));

  wire fb;
  SC7P5T_CKND2X2_SSC14SL N1 (.Z(fb), .CLK(lobit), .EN(hibit));
  SC7P5T_CKND2X2_SSC14SL N2 (.Z(clk_o), .CLK(fb), .EN(ctl_en));

endmodule
""")


print("""
module bsg_rp_clk_gen_osc_row
 (input    async_reset_i
  , input  clkgate_i
  , input  clkdly_i
  , input  clkfb_i
  , input  ctl_i
  , output clk_o
  );

  wire ctl_r;
  SC7P5T_DFFRQX2_SSC14SL D0 (.Q(ctl_r), .CLK(clkgate_i), .D(ctl_i), .RESET(async_reset_i));

  wire ctl_en;
  SC7P5T_CKND2X2_SSC14SL N0 (.Z(ctl_en), .CLK(clkdly_i), .EN(ctl_r));

  wire hibit;
  SC7P5T_TIEHIX2_SSC14SL T0 (.Z(hibit));

  wire fb;
  SC7P5T_CKND2X2_SSC14SL N1 (.Z(fb), .CLK(clkfb_i), .EN(hibit));
  SC7P5T_CKND2X2_SSC14SL N2 (.Z(clk_o), .CLK(fb), .EN(ctl_en));

endmodule
""")

print("""
module bsg_rp_clk_gen_osc_column_first
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input [{num_rows_p_m1}:0] ctl_one_hot_i
   , output clk_o
   );

  wire clkgate_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(clkgate_inv), .CLK(clkgate_i));

  wire clkdly_inv;
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clkdly_inv), .CLK(clkdly_i));

  wire async_reset_neg;
  SC7P5T_CKINVX8_SSC14SL I2 (.Z(async_reset_neg), .CLK(async_reset_i));

  wire [{num_rows_p}:1] clkfb;
  bsg_rp_clk_gen_osc_row_first row_0
    (.async_reset_i(async_reset_neg)
     ,.clkgate_i(clkgate_inv)
     ,.clkdly_i(clkdly_inv)
     ,.ctl_i(ctl_one_hot_i[0])
     ,.clk_o(clkfb[1])
     );
""".format(num_rows_p=num_rows_p, num_rows_p_m1=num_rows_p-1))

for i in range(1, num_rows_p):
    print("""
      bsg_rp_clk_gen_osc_row row_{i}
        (.async_reset_i(async_reset_neg)
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

print("""
module bsg_rp_clk_gen_osc_column
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input clkfb_i
   , input [{num_rows_p_m1}:0] ctl_one_hot_i
   , output clk_o
   );

  wire clkgate_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(clkgate_inv), .CLK(clkgate_i));

  wire clkdly_inv;
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clkdly_inv), .CLK(clkdly_i));

  wire async_reset_neg;
  SC7P5T_CKINVX8_SSC14SL I2 (.Z(async_reset_neg), .CLK(async_reset_i));

  wire [{num_rows_p}:0] clkfb;
  assign clkfb[0] = clkfb_i;
""".format(num_rows_p=num_rows_p, num_rows_p_m1=num_rows_p-1))

for i in range(0, num_rows_p):
    print("""
      bsg_rp_clk_gen_osc_row row_{i}
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[{i}])
         ,.ctl_i(ctl_one_hot_i[{i}])
         ,.clk_o(clkfb[{ip1}])
         );
""".format(i=i,ip1=i+1))

print("""
  assign clk_o = clkfb[{num_rows_p}];

endmodule
""".format(num_rows_p=num_rows_p))

print("""
module bsg_rp_clk_gen_osc
  (input async_reset_i
   , input trigger_i
   , input [{ctl_width_p_m1}:0] ctl_one_hot_i
   , output clk_o
   );

  wire lobit;
  SC7P5T_TIELOX2_SSC14SL T0 (.Z(lobit));

  wire fb, fb_dly, fb_rst;
  SC7P5T_CKND2X2_SSC14SL N0 (.Z(fb_rst), .CLK(fb), .EN(async_reset_i));

  wire [{num_dly_p}:0] n;
  assign n[0] = fb_rst;
""".format(ctl_width_p_m1=num_cols_p*num_rows_p-1, num_dly_p=num_dly_p))

for i in range(0, num_dly_p):
    print("""
    SC7P5T_CKBUFX2_SSC14SL B{i} (.Z(n[{ip1}]), .CLK(n[{i}]));
""".format(i=i, ip1=i+1))

print("""
  assign fb_dly = n[{num_dly_p}];

  wire fb_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(fb_inv), .CLK(fb_dly));
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clk_o ), .CLK(fb_dly));

  wire gate_en_sync_r;
  SC7P5T_SYNC2SDFFQX2_SSC14SL S0 (.D(trigger_i), .CLK(fb_inv), .SI(lobit), .SE(lobit), .Q(gate_en_sync_r));

  wire fb_gated;
  SC7P5T_CKGPRELATNX24_SSC14SL CG0 (.Z(fb_gated), .CLK(fb_inv), .E(gate_en_sync_r), .TE(lobit));

  wire [{num_cols_p}:1] fb_col;
  bsg_rp_clk_gen_osc_column_first col_0
   (.async_reset_i(async_reset_i)
    ,.clkgate_i(fb_gated)
    ,.clkdly_i(fb_dly)
    ,.ctl_one_hot_i(ctl_one_hot_i[{num_rows_p_m1}:0])
    ,.clk_o(fb_col[1])
    );
""".format(num_rows_p=num_rows_p, num_cols_p=num_cols_p, num_dly_p=num_dly_p, num_rows_p_m1=num_rows_p-1))

for i in range(1, num_cols_p):
    print("""
      bsg_rp_clk_gen_osc_column col_{i}
       (.async_reset_i(async_reset_i)
        ,.clkgate_i(fb_gated)
        ,.clkdly_i(fb_dly)
        ,.clkfb_i(fb_col[{i}])
        ,.ctl_one_hot_i(ctl_one_hot_i[{ip1_num_rows_p}:{i_num_rows_p}])
        ,.clk_o(fb_col[{ip1}])
        );
""".format(num_rows_p=num_rows_p, num_cols_p=num_cols_p, i=i, ip1=i+1, i_num_rows_p=i*num_rows_p, ip1_num_rows_p=(i+1)*num_rows_p-1, num_rows_p_m1=num_rows_p-1))

print("""
  assign fb = fb_col[{num_cols_p}];

endmodule
""".format(num_cols_p=num_cols_p))


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
  SC7P5T_TIEHIX2_SSC14SL T1 (.Z(lobit));

  wire fb;
  SC7P5T_CKND2X2_SSC14SL N1 (.Z(fb), .CLK(lobit), .EN(hibit));
  SC7P5T_CKND2X2_SSC14SL N2 (.Z(clk_o), .CLK(fb), .EN(ctl_en));

endmodule


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


module bsg_rp_clk_gen_osc_column_first
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input [3:0] ctl_one_hot_i
   , output clk_o
   );

  wire clkgate_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(clkgate_inv), .CLK(clkgate_i));

  wire clkdly_inv;
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clkdly_inv), .CLK(clkdly_i));

  wire async_reset_neg;
  SC7P5T_CKINVX8_SSC14SL I2 (.Z(async_reset_neg), .CLK(async_reset_i));

  wire [4:1] clkfb;
  bsg_rp_clk_gen_osc_row_first row_0
    (.async_reset_i(async_reset_neg)
     ,.clkgate_i(clkgate_inv)
     ,.clkdly_i(clkdly_inv)
     ,.ctl_i(ctl_one_hot_i[0])
     ,.clk_o(clkfb[1])
     );


      bsg_rp_clk_gen_osc_row row_1
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[1])
         ,.ctl_i(ctl_one_hot_i[1])
         ,.clk_o(clkfb[2])
         );


      bsg_rp_clk_gen_osc_row row_2
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[2])
         ,.ctl_i(ctl_one_hot_i[2])
         ,.clk_o(clkfb[3])
         );


      bsg_rp_clk_gen_osc_row row_3
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[3])
         ,.ctl_i(ctl_one_hot_i[3])
         ,.clk_o(clkfb[4])
         );


  assign clk_o = clkfb[4];

endmodule


module bsg_rp_clk_gen_osc_column
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input clkfb_i
   , input [3:0] ctl_one_hot_i
   , output clk_o
   );

  wire clkgate_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(clkgate_inv), .CLK(clkgate_i));

  wire clkdly_inv;
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clkdly_inv), .CLK(clkdly_i));

  wire async_reset_neg;
  SC7P5T_CKINVX8_SSC14SL I2 (.Z(async_reset_neg), .CLK(async_reset_i));

  wire [4:0] clkfb;
  assign clkfb[0] = clkfb_i;


      bsg_rp_clk_gen_osc_row row_0
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[0])
         ,.ctl_i(ctl_one_hot_i[0])
         ,.clk_o(clkfb[1])
         );


      bsg_rp_clk_gen_osc_row row_1
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[1])
         ,.ctl_i(ctl_one_hot_i[1])
         ,.clk_o(clkfb[2])
         );


      bsg_rp_clk_gen_osc_row row_2
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[2])
         ,.ctl_i(ctl_one_hot_i[2])
         ,.clk_o(clkfb[3])
         );


      bsg_rp_clk_gen_osc_row row_3
        (.async_reset_i(async_reset_neg)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[3])
         ,.ctl_i(ctl_one_hot_i[3])
         ,.clk_o(clkfb[4])
         );


  assign clk_o = clkfb[4];

endmodule


module bsg_rp_clk_gen_osc
  (input async_reset_i
   , input trigger_i
   , input [7:0] ctl_one_hot_i
   , output clk_o
   );

  wire lobit;
  SC7P5T_TIELOX2_SSC14SL T0 (.Z(lobit));

  wire fb, fb_dly, fb_rst;
  SC7P5T_CKND2X2_SSC14SL N0 (.Z(fb_rst), .CLK(fb), .EN(async_reset_i));

  wire [3:0] n;
  assign n[0] = fb_rst;


    SC7P5T_CKBUFX2_SSC14SL B0 (.Z(n[1]), .CLK(n[0]));


    SC7P5T_CKBUFX2_SSC14SL B1 (.Z(n[2]), .CLK(n[1]));


    SC7P5T_CKBUFX2_SSC14SL B2 (.Z(n[3]), .CLK(n[2]));


  assign fb_dly = n[3];

  wire fb_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(fb_inv), .CLK(fb_dly));
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clk_o ), .CLK(fb_dly));

  wire gate_en_sync_r;
  SC7P5T_SYNC2SDFFQX2_SSC14SL S0 (.D(trigger_i), .CLK(fb_inv), .SI(lobit), .SE(lobit), .Q(gate_en_sync_r));

  wire fb_gated;
  SC7P5T_CKGPRELATNX24_SSC14SL CG0 (.Z(fb_gated), .CLK(fb_inv), .E(gate_en_sync_r), .TE(lobit));

  wire [2:1] fb_col;
  bsg_rp_clk_gen_osc_column_first col_0
   (.async_reset_i(async_reset_i)
    ,.clkgate_i(fb_gated)
    ,.clkdly_i(fb_dly)
    ,.ctl_one_hot_i(ctl_one_hot_i[3:0])
    ,.clk_o(fb_col[1])
    );


      bsg_rp_clk_gen_osc_column col_1
       (.async_reset_i(async_reset_i)
        ,.clkgate_i(fb_gated)
        ,.clkdly_i(fb_dly)
        ,.clkfb_i(fb_col[1])
        ,.ctl_one_hot_i(ctl_one_hot_i[7:4])
        ,.clk_o(fb_col[2])
        );


  assign fb = fb_col[2];

endmodule


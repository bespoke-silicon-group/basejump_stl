
module bsg_rp_clk_gen_osc_row
 (input          async_reset_i
  , input        clkgate_i
  , input        clkdly_i
  , input        clkfb_i
  , input        ctl_i
  , output logic clk_o
  );

  wire ctl_r;
  SC7P5T_DFFNRQX1_SSC14SLD0 (.Q(ctl_r), .CLK(clkgate_i), .D(ctl_i), .RESET(async_reset_i);

  wire ctl_en;
  SC7P5T_CKND2X1_SSC14SL N0 (.Z(ctl_en), .CLK(clkdly_i), EN(ctl_r));

  wire hibit;
  SC7P5T_TIEHIX1_SSC14SL T0 (.Z(hibit));

  wire fb;
  SC7P5T_CKND2X1_SSC14SL N1 (.Z(fb), .CLK(clk_fb_i), EN(hibit));
  SC7P5T_CKND2X1_SSC14SL N2 (.Z(clk_o), .CLK(fb), EN(ctl_en));

endmodule


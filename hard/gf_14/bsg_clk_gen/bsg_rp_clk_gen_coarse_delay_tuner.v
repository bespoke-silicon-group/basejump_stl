module bsg_rp_clk_gen_coarse_delay_tuner
  ( input i
  
  , input [1:0] sel_i
  , input       we_i
  , input       async_reset_neg_i

  , output o
  , output we_o
  
  );
  
  wire [1:0] sel_r;
  wire [7:0] signal;
  wire [1:0] mux_lo;
  
// synopsys rp_group (bsg_clk_gen_cde)
// synopsys rp_fill (0 0 RX)
  
  SC7P5T_CKINVX2_SSC14SL I1  ( .CLK(i)        , .Z(signal[0]) );
  SC7P5T_CKINVX2_SSC14SL I2  ( .CLK(signal[0]), .Z(signal[1]) );
  SC7P5T_CKINVX10_SSC14SL I2a ( .CLK(signal[1]), .Z()          );

  SC7P5T_CKINVX2_SSC14SL I3  ( .CLK(signal[1]), .Z(signal[2]) );
  SC7P5T_CKINVX2_SSC14SL I4  ( .CLK(signal[2]), .Z(signal[3]) );
  SC7P5T_CKINVX10_SSC14SL I4a ( .CLK(signal[3]), .Z()          );

  SC7P5T_CKINVX2_SSC14SL I5  ( .CLK(signal[3]), .Z(signal[4]) );
  SC7P5T_CKINVX2_SSC14SL I6  ( .CLK(signal[4]), .Z(signal[5]) );
  SC7P5T_CKINVX10_SSC14SL I6a ( .CLK(signal[5]), .Z()          );

  SC7P5T_CKINVX2_SSC14SL I7  ( .CLK(signal[5]), .Z(signal[6]) );
  SC7P5T_CKINVX2_SSC14SL I8  ( .CLK(signal[6]), .Z(signal[7]) );
  
// synopsys rp_fill (0 1 RX)
  
  SC7P5T_MUXI4X4_SSC14SL M1 ( .D0(signal[5]), .D1(signal[3]), .D2(signal[1]), .D3(i), .S0(sel_r[0]), .S1(sel_r[1]), .Z(o) );
  
// synopsys rp_fill (0 2 RX)
  
  SC7P5T_DFFNRQX4_SSC14SL sel_r_reg_0 ( .D(mux_lo[0]), .CLK(o), .RESET(async_reset_neg_i), .Q(sel_r[0]) );

  SC7P5T_MUX2X1_SSC14SL MX1 ( .D0(sel_r[0]), .D1(sel_i[0]), .S(we_i), .Z(mux_lo[0]) );
  
// synopsys rp_fill (0 3 RX)

  SC7P5T_DFFNRQX4_SSC14SL sel_r_reg_1 ( .D(mux_lo[1]), .CLK(o), .RESET(async_reset_neg_i), .Q(sel_r[1]) );

  SC7P5T_MUX2X1_SSC14SL MX2 ( .D0(sel_r[1]),.D1(sel_i[1]),.S(we_i), .Z(mux_lo[1]) );
  
// synopsys rp_fill (0 4 RX)
  SC7P5T_BUFX4_SSC14SL we_o_buf ( .A(we_i), .Z(we_o) );
  
// synopsys rp_endgroup (bsg_clk_gen_cde)

endmodule

module bsg_rp_clk_gen_fine_delay_tuner
  ( input       i
  , input       we_i
  , input       async_reset_neg_i
  , input [1:0] sel_i

  , output o
  , output buf_o
  
  );

  wire [1:0] sel_r;
  wire [1:0] mux_lo;
  wire [3:0] ft;
  wire       i_inv;
  
  // if wen, capture the select line shortly after a transition
  // from 1 to 0 of the input i
  
  // synopsys rp_group (bsg_clk_gen_fdt)
  // synopsys rp_fill (0 0 UX)
  
  // synopsys rp_fill (0 0 UX)
  
  // synopsys rp_orient ({N FS} I2_1)
  SC7P5T_CKINVX3_SSC14SL I2_1 ( .CLK(ft[1]), .Z() );
  // synopsys rp_orient ({N FS} I3_1)
  SC7P5T_CKINVX3_SSC14SL I3_1 ( .CLK(ft[2]), .Z() );
  // synopsys rp_orient ({N FS} I3_2)
  SC7P5T_CKINVX3_SSC14SL I3_2 ( .CLK(ft[2]), .Z() );
  // synopsys rp_orient ({N FS} I4_1)
  SC7P5T_CKINVX3_SSC14SL I4_1 ( .CLK(ft[3]), .Z() );
  // synopsys rp_orient ({N FS} I4_2)
  SC7P5T_CKINVX3_SSC14SL I4_2 ( .CLK(ft[3]), .Z() );
  // synopsys rp_orient ({N FS} I4_3)
  SC7P5T_CKINVX3_SSC14SL I4_3 ( .CLK(ft[3]), .Z() );
  
  // same driver with different caps and thus different transition times
  // synopsys rp_fill (1 0 UX)
  SC7P5T_CKINVX4_SSC14SL I0 ( .CLK(i)    , .Z(i_inv) );     // decouple load of FDT from previous stage; also makes this inverting
  SC7P5T_CKINVX2_SSC14SL I1 ( .CLK(i_inv), .Z(ft[0]) );
  SC7P5T_CKINVX2_SSC14SL I2 ( .CLK(i_inv), .Z(ft[1]) );
  SC7P5T_CKINVX2_SSC14SL I3 ( .CLK(i_inv), .Z(ft[2]) );
  SC7P5T_CKINVX2_SSC14SL I4 ( .CLK(i_inv), .Z(ft[3]) );
  
  // flops catch on positive edge of inverted clock
  
  // synopsys rp_fill (2 0 UX)
  SC7P5T_MUX2X1_SSC14SL X1 ( .D0(sel_r[0]), .D1(sel_i[0]), .S(we_i), .Z(mux_lo[0]) );

  SC7P5T_DFFRQX4_SSC14SL DFFR1 ( .D(mux_lo[0]), .CLK(o), .Q(sel_r[0]), .RESET(async_reset_neg_i) );
  
  
  SC7P5T_MUXI4X4_SSC14SL M2 ( .D0(ft[3]), .D1(ft[2]), .D2(ft[1]), .D3(ft[0]), .S0(sel_r[0]), .S1(sel_r[1]), .Z(o) );
  
  // capture on positive edge
  SC7P5T_DFFRQX4_SSC14SL DFFR2 ( .D(mux_lo[1]), .CLK(o), .Q(sel_r[1]), .RESET(async_reset_neg_i) );

  SC7P5T_MUX2X1_SSC14SL MX2 ( .D0(sel_r [1]), .D1(sel_i[1]), .S(we_i), .Z(mux_lo[1]) );
  
  // synopsys rp_fill (3 2 UX)
  
  SC7P5T_CKBUFX8_SSC14SL ICLK ( .CLK(o), .Z(buf_o) );
  
  // synopsys rp_endgroup(bsg_clk_gen_fdt)

endmodule

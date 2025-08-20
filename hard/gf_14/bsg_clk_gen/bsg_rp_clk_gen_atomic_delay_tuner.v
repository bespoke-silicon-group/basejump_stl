module bsg_rp_clk_gen_atomic_delay_tuner
  ( input   i
            
  , input   sel_i
  , input   we_async_i
  , input   we_inited_i


  , input   async_reset_neg_i
  , output  we_o
  , output  o
  );

  wire [ 1:0] sel_r;
  wire [13:0] signal;
  wire        we_o_pre_buf;
  wire        zero_bit;
  wire        mux_lo;
  wire        we_i_sync, we_i_sync_sync, we_i_sync_sync_nand;

// synopsys rp_group (bsg_clk_gen_cde)

// synopsys rp_fill (13 2 LX)

  wire n1, n2, n3, n4;

  SC7P5T_CKINVX2_SSC14SL I11  ( .CLK(i),  .Z(n1) );
  SC7P5T_CKINVX2_SSC14SL I12  ( .CLK(n1), .Z(signal[0]) );
  SC7P5T_CKINVX8_SSC14SL I12a ( .CLK(n1), .Z( ));
  SC7P5T_CKINVX8_SSC14SL I12b ( .CLK(n1), .Z( ));

  SC7P5T_CKINVX2_SSC14SL I21  ( .CLK(signal[0]),  .Z(n2) );
  SC7P5T_CKINVX2_SSC14SL I22  ( .CLK(n2),         .Z(signal[1]) );
  SC7P5T_CKINVX8_SSC14SL I22a ( .CLK(n2),         .Z( ));
  SC7P5T_CKINVX8_SSC14SL I22b ( .CLK(n2),         .Z( ));

  SC7P5T_CKINVX2_SSC14SL I31  ( .CLK(signal[1]),  .Z(n3) );
  SC7P5T_CKINVX2_SSC14SL I32  ( .CLK(n3),         .Z(signal[2]) );
  SC7P5T_CKINVX8_SSC14SL I32a ( .CLK(n3),         .Z( ));
  SC7P5T_CKINVX8_SSC14SL I32b ( .CLK(n3),         .Z( ));

  SC7P5T_CKINVX2_SSC14SL I41  ( .CLK(signal[2]),  .Z(n4) );
  SC7P5T_CKINVX2_SSC14SL I42  ( .CLK(n4),         .Z(signal[3]) );
  SC7P5T_CKINVX8_SSC14SL I42a ( .CLK(n4),         .Z( ));
  SC7P5T_CKINVX8_SSC14SL I42b ( .CLK(n4),         .Z( ));

// synopsys rp_fill (0 1 RX)

  SC7P5T_MUXI4X4_SSC14SL M1 ( .D0(signal[3]), .D1(signal[2]), .D2(zero_bit), .D3(signal[0]), .S0(sel_r[0]), .S1(sel_r[1]), .Z(o) );

// synopsys rp_fill (0 0 RX)

  // this gate picks input 01 when async reset is low, initializing the oscillator
  SC7P5T_TIELOX2_SSC14SL ZB ( .Z(zero_bit) );

  SC7P5T_ND2IAX2_SSC14SL NB ( .A(sel_r[0]), .B(async_reset_neg_i), .Z(sel_r[1]) );

  SC7P5T_DFFRQX4_SSC14SL sel_r_reg_0 ( .D(mux_lo), .CLK(o), .RESET(async_reset_neg_i), .Q(sel_r[0]) );

  // 40nm: non-inverting mux 32.5ps + load S->Z
  // 40nm: inverting     mux 43ps + load  S->ZN
  // inputs are reversed because select is inverted
  // we_i&we_inited_i=1 -> new value  (I0)
  // we_i&we_inited-i=0 -> use value in register (I1)
  SC7P5T_MUX2X1_SSC14SL MX1 ( .D0(sel_i), .D1(sel_r[0]), .S(we_i_sync_sync_nand), .Z(mux_lo) );

  // nand 10ps versus 22ps
  SC7P5T_ND2X1_SSC14SL bsg_we_nand ( .A(we_i_sync_sync), .B(we_inited_i), .Z(we_i_sync_sync_nand) );

  // synchronizer flops; negative edge triggered
  SC7P5T_DFFNQX1_SSC14SL bsg_SYNC_2_r ( .D(we_i_sync) , .CLK(o), .Q(we_i_sync_sync) );
  SC7P5T_DFFNQX1_SSC14SL bsg_SYNC_1_r ( .D(we_async_i), .CLK(o), .Q(we_i_sync) );

  // drive we signal to next CDT; minimize capacitive load on critical we_i path
  SC7P5T_INVX0P5_SSC14SL we_o_pre ( .A(we_i_sync_sync_nand), .Z(we_o_pre_buf) );
  SC7P5T_BUFX4_SSC14SL   we_o_buf ( .A(we_o_pre_buf)       , .Z(we_o)         );

// synopsys rp_endgroup (bsg_clk_gen_cde)

endmodule

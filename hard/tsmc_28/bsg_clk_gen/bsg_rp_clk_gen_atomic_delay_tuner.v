// bsg_rp_clk_gen_coarse_delay_element
//
// o       contains controllably delayed signal
//
// module bsg_clk_gen_coarse_delay_element #(parameter `BSG_INV_PARAM(start_tap_p))
//
// DWP 10/6/2021: Ported from TSMC40 to TSMC28 by reusing cells and appending 7T40P140 for the specific cell lib

module bsg_rp_clk_gen_atomic_delay_tuner
  (input i

   , input  sel_i
   , input  we_async_i
   , input  we_inited_i  // basically says we_async_i should have successfully passed through
                         // the generated clock's synchronizers; i.e. the generated clock is
                         // running and the bsg_tag_slave and client have been initialized
   , input async_reset_neg_i
   , output we_o
   , output o
   );

   wire [1:0] sel_r;
   wire [8:0] signal;
   wire       we_o_pre_buf;

   assign signal[0] = i;

   // synopsys rp_group (bsg_clk_gen_adt)
   // synopsys rp_fill (13 2 LX)

   CKND2BWP7T40P140 I1  (.I(signal[0]), .ZN(signal[1]) );
   CKND2BWP7T40P140 I2  (.I(signal[1]), .ZN(signal[2]) );
   CKND4BWP7T40P140 I2a (.I(signal[1]), .ZN()          );

   CKND2BWP7T40P140 I3  (.I(signal[2]), .ZN(signal[3]) );
   CKND2BWP7T40P140 I4  (.I(signal[3]), .ZN(signal[4]) );
   CKND4BWP7T40P140 I4a (.I(signal[3]), .ZN()          );
   CKND2BWP7T40P140 I4b (.I(signal[3]), .ZN()          ); // this is an extra gate because
                                                        // we are not attaching to the mux
                                                        // cap tries to match that of mux input
   CKND2BWP7T40P140 I5  (.I(signal[4]), .ZN(signal[5]) );
   CKND2BWP7T40P140 I6  (.I(signal[5]), .ZN(signal[6]) );
   CKND4BWP7T40P140 I6a (.I(signal[5]), .ZN()          );

   CKND2BWP7T40P140 I7  (.I(signal[6]), .ZN(signal[7]) );
   CKND2BWP7T40P140 I8  (.I(signal[7]), .ZN(signal[8]) );

   CKND4BWP7T40P140 I8a (.I(signal[7]), .ZN()          );
   CKND3BWP7T40P140 I8b (.I(signal[7]), .ZN()          ); // fudge factor capacitance

   // synopsys rp_fill (0 1 RX)

   wire       zero_bit;


   MUX4ND4BWP7T40P140 M1 ( .I0(signal[8])
                        ,.I1(signal[6])
                        ,.I2(zero_bit)
                        ,.I3(signal[0])

                        ,.S0(sel_r[0])
                        ,.S1(sel_r[1])
                        ,.ZN(o   )
                         );

   wire [1:0] mux_lo;
   wire       we_i_sync, we_i_sync_sync, we_i_sync_sync_nand;

   // synopsys rp_fill (0 0 RX)

   // this gate picks input 01 when async reset is low, initializing the oscillator
   IND2D2BWP7T40P140 NB (.A1(sel_r[0]), .B1(async_reset_neg_i), .ZN(sel_r[1]));
   TIELBWP7T40P140   ZB (.ZN(zero_bit));

   DFCND4BWP7T40P140 sel_r_reg_0 (.D(mux_lo[0]), .CP(o)      ,.CDN(async_reset_neg_i), .Q(sel_r[0]), .QN());
   //LHCND4BWP7T40P140 sel_r_latch_0 (.D(mux_lo[0]), .E(o)      ,.CDN(async_reset_neg_i), .Q(sel_r[0]), .QN());

   // 40nm: non-inverting mux 32.5ps + load S->Z
   // 40nm: inverting     mux 43ps + load  S->ZN
   // inputs are reversed because select is inverted
   // we_i&we_inited_i=1 -> new value  (I0)
   // we_i&we_inited-i=0 -> use value in register (I1)
   MUX2D1BWP7T40P140 MX1          ( .I0(sel_i), .I1(sel_r[0]), .S(we_i_sync_sync_nand), .Z(mux_lo[0]));

   // nand 10ps versus 22ps
   ND2D1BWP7T40P140 bsg_we_nand   (.A1(we_i_sync_sync), .A2(we_inited_i), .ZN(we_i_sync_sync_nand));
   // synchronizer flops; negative edge triggered
   //DFND1BWP7T40P140 bsg_SYNC_2_r  (.D(we_i_sync), .CPN(o), .Q(we_i_sync_sync), .QN());
   //DFND1BWP7T40P140 bsg_SYNC_1_r  (.D(we_async_i),     .CPN(o), .Q(we_i_sync),      .QN());
   DFNCND1BWP7T40P140 bsg_SYNC_2_r  (.D(we_i_sync),  .CPN(o), .CDN(async_reset_neg_i), .Q(we_i_sync_sync), .QN());
   DFNCND1BWP7T40P140 bsg_SYNC_1_r  (.D(we_async_i), .CPN(o), .CDN(async_reset_neg_i), .Q(we_i_sync),      .QN());
   // drive we signal to next CDT; minimize capacitive load on critical we_i path
   INVD0BWP7T40P140 we_o_pre      (.I(we_i_sync_sync_nand), .ZN(we_o_pre_buf));
   BUFFD4BWP7T40P140 we_o_buf     (.I(we_o_pre_buf),. Z(we_o));

   // synopsys rp_endgroup (bsg_clk_gen_adt)

endmodule

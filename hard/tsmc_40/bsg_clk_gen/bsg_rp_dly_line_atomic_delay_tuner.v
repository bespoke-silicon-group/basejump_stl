// bsg_rp_clk_gen_coarse_delay_element
//
// o       contains controllably delayed signal
//
// module bsg_clk_gen_coarse_delay_element #(parameter `BSG_INV_PARAM(start_tap_p))
//

module bsg_rp_dly_line_atomic_delay_tuner
  (input i

   , input  sel_i
   , input  we_i
   , input async_reset_neg_i
   , output we_o
   , output o
   );

   wire [1:0] sel_r;
   wire [8:0] signal;
   wire       we_o_pre_buf;

   INVD4BWP i_inv (.I(i), .ZN(signal[0]));

   // synopsys rp_group (bsg_clk_gen_adt)
   // synopsys rp_fill (13 2 LX)

   CKND2BWP I1  (.I(signal[0]), .ZN(signal[1]) );
   CKND2BWP I2  (.I(signal[1]), .ZN(signal[2]) );
   CKND4BWP I2a (.I(signal[1]), .ZN()          );

   CKND2BWP I3  (.I(signal[2]), .ZN(signal[3]) );
   CKND2BWP I4  (.I(signal[3]), .ZN(signal[4]) );
   CKND4BWP I4a (.I(signal[3]), .ZN()          );
   CKND2BWP I4b (.I(signal[3]), .ZN()          ); // this is an extra gate because
                                                 // we are not attaching to the mux
                                                 // cap tries to match that of mux input
   CKND2BWP I5  (.I(signal[4]), .ZN(signal[5]) );
   CKND2BWP I6  (.I(signal[5]), .ZN(signal[6]) );
   CKND4BWP I6a (.I(signal[5]), .ZN()          );

   CKND2BWP I7  (.I(signal[6]), .ZN(signal[7]) );
   CKND2BWP I8  (.I(signal[7]), .ZN(signal[8]) );

   CKND4BWP I8a (.I(signal[7]), .ZN()          );
   CKND3BWP I8b (.I(signal[7]), .ZN()          ); // fudge factor capacitance

   // synopsys rp_fill (0 1 RX)

   wire       zero_bit;


   MUX4ND4BWP M1 ( .I0(signal[8])
                  ,.I1(signal[6])
                  ,.I2(zero_bit)
                  ,.I3(signal[0])

                  ,.S0(sel_r[0])
                  ,.S1(sel_r[1])
                  ,.ZN(o   )
                   );

   // synopsys rp_fill (0 0 RX)

   // this gate picks input 01 when async reset is low, initializing the oscillator
   IND2D2BWP NB (.A1(sel_r[0]), .B1(async_reset_neg_i), .ZN(sel_r[1]));
   TIELBWP   ZB (.ZN(zero_bit));

   DFCND4BWP sel_r_reg_0 (.D(sel_i[0]), .CP(we_i)      ,.CDN(async_reset_neg_i), .Q(sel_r[0]), .QN());
   //LHCND4BWP sel_r_latch_0 (.D(mux_lo[0]), .E(o)      ,.CDN(async_reset_neg_i), .Q(sel_r[0]), .QN());

   // drive we signal to next CDT; minimize capacitive load on critical we_i path
   BUFFD0BWP we_o_pre     (.I(we_i), .Z(we_o_pre_buf));
   BUFFD4BWP we_o_buf     (.I(we_o_pre_buf),. Z(we_o));

   // synopsys rp_endgroup (bsg_clk_gen_adt)

endmodule

`BSG_ABSTRACT_MODULE(bsg_rp_dly_line_atomic_delay_tuner)

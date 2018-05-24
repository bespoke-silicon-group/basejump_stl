// bsg_rp_clk_gen_coarse_delay_element
//
// (o       is inverting on even start_tap_p
//  worst_o is non-inverting)
//
// o       contains controllably delayed signal
// worst_o contains worst-case   delayed signal (for delay matching)
//
//
// we use sed to substitute parameters because the netlist reader
// does not like them, and we need the netlist reader for rp_groups
//
// module bsg_clk_gen_coarse_delay_element #(parameter start_tap_p="inv")
//

module bsg_rp_clk_gen_atomic_delay_tuner
  (input i

   , input  sel_i
   , input  we_i
   , input async_reset_neg_i
   , output       o
   );

   wire [1:0] sel_r;
   wire [8:0] signal;

   assign signal[0] = i;

   // synopsys rp_group (bsg_clk_gen_cde)
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

   wire [1:0] mux_lo;

   // synopsys rp_fill (0 0 RX)

   // this gate picks input 01 when async reset is low, initializing the oscillator
   IND2D2BWP NB        (.A1(sel_r[0]), .B1(async_reset_neg_i), .ZN(sel_r[1]));
   TIELBWP  ZB (.ZN(zero_bit));

   wire       sel_r_0_inv, sel_i_inv;

   DFCND4BWP sel_r_reg_0 (.D(mux_lo[0]), .CP(o)      ,.CDN(async_reset_neg_i), .Q(sel_r[0]), .QN(sel_r_0_inv));

   CKND2BWP I_MX      (.I(sel_i), .ZN(sel_i_inv));

   // we invert both inputs of this mux to optimize the select-to-output path by 40 ps
   MUX2ND1BWP MX1         (.I0(sel_r_0_inv) , .I1(sel_i_inv)   ,.S(we_i), .ZN(mux_lo[0]));

   // synopsys rp_endgroup (bsg_clk_gen_cde)

endmodule

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

module bsg_rp_clk_gen_coarse_delay_tuner
  (input i

   , input  [1:0] sel_i
   , input  we_i
   , input async_reset_neg_i
   , output       o
   , output we_o
   );

   wire [1:0] sel_r;
   wire [8:0] signal;

   assign signal[0] = i;

   // synopsys rp_group (bsg_clk_gen_cdt)
   // synopsys rp_fill (0 0 RX)

   CKND2BWP I1  (.I(signal[0]), .ZN(signal[1]) );
   CKND2BWP I2  (.I(signal[1]), .ZN(signal[2]) );
   CKND4BWP I2a (.I(signal[1]), .ZN()          );

   CKND2BWP I3  (.I(signal[2]), .ZN(signal[3]) );
   CKND2BWP I4  (.I(signal[3]), .ZN(signal[4]) );
   CKND4BWP I4a (.I(signal[3]), .ZN()          );

   CKND2BWP I5  (.I(signal[4]), .ZN(signal[5]) );
   CKND2BWP I6  (.I(signal[5]), .ZN(signal[6]) );
   CKND4BWP I6a (.I(signal[5]), .ZN()          );

   CKND2BWP I7  (.I(signal[6]), .ZN(signal[7]) );
   CKND2BWP I8  (.I(signal[7]), .ZN(signal[8]) );

   // synopsys rp_fill (0 1 RX)

   MUX4ND4BWP M1 ( .I0(signal[6])       // start_tap_p + 6
                  ,.I1(signal[4])       // start_tap_p + 4
                  ,.I2(signal[2])       // start_tap_p + 2
                  ,.I3(signal[0])       // start_tap_p + 0

                  ,.S0(sel_r[0])
                  ,.S1(sel_r[1])
                  ,.ZN (o   )
                   );

   wire [1:0] mux_lo;

   // synopsys rp_fill (0 2 RX)

   DFNCND4BWP sel_r_reg_0 (.D(mux_lo[0]), .CPN(o), .CDN(async_reset_neg_i), .Q(sel_r[0]), .QN());
   MUX2D1BWP MX1 (.I0(sel_r[0]),.I1(sel_i[0]),.S(we_i), .Z(mux_lo[0]));

   // synopsys rp_fill (0 3 RX)

   DFNCND4BWP sel_r_reg_1 (.D(mux_lo[1]), .CPN(o), .CDN(async_reset_neg_i), .Q(sel_r[1]), .QN());
   MUX2D1BWP MX2 (.I0(sel_r[1]),.I1(sel_i[1]),.S(we_i), .Z(mux_lo[1]));

   // synopsys rp_fill (0 4 RX)
   BUFFD4BWP we_o_buf (.I(we_i), .Z(we_o));

   // synopsys rp_endgroup (bsg_clk_gen_cdt)

endmodule

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
   );

   wire [1:0] sel_r;
   wire [8:0] signal;

   assign signal[0] = i;

   // synopsys rp_group (bsg_clk_gen_cdt)
   // synopsys rp_fill (0 0 RX)

   CLKINVX2 I1  (.A(signal[0]), .Y(signal[1]) );
   CLKINVX2 I2  (.A(signal[1]), .Y(signal[2]) );
   CLKINVX4 I2a (.A(signal[1]), .Y()          );

   CLKINVX2 I3  (.A(signal[2]), .Y(signal[3]) );
   CLKINVX2 I4  (.A(signal[3]), .Y(signal[4]) );
   CLKINVX4 I4a (.A(signal[3]), .Y()          );

   CLKINVX2 I5  (.A(signal[4]), .Y(signal[5]) );
   CLKINVX2 I6  (.A(signal[5]), .Y(signal[6]) );
   CLKINVX4 I6a (.A(signal[5]), .Y()          );

   CLKINVX2 I7  (.A(signal[6]), .Y(signal[7]) );
   CLKINVX2 I8  (.A(signal[7]), .Y(signal[8]) );

   // synopsys rp_fill (0 1 RX)

   MXI4X4 M1 ( .A(signal[6])       // start_tap_p + 6
              ,.B(signal[4])       // start_tap_p + 4
              ,.C(signal[2])       // start_tap_p + 2
              ,.D(signal[0])       // start_tap_p + 0

              ,.S0(sel_r[0])
              ,.S1(sel_r[1])
              ,.Y (o   )
               );

   wire [1:0] mux_lo;

   // synopsys rp_fill (0 2 RX)

   DFFNRX4 sel_r_reg_0 (.D(mux_lo[0]), .CKN(o), .RN(async_reset_neg_i), .Q(sel_r[0]), .QN());
   MX2X1 MX1 (.A(sel_r[0]),.B(sel_i[0]),.S0(we_i), .Y(mux_lo[0]));

   // synopsys rp_fill (0 3 RX)

   DFFNRX4 sel_r_reg_1 (.D(mux_lo[1]), .CKN(o), .RN(async_reset_neg_i), .Q(sel_r[1]), .QN());
   MX2X1 MX2 (.A(sel_r[1]),.B(sel_i[1]),.S0(we_i), .Y(mux_lo[1]));

   // synopsys rp_endgroup (bsg_clk_gen_cdt)

endmodule

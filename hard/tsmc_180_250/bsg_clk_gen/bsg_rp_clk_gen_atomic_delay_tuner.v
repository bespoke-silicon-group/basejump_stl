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

   // synopsys rp_group (bsg_clk_gen_adt)
   // synopsys rp_fill (13 2 LX)

   CLKINVX2 I1  (.A(signal[0]), .Y(signal[1]) );
   CLKINVX2 I2  (.A(signal[1]), .Y(signal[2]) );
   CLKINVX4 I2a (.A(signal[1]), .Y()          );

   CLKINVX2 I3  (.A(signal[2]), .Y(signal[3]) );
   CLKINVX2 I4  (.A(signal[3]), .Y(signal[4]) );
   CLKINVX4 I4a (.A(signal[3]), .Y()          );
   CLKINVX2 I4b (.A(signal[3]), .Y()          ); // this is an extra gate because
                                                 // we are not attaching to the mux
                                                 // cap tries to match that of mux input
   CLKINVX2 I5  (.A(signal[4]), .Y(signal[5]) );
   CLKINVX2 I6  (.A(signal[5]), .Y(signal[6]) );
   CLKINVX4 I6a (.A(signal[5]), .Y()          );

   CLKINVX2 I7  (.A(signal[6]), .Y(signal[7]) );
   CLKINVX2 I8  (.A(signal[7]), .Y(signal[8]) );

   CLKINVX4 I8a (.A(signal[7]), .Y()          );
   CLKINVX3 I8b (.A(signal[7]), .Y()          ); // fudge factor capacitance

   // synopsys rp_fill (0 1 RX)

   wire       zero_bit;


   MXI4X4 M1 ( .A(signal[8])
              ,.B(signal[6])
              ,.C(zero_bit)
              ,.D(signal[0])

              ,.S0(sel_r[0])
              ,.S1(sel_r[1])
              ,.Y (o   )
               );

   wire [1:0] mux_lo;

   // synopsys rp_fill (0 0 RX)

   // this gate picks input 01 when async reset is low, initializing the oscillator
   NAND2BX2 NB        (.AN(sel_r[0]), .B(async_reset_neg_i), .Y(sel_r[1]));
   TIELO  ZB (.Y(zero_bit));

   wire       sel_r_0_inv, sel_i_inv;

   DFFRX4 sel_r_reg_0 (.D(mux_lo[0]), .CK(o)      ,.RN(async_reset_neg_i), .Q(sel_r[0]), .QN(sel_r_0_inv));

   CLKINVX2 I_MX      (.A(sel_i), .Y(sel_i_inv));

   // we invert both inputs of this mux to optimize the select-to-output path by 40 ps
   MXI2X1 MX1         (.A(sel_r_0_inv) , .B(sel_i_inv)   ,.S0(we_i), .Y(mux_lo[0]));

   // synopsys rp_endgroup (bsg_clk_gen_adt)

endmodule

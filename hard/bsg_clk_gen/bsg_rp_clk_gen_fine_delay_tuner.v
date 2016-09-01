
// bsg_rp_clk_gen_fine_delay_tuner
// fine-tuned sub-gate granularity of delay tuning
//
// o is delayed signal, non-inverted
//

module bsg_rp_clk_gen_fine_delay_tuner
  (input i
   , input we_i
   , input async_reset_neg_i
   , input [1:0] sel_i
   , output o
   , output buf_o
   );

   wire [1:0] sel_r;
   wire [1:0] mux_lo;

   // if wen, capture the select line shortly after a transition
   // from 1 to 0 of the input i

   // synopsys rp_group (bsg_clk_gen_fdt)
   // synopsys rp_fill (0 0 UX)

   wire [3:0] ft;

   // synopsys rp_fill (0 0 UX)

   // synopsys rp_orient ({N FS} I2_1)
   CLKINVX12 I2_1 (.A(ft[1]),.Y());                                   // Cap= 1 * 0.0098 pF
   // synopsys rp_orient ({N FS} I3_1)
   CLKINVX12 I3_1 (.A(ft[2]),.Y());
   // synopsys rp_orient ({N FS} I3_2)
   CLKINVX12 I3_2 (.A(ft[2]),.Y());                                   // Cap= 2 * 0.0098 pF
   // synopsys rp_orient ({N FS} I4_1)
   CLKINVX12 I4_1 (.A(ft[3]),.Y());
   // synopsys rp_orient ({N FS} I4_2)
   CLKINVX12 I4_2 (.A(ft[3]),.Y());
   // synopsys rp_orient ({N FS} I4_3)
   CLKINVX12 I4_3 (.A(ft[3]),.Y()); // Cap= 3 * 0.0098 pF

   // same driver with different caps and thus different transition times
   // synopsys rp_fill (1 0 UX)
   CLKINVX2 I1 (.A(i), .Y(ft[0]));
   CLKINVX2 I2 (.A(i), .Y(ft[1]));
   CLKINVX2 I3 (.A(i), .Y(ft[2]));
   CLKINVX2 I4 (.A(i), .Y(ft[3]));

   // synopsys rp_fill (2 0 UX)
   MX2X1   MX1    (.A(sel_r [0]),.B  (sel_i[0]), .S0(we_i)    ,.Y(mux_lo[0]         ));
   DFFRX4 DFFR1 (.D(mux_lo[0]),.CK(o), .Q (sel_r[0]), .QN(), .RN(async_reset_neg_i));

   wire       tune_lo;
   MXI4X4 M2 (.A(ft[3]), .B(ft[2]), .C(ft[1]), .D(ft[0])
              ,.S0(sel_r[0]), .S1(sel_r[1])
              ,.Y(tune_lo)
              );

   DFFRX4 DFFR2 (.D(mux_lo[1]),.CK(o), .Q (sel_r[1]), .QN(), .RN(async_reset_neg_i));
   MX2X1   MX2    (.A(sel_r [1]),.B  (sel_i[1]), .S0(we_i)    ,.Y(mux_lo[1]         ));

   // synopsys rp_fill (3 2 UX)

   CLKBUFX8 ICLK (.A(o),        .Y(buf_o)                     );

   // MBT FIXME: in reset condition, tune_lo will be a 1 and
   // the async reset signal will be a 0.

   // when the async reset signal goes low, then the output
   // will be a posedge of the clk. async resets must not
   // change in a narrow window around the clk edge.
   // for a balanced reset tree, this would not be a problem
   // but a safer approach would be to hold this signal high
   // rather than low during reset

   AND2X4 A1      (.A(tune_lo),  .B(async_reset_neg_i), .Y(o)  );

   // synopsys rp_endgroup(bsg_clk_gen_fdt)

endmodule


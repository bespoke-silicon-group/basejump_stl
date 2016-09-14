
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
   , output buf_btc_o
   );

   wire [1:0] sel_r;
   wire [1:0] mux_lo;

   // if wen, capture the select line shortly after a transition
   // from 1 to 0 of the input i

   // synopsys rp_group (bsg_clk_gen_fdt)
   // synopsys rp_fill (0 0 UX)

   wire [3:0] ft;
   wire       i_inv;

   // synopsys rp_fill (0 0 UX)

   // synopsys rp_orient ({N FS} I2_1)
   CLKINVX3 I2_1 (.A(ft[1]),.Y());
   // synopsys rp_orient ({N FS} I3_1)
   CLKINVX3 I3_1 (.A(ft[2]),.Y());
   // synopsys rp_orient ({N FS} I3_2)
   CLKINVX4 I3_2 (.A(ft[2]),.Y());
   // synopsys rp_orient ({N FS} I4_1)
   CLKINVX3 I4_1 (.A(ft[3]),.Y());
   // synopsys rp_orient ({N FS} I4_2)
   CLKINVX4 I4_2 (.A(ft[3]),.Y());
   // synopsys rp_orient ({N FS} I4_3)
   CLKINVX4 I4_3 (.A(ft[3]),.Y());

   // same driver with different caps and thus different transition times
   // synopsys rp_fill (1 0 UX)
   CLKINVX4 I0 (.A(i), .Y(i_inv));     // decouple load of FDT from previous stage; also makes this inverting
   CLKINVX2 I1 (.A(i_inv), .Y(ft[0]));
   CLKINVX2 I2 (.A(i_inv), .Y(ft[1]));
   CLKINVX2 I3 (.A(i_inv), .Y(ft[2]));
   CLKINVX2 I4 (.A(i_inv), .Y(ft[3]));

   // flops catch on positive edge of inverted clock

   // synopsys rp_fill (2 0 UX)
   MX2X1   MX1    (.A(sel_r [0]),.B  (sel_i[0]), .S0(we_i)    ,.Y(mux_lo[0]         ));
   DFFRX4 DFFR1 (.D(mux_lo[0]),.CK(o), .Q (sel_r[0]), .QN(), .RN(async_reset_neg_i));

   MXI4X4 M2 (.A(ft[3]), .B(ft[2]), .C(ft[1]), .D(ft[0])
              ,.S0(sel_r[0]), .S1(sel_r[1])
              ,.Y(o)
              );

   // capture on positive edge
   DFFRX4 DFFR2 (.D(mux_lo[1]),.CK(o), .Q (sel_r[1]), .QN(), .RN(async_reset_neg_i));
   MX2X1   MX2    (.A(sel_r [1]),.B  (sel_i[1]), .S0(we_i)    ,.Y(mux_lo[1]         ));

   // synopsys rp_fill (3 2 UX)

   CLKBUFX8 ICLK (.A(o),        .Y(buf_o) );

   // to clock the btc client, we use the pre-FDT clock
   // our goal is to have the btc_client send on the positive edge
   // of the clock, and the ADT/FDT/CDT capture on the negative edge
   // of the clock. However the delay through the BTC is much more
   // significant, so we get a headstart on sending that clock out.

   CLKBUFX8 BTCCLK (.A(i_inv),       .Y(buf_btc_o) );
   // synopsys rp_endgroup(bsg_clk_gen_fdt)

endmodule


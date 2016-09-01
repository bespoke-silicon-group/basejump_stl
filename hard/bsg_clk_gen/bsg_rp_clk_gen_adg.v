
// bsg_clk_gen_adg
//
// o is non-inverted
//

module bsg_rp_clk_gen_adg
  (input i
   , input we_i
   , input sel_i
   , input async_reset_neg_i
   , output o

   , input slow_i
   , output slow_o
   );

   wire sel_r, sel_r_inv;
   wire clk_int_inv;
   wire mux_lo;

   wire                  net_fast_li;

   // synopsys rp_group (bsg_clk_gen_adg)
   // synopsys rp_fill  (0 0 UX)

   // see the documentation on Atomic Delay Gadgets
   // to understand the magic behind this flip flop
   // which enables atomic switch-over.
   // the basic idea is to transition
   //

   // on we_i captures sel_i shortly after input i
   // transitions from high to low, and so the output of both
   // "and gates" is 0.

   MX2X1   MX1 (.A(sel_r),  .B  (sel_i)     , .S0(we_i), .Y (mux_lo   ));
   DFFNRX4 DFF1 (.D(mux_lo), .CKN(clk_int_inv), .RN(async_reset_neg_i), .Q(sel_r), .QN(sel_r_inv));

   // demultiplex signal into two paths: fast and slow

   AND2X4 A1(.A(i), .B(sel_r_inv), .Y(slow_o));

   // synopsys rp_fill  (1 2 UX)
   // reconverge fast and slow paths

   NOR2X4 N5   (.A(net_fast_li), .B(slow_i), .Y(clk_int_inv));

   // synopsys rp_fill  (2 2 UX)
   // buffer this up; next stage has high load
   CLKINVX2 I7 (.A(clk_int_inv)                        , .Y(o          ));

      // synopsys rp_fill  (3 2 UX)
   AND2X4 A2(.A(i), .B(sel_r),     .Y(net_fast_li));

   // synopsys rp_fill  (0 3 UX)
   wire [2:0] unused_lo;

   // fast path; sole purpose of this is to load the
   // signal net_fast_li

   MXI4X4 M1(. A(net_fast_li)
             ,.B(net_fast_li)
             ,.C(net_fast_li)
             ,.D(net_fast_li)
             ,.S0(1'b0)
             ,.S1(1'b0)
             ,.Y(unused_lo[0]) // unused
             );

   MXI4X4 M2(. A(net_fast_li)
             ,.B(net_fast_li)
             ,.C() // unused
             ,.D() // unused
             ,.S0(1'b0)
             ,.S1(1'b0)
             ,.Y(unused_lo[1]) // unused
             );

   // synopsys rp_endgroup (bsg_clk_gen_adg)

endmodule

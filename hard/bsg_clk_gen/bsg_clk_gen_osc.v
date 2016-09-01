// bsg_clk_gen_osc
//
// the parameters adg_i, cdt_i, and fdt_i
// are latched shortly after their input goes from 1->0
// if we_i is set. typically, we would setup the inputs
// a few cycles a head of time, and then assert the enable.
//
// the clocking of enable is tricky.
//
// note: quality of circuit depends on how
//       edge-and-delay balanced the MXI4 is.
//

`include "bsg_clk_gen.vh"

module bsg_clk_gen_osc
   import bsg_tag_pkg::bsg_tag_s;
 #(parameter num_adgs_p=2)
  (
   input bsg_tag_s bsg_tag_i

   ,input                  async_reset_i
   ,output                 clk_o
   );

   wire       fb_clk;     // internal clock
   wire       async_reset_neg = ~async_reset_i;

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   wire       fb_we_r;

   // note: oscillator has to be already working in order
   // for configuration state to pass through here

   bsg_tag_client #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
                    ,.default_p(0)
                    ) btc
     (.bsg_tag_i     (bsg_tag_i)
      ,.recv_clk_i   (fb_clk)
      ,.recv_reset_i (1'b0)     // no default value is loaded;
      ,.recv_new_r_o (fb_we_r)  // default is already in OSC flops
      ,.recv_data_r_o(fb_tag_r)
      );

   wire [num_adgs_p-1+1:0] adg_int;

   // instantatiate CDT (coarse delay tuner)
   // this one inverts the output

   bsg_clk_gen_coarse_delay_tuner cdt
   (.i                 (fb_clk)
    ,.we_i             (fb_we_r         )
    ,.async_reset_neg_i(async_reset_neg )
    ,.sel_i            (fb_tag_r.cdt    )

    // goes on to ADG
    ,.o                (adg_int[0]      )

    );

   genvar      i,j;

   // instantatiate ADG's (atomic delay gadgets)
   // non-inverting

   for (i = 0; i < num_adgs_p; i=i+1)
     begin : adg_gen
        wire slow_lo, slow_li;

        // lengths of adg's multiply up exponentially
        bsg_rp_clk_gen_adg
          adg
            (.i                 (adg_int [i]      )
             ,.we_i             (fb_we_r          )
             ,.sel_i            (fb_tag_r.adg[i]  )
             ,.async_reset_neg_i(async_reset_neg  )
             ,.o                (adg_int [i+1]    )

             // to allow this to be a rp_group, we
             // route out to the variable part
             ,.slow_i(slow_li)
             ,.slow_o(slow_lo)
             );

        wire [(1 << i)-1+1:0] net_slow;

        // chain together CDG to make a delay circuit; non-inverting
        for (j = 0; j < 1 << i; j=j+1)
          begin: delay
             // slow path
             bsg_rp_clk_gen_coarse_delay_element_8_6_4_2 cdt //  #(.start_tap_p(2))
                 (.i       (net_slow[j]  )
                  ,.worst_o(net_slow[j+1])

                  ,.sel_i(2'b00)
                  ,.o() // unused
                  );
          end

        assign net_slow[0] = slow_lo;
        assign slow_li = net_slow[1<<i];
     end

   // instantiate FDT (fine delay tuner)
   // non-inverting

   bsg_rp_clk_gen_fine_delay_tuner fdt
     (.i                 (adg_int[num_adgs_p])
      ,.we_i             (fb_we_r        )
      ,.async_reset_neg_i(async_reset_neg)
      ,.sel_i            (fb_tag_r.fdt   )
      ,.o                (fb_clk)
      ,.buf_o            (clk_o)
      );

   //always @(*)
   //  $display("%m async_reset_neg=%b fb_clk=%b adg_int=%b fb_tag_r=%b fb_we_r=%b",
   //           async_reset_neg,fb_clk,adg_int,fb_tag_r,fb_we_r);

endmodule // bsg_clk_gen_osc

module bsg_clk_gen_coarse_delay_tuner
  (input i
   , input [1:0] sel_i
   , input we_i
   , input async_reset_neg_i
   , output o
   );

   wire worst_lo;
   wire [1:0] sel_r;
   wire [1:0] mux_lo;

   // if wen, capture the select line shortly after a transition
   // from 1 to 0 of the input i

   // for this, CLK->delay should be greater than the MX4 in the coarse delay element

   bsg_rp_tsmc_250_MX2X1_b2 MX12
     // 0 input, 1 input,       select input
   (.i0(sel_r), .i1(sel_i), .i2({ we_i, we_i }), .o(mux_lo));

   // assumes generate string for DFFNRX4 of "#0 (.D (#1), .CKN(#2), .RN(#3), .Q(#4), .QN());"
   bsg_rp_tsmc_250_DFFNRX4_b2 DFFNR12
     (.i0(mux_lo)                                  // D
      ,.i1({worst_lo, worst_lo})                   // CKN
      ,.i2({async_reset_neg_i, async_reset_neg_i}) // RN
      ,.o(sel_r)                                   // Q
      );

//   MX2X1   MX1    (.A(sel_r [0]),.B  (sel_i[0]), .S0(we_i)    ,.Y(mux_lo[0]         ));
//   DFFNRX4 DFFNR1 (.D(mux_lo[0]),.CKN(worst_lo), .RN(async_reset_neg_i), .Q (sel_r[0]),.QN());

//   MX2X1   MX2    (.A(sel_r [1]),.B  (sel_i[1]), .S0(we_i)    ,.Y(mux_lo[1]         ));
//   DFFNRX4 DFFNR2 (.D(mux_lo[1]),.CKN(worst_lo), .RN(async_reset_neg_i), .Q (sel_r[1]),.QN());

   bsg_rp_clk_gen_coarse_delay_element_6_4_2_0 cde // #(.start_tap_p(0))
   (.i     (i    )
    ,.sel_i(sel_r)
    ,.o    (o) // inverted
    ,.worst_o(worst_lo)
    );


   // always @(*)
   //  $display("%m async_reset_neg_i=%b o=%b\n",async_reset_neg_i,o);

endmodule


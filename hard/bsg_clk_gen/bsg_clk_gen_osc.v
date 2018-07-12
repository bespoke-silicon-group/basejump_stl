// bsg_clk_gen_osc
//
// new settings are delivered via bsg_tag_i
//
// the clock is designed to be atomically updated
// between any of its values without glitching.
//
// the order of components is:
//
// ADT, CDT, FDT  --> feedback (and buffer to outside world)
//
// All three stages invert their outputs.
//
// All of the modules have delay circuits that clock their config
// flops right after the signal has passed through. All of them are
// configured to grab the new value after a negedge enters the beginning of
// of the ADT, but of course since the signal is inverted at each stage
// ADT and FDT do it on posege and CDT does it on negedge.
//
// We employ a MUXI4 that is part of the TSMC 250 standard cell library
// that has balanced paths and is glitch-free, because it is based on a
// t-gate design. If the MUXI4 were made out of AND-OR circuits, care
// would have to be taken to make sure that the transitions occur when
// either all inputs are 0 or 1 to the MUXI4, depending on the implementation.
// For example, if the mux is AOI, triggered on negedge edge of input clock would
// be okay. Fortunately, we don't have to worry about this (and confirmed by spice.)
//
// We have verified this in TSMC 250 by running with sdf annotations.
//
// There is an implicit race between the bsg_tag's output fb_we_r (clocked on
// positive edge of FDT output) and these config flops that cannot be addressed
// in ICC because we cannot explicitly control timing between ICC-managed
// clocks and our internal oscillator clocks.
//
// A final check must be made on the 5 flops inside the adt / cdt / fdt
// to see that async reset drops and data inputs do not come too close
// to the appropriate clock edge.  This could be verified via a script that
// processes the SDF file, but for now we pull the test trace up in DVE and
// manually check these points.  Typically, the ADT is the closest
// call, where in MAX timing mode, the data changes about 481 ps before the
// positive edge of the flop's clock. With a setup time on the order of
// 261 ps, there is a slack of 220 ps. This path was originally a problem
// and it fixed by sending the clock out to the BTC at the beginning of
// the FDT as opposed to at the end. This gives more time for propagate
// through the ICC-generate clock tree for the BTC.
//

`include "bsg_clk_gen.vh"

module bsg_clk_gen_osc
   import bsg_tag_pkg::bsg_tag_s;
 #(parameter num_adgs_p=1)
  (
   input async_reset_i
   ,input bsg_tag_s bsg_tag_i
   ,output clk_o
   );

   wire       fb_clk, fb_btc_clk;     // internal clock
   wire       async_reset_neg = ~async_reset_i;

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s fb_tag_r;
   wire       fb_we_r;

   // note: oscillator has to be already working in order
   // for configuration state to pass through here

   bsg_tag_client #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
                    ,.harden_p(1)
                    ,.default_p(0)
                    ) btc
     (.bsg_tag_i     (bsg_tag_i)
      ,.recv_clk_i   (fb_btc_clk)
      ,.recv_reset_i (1'b0)     // no default value is loaded;
      ,.recv_new_r_o (fb_we_r)  // default is already in OSC flops
      ,.recv_data_r_o(fb_tag_r)
      );

   wire adt_lo, cdt_lo;

   wire fb_clk_del;

   // this adds some delay in the loop for RTL simulation
   // should be ignored in synthesis
   assign #4000 fb_clk_del = fb_clk;

   bsg_rp_clk_gen_atomic_delay_tuner  adt
     (.i(fb_clk_del)
      ,.we_i(fb_we_r)
      ,.async_reset_neg_i(async_reset_neg)
      ,.sel_i(fb_tag_r.adg[0])
      ,.o(adt_lo)
      );

   // instantatiate CDT (coarse delay tuner)
   // this one inverts the output
   // captures config state on negative edge of input clock

   bsg_rp_clk_gen_coarse_delay_tuner cdt
     (.i                 (adt_lo)
      ,.we_i             (fb_we_r         )
      ,.async_reset_neg_i(async_reset_neg )
      ,.sel_i            (fb_tag_r.cdt    )
      ,.o                (cdt_lo          )
      );

   // instantiate FDT (fine delay tuner)
   // captures config state on positive edge of (inverted) input clk
   // non-inverting

   bsg_rp_clk_gen_fine_delay_tuner fdt
     (.i                 (cdt_lo)
      ,.we_i             (fb_we_r        )
      ,.async_reset_neg_i(async_reset_neg)
      ,.sel_i            (fb_tag_r.fdt   )
      ,.o                (fb_clk)     // in the actual critical loop
      ,.buf_btc_o        (fb_btc_clk) // inside this module; to the btc
      ,.buf_o            (clk_o)     // outside this module
      );

   //always @(*)
   //  $display("%m async_reset_neg=%b fb_clk=%b adg_int=%b fb_tag_r=%b fb_we_r=%b",
   //           async_reset_neg,fb_clk,adg_int,fb_tag_r,fb_we_r);

endmodule // bsg_clk_gen_osc



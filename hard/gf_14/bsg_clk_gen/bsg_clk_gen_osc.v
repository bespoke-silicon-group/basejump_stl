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
// We employ a MUXI4 that is part of the standard cell library
// that we verify to be glitch-free using spice simulation (presumably because it is based on a
// t-gate design). If the MUXI4 were made out of AND-OR circuits, care
// would have to be taken to make sure that the transitions occur when
// either all inputs are 0 or 1 to the MUXI4, depending on the implementation.
// For example, if the mux is AOI, triggered on negedge edge of input clock would
// be okay. Fortunately, we don't have to worry about this (and confirmed by spice.)
//
// We have verified this in TSMC 40 by running with sdf annotations.
//

// Gen 2 specific info (starting with 40nm)  MBT 5-26-2018
//
// This Gen 2 clock generator has been slight redesigned in order to address the races
// in the gen 1 design that prevented automation.
//
// We use the bsg_tag_client_unsync implementation in order to reduce the load on
// the internally generated clock. Additionally, we separate out the we_r trigger
// signal so that it is explicitly set. This means that to set the frequency
// on average, three packets will need to be sent. First, a packet will be sent
// to set clock configuration bits. Then a packet will be sent to enable the we_r
// signal. Finally a packet will be sent to clear the we_r signal.
// This applies only for the oscillator programming.
//
// The trigger is synchronized inside the ADT; and then the synchronized signal
// is buffered and passed on to the CDT and then to the FDT, mirroring the
// flow of the clock signal through the units.
//
// The goal of this approach is to ensure that a new value is latched into the
// oscillator's configuration registers atomically, and during the first negative
// clock phase after a positive edge.
//
//
// The downsampler uses the normal interface.
//
//
// Gen 1 specific info (for reference)
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
//
//
//

`timescale 1ps/1ps

`include "bsg_clk_gen.vh"

module bsg_clk_gen_osc
   import bsg_tag_pkg::bsg_tag_s;
 #(parameter num_adgs_p=1)
  (
   input bsg_tag_s bsg_tag_i
   ,input bsg_tag_s bsg_tag_trigger_i

   ,input async_reset_i
   ,output clk_o
   );

   wire  fb_clk;
   wire       async_reset_neg = ~async_reset_i;

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)

   bsg_clk_gen_osc_tag_payload_s tag_r_async;
   wire       tag_trigger_r_async;
   wire       adt_to_cdt_trigger_lo, cdt_to_fdt_trigger_lo;

   // this is a raw interface; and wires will toggle
   // as the bits shift in. the wires are also
   // unsynchronized with respect to the target domain.

   bsg_tag_client_unsync
     #(.width_p($bits(bsg_clk_gen_osc_tag_payload_s))
       ,.harden_p(1)
       ) btc
       (.bsg_tag_i(bsg_tag_i)
        ,.data_async_r_o(tag_r_async)
        );

   bsg_tag_client_unsync
     #(.width_p(1)
       ,.harden_p(1)
       ) btc_trigger
       (.bsg_tag_i(bsg_tag_trigger_i)
        ,.data_async_r_o(tag_trigger_r_async)
        );

   wire adt_lo, cdt_lo;

   wire fb_clk_del;

   // this adds some delay in the loop for RTL simulation
   // should be ignored in synthesis
   assign #4000 fb_clk_del = fb_clk;

   bsg_rp_clk_gen_atomic_delay_tuner  adt_DONT_TOUCH
     (.i(fb_clk_del)
      ,.we_async_i (tag_trigger_r_async   )
      ,.we_inited_i(bsg_tag_trigger_i.en  )
      ,.async_reset_neg_i(async_reset_neg )
      ,.sel_i(tag_r_async.adg[0]          )
      ,.we_o(adt_to_cdt_trigger_lo        )
      ,.o(adt_lo                          )
      );

   // instantatiate CDT (coarse delay tuner)
   // this one inverts the output
   // captures config state on negative edge of input clock

   bsg_rp_clk_gen_coarse_delay_tuner cdt_DONT_TOUCH
     (.i                 (adt_lo)
      ,.we_i             (adt_to_cdt_trigger_lo)
      ,.async_reset_neg_i(async_reset_neg      )
      ,.sel_i            (tag_r_async.cdt      )
      ,.we_o             (cdt_to_fdt_trigger_lo)
      ,.o                (cdt_lo)
      );

   // instantiate FDT (fine delay tuner)
   // captures config state on positive edge of (inverted) input clk
   // non-inverting

   bsg_rp_clk_gen_fine_delay_tuner fdt_DONT_TOUCH
     (.i                 (cdt_lo)
      ,.we_i             (cdt_to_fdt_trigger_lo)
      ,.async_reset_neg_i(async_reset_neg)
      ,.sel_i            (tag_r_async.fdt)
      ,.o                (fb_clk)     // in the actual critical loop
      ,.buf_o            (clk_o)     // outside this module
      );

   //always @(*)
   //  $display("%m async_reset_neg=%b fb_clk=%b adg_int=%b fb_tag_r=%b fb_we_r=%b",
   //           async_reset_neg,fb_clk,adg_int,fb_tag_r,fb_we_r);

endmodule // bsg_clk_gen_osc



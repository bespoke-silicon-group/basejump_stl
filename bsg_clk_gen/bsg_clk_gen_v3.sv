// This is the toplevel module for the clock generator. The clock generator
// internally contains a bsg_tag node, a ring oscillator, and a clock
// downsampler as well as a external clock pass through. The ring oscillator
// also has its own bsg_tag node.

// To select between
// the ring oscillator, the downsampled ring oscillator and the external
// pass-through clock use the 2-bit select_i signal.
//
// Here are the two bsg_tag payloads for this module:
//
// 1. downsampler
//
// n..1: <n-bit downsampler value>
// 0..0: <1-bit posedge reset value>
//
// all 0's is the fastest setting, and sampling increases as the counter is incremented
//
// 2. oscillator
// n..0: active taps - control speed of oscillator
//
// all 0's is the slowest setting, and delay decreases as you increment the counter
//

`include "bsg_defines.sv"

`include "bsg_clk_gen.svh"

module bsg_clk_gen_v3
  import bsg_tag_pkg::bsg_tag_s;
 #(parameter `BSG_INV_PARAM(downsample_width_p )
  ,          num_taps_p         = 4
  )
  (input  bsg_tag_s         bsg_osc_tag_i
  ,input  bsg_tag_s         bsg_osc_trigger_tag_i
  ,input  bsg_tag_s         bsg_ds_tag_i
  ,input                    async_osc_reset_i

  ,input                    ext_clk_i
  ,input  [1:0]             select_i
  ,output logic             clk_o
  );

   localparam debug_level_lp = 0;

   logic osc_clk_out;                // oscillator output clock
   logic ds_clk_out;                 // downsampled output clock

  // Clock Generator (CG) Instance
  //

   bsg_clk_gen_osc_v3 #(.num_taps_p(num_taps_p)) clk_gen_osc_inst
    (.bsg_tag_i(bsg_osc_tag_i)
     ,.bsg_tag_trigger_i(bsg_osc_trigger_tag_i)
     ,.async_reset_i(async_osc_reset_i)
     ,.clk_o(osc_clk_out)
     );

   `declare_bsg_clk_gen_ds_tag_payload_s(downsample_width_p);

   bsg_clk_gen_ds_tag_payload_s ds_tag_payload_r;

   wire  ds_tag_payload_new_r;

   // fixme: maybe wire up a default and deal with reset issue?
   // downsampler bsg_tag interface
   bsg_tag_client #(.width_p($bits(bsg_clk_gen_ds_tag_payload_s))
                    ,.harden_p(1)
                    ) btc_ds
     (.bsg_tag_i(bsg_ds_tag_i)

      ,.recv_clk_i   (osc_clk_out)
      ,.recv_new_r_o (ds_tag_payload_new_r)     // we don't require notification
      ,.recv_data_r_o(ds_tag_payload_r)
      );

   if (debug_level_lp > 1)
   always @(negedge osc_clk_out)
     if (ds_tag_payload_new_r)
       $display("## bsg_clk_gen downsampler received configuration state: %b",ds_tag_payload_r);

  // clock downsampler
  //
  // we allow the clock downsample reset to be accessed via bsg_tag; this way
  // we can turn it off by holding reset high to save power.
  //

  bsg_counter_clock_downsample #(.width_p(downsample_width_p),. harden_p(1)) clk_gen_ds_inst
    (.clk_i(osc_clk_out)
    ,.reset_i(ds_tag_payload_r.reset)
    ,.val_i  (ds_tag_payload_r.val  )
    ,.clk_r_o(ds_clk_out      )
    );

  // edge balanced mux for selecting the clocks

  bsg_mux #(.width_p(1)
            ,.els_p(4)
            ,.balanced_p(1)
            ,.harden_p(1)
            ) mux_inst

    // mux pins are A B D C
    // probably wise to locate ds_clk_out and osc_clk_out
    // apart from each other
    (.data_i ({  1'b0, ext_clk_i, ds_clk_out, osc_clk_out })
     ,.sel_i (select_i)
     ,.data_o(clk_o)
     );

endmodule

`BSG_ABSTRACT_MODULE(bsg_clk_gen_v3)


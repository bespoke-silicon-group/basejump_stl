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
//
// 4+n .. 4: ADG ctrl - control speed of n ADG stages
//   3 .. 2: CDT ctrl - control speed of CDT stage
//   1 .. 0: FDT ctrl - control speed of FDT stage
//
// all 0's is the slowest setting, and delay decreases as you increment the counter
//
// PREFERRED BOOTUP SEQUENCE (assuming the bypass external clock is not used)
//
// 1. reset the bsg_tag_master
//
//    a. reset the bsg_tag_master
//        - send a 1 on bsg_tag and then a stream of 0's to reset the bsg_tag_master
//        - check bsg_tag.vh for a macro that says how many 0's to send
//
//
// 2. foreach bsg_clk_gen
//    a. program the oscillator
//
//      1. reset the oscillator's bsg_tag_client
//           - send a reset packet (data_not_reset) to the oscillator's bsg_tag_client using bsg_tag
//      2. reset the oscillator's internal registers
//           - assert the async_osc_reset_i to force the oscillator's internal registers to its lowest frequency setting
//           - deassert the async_osc_reset_i, which will cause the oscillator to start oscillating
//      3. program the oscillator using bsg_tag
//           - send a data_not_reset packet to the client via bsg_tag
//
//    b. program the downsampler (should be done after step 2)
//
//      1. reset the downsampler's bsg_tag_client
//         - send a reset packet (data_not_reset) to the downsampler's bsg_tag_client using bsg_tag
//      2. reset and deactiveate the downsampler
//         - send a packet to the downsampler's bsg_tag_client with low bit set to 1
//      3. optionally, activate the downsampler
//         - send a packet to program the downsampler with a new value and set low bit to 0, ending reset
//
// 3. make use of the stable clocks
//
// DEADBUG MODE
//
// 1. Apply voltage to all voltage domains (I/O, Core, and possibly Clock)
//    - (Oscillator probably will be oscillating at a random frequency
// 2. Apply brief voltage to async_osc_reset_i
//    - (Oscillator will now be oscillating at lowest frequency
// 3. Should be able to probe pin to see something (maybe very noisy because not 50 ohm terminated)
//

`include "bsg_clk_gen.vh"

module bsg_clk_gen
  import bsg_tag_pkg::bsg_tag_s;
 #(parameter downsample_width_p = "inv"
  ,          num_adgs_p         = 2
  )
  (input  bsg_tag_s         bsg_osc_tag_i
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
  bsg_clk_gen_osc #(.num_adgs_p(num_adgs_p))  clk_gen_osc_inst
    (
     .bsg_tag_i          (bsg_osc_tag_i    )
     ,.async_reset_i     (async_osc_reset_i)
     ,.clk_o             (osc_clk_out      )
    );

   `declare_bsg_clk_gen_ds_tag_payload_s(downsample_width_p)

   bsg_clk_gen_ds_tag_payload_s ds_tag_payload_r;

   wire  ds_tag_payload_new_r;

   // fixme: maybe wire up a default and deal with reset issue?
   // downsampler bsg_tag interface
   bsg_tag_client #(.width_p($bits(bsg_clk_gen_ds_tag_payload_s)),.default_p(0)) btc_ds
     (.bsg_tag_i(bsg_ds_tag_i)

      ,.recv_clk_i   (osc_clk_out)
      ,.recv_reset_i (1'b0) // node must be programmed by bsg tag
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

  bsg_counter_clock_downsample #(.width_p(downsample_width_p)) clk_gen_ds_inst
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

    (.data_i ({  1'b0, ext_clk_i, ds_clk_out, osc_clk_out })
     ,.sel_i (select_i)
     ,.data_o(clk_o)
     );

endmodule


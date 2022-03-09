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
 import bsg_tag_pkg::*;
 #(parameter `BSG_INV_PARAM(num_row_p)
   , parameter `BSG_INV_PARAM(num_col_p)
   )
  (input bsg_tag_s bsg_tag_trigger_i
   , input bsg_tag_s bsg_tag_i
   , input async_reset_i
   , output logic clk_o
   );

  wire fb, n0, n1, n2, fb_dly
  SC7P5T_CKBUFX2_SSC14SL B0 (.Z(n0    ), .CLK(fb));
  SC7P5T_CKBUFX2_SSC14SL B1 (.Z(n1    ), .CLK(n0));
  SC7P5T_CKBUFX2_SSC14SL B2 (.Z(n2    ), .CLK(n1));
  SC7P5T_CKBUFX2_SSC14SL B3 (.Z(fb_dly), .CLK(n2));

  wire fb_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(fb_inv), .CLK(fb_dly));
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clk_o ), .CLK(fb_dly));

  logic gate_en_r;
  bsg_tag_client_unsync #(.width_p(1))
   btc_clkgate
    (.bsg_tag_i(bsg_tag_trigger_i)
     ,.data_async_r_o(gate_en_r)
     );

  logic gate_en_sync_r;
  bsg_sync_sync #(.width_p(1))
   bss
    (.oclk_i(fb_inv)
     ,.iclk_data_i(gate_en_r)
     ,.oclk_data_o(gate_en_sync_r)
     );

  wire lobit;
  SC7P5T_TIELOX1_SSC14SL T0 (.Z(lobit));

  wire fb_gated;
  SC7P5T_CKGPRELATNX24_SSC14SL CG0 (.Z(fb_gated), .CLK(fb_inv), .E(gate_en_sync_r), .TE(lobit));
  
  logic [`BSG_SAFE_CLOG2(num_row_p*num_col_p)-1:0] ctl_r;
  bsg_tag_client_unsync
   #(.width_p(`BSG_SAFE_CLOG2(num_row_p*num_col_p)))
   btc_ctl
    (.bsg_tag_i(bsg_tag_i)
     ,.data_async_r_o(ctl_r)
     );

  logic [num_col_p-1:0][num_row_p-1:0] ctl_one_hot_lo;
  bsg_decode #(.num_out_p(num_col_p*num_row_p)) decode
   (.i(ctl_r)
    ,.o(ctl_one_hot_lo)
    );

  wire [num_col_p:0] fb_col;
  assign fb_col[0] = lobit;
  for (genvar i = 0; i < num_col_p; i++)
    begin : c
      bsg_clk_gen_osc_column #(.num_row_p(num_row_p)) col
       (.async_reset_i(async_reset_i)
        ,.clkgate_i(fb_gated)
        ,.clkdly_i(fb_dly)
        ,.clkfb_i(fb_col[i])
        ,.ctl_one_hot_i(ctl_one_hot_lo[i])
        ,.clk_o(fb_col[i+1])
        );
    end
  assign fb = fb_col[num_col_p];

endmodule



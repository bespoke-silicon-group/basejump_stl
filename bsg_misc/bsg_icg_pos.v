/**
 *    bsg_icg_pos.v
 *  
 *    positive-phase integrated clock gating cell
 *  
 *    For simulation-purpose only. Don't synthesize this module.
 *    Instead use a hardened version of this module for synthesis.
 */

`include "bsg_defines.v"

`BSG_SYNTH_MUST_HARDEN

module bsg_icg_pos
  (
    input clk_i
    , input en_i
    , output clk_o
  );

  logic clk_en_r;

  always_latch
    if (clk_i == 1'b0)
      clk_en_r <= en_i;

  assign clk_o = clk_en_r & clk_i;


endmodule

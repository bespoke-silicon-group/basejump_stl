/**
 *    bsg_icg.v
 *  
 *    integrated clock gating cell
 *  
 *    For simulation-purpose only. Don't synthesize this module.
 *    Instead use a hardened version of this module for synthesis.
 */


`ifndef SYNTHESIS

module bsg_icg 
  (
    input clk_i
    , input en_i
    , output clk_o
  );

  logic clk_en;

  always_latch
    if (clk_i == 1'b0)
      clk_en <= en_i;

  assign clk_o = clk_en & clk_i;


endmodule


`endif

/**
 *    bsg_dff_reset_set_clear.v
 *
 *    Reset has priority over set.
 *    Set has priority over clear (by default).
 *
 */


`include "bsg_defines.v"

module bsg_dff_reset_set_clear
  #(parameter width_p="inv"
    , parameter clear_over_set_p=0 // if 1, clear overrides set.
  )
  (
    input clk_i
    , input reset_i
    , input [width_p-1:0] set_i
    , input [width_p-1:0] clear_i
    , output logic [width_p-1:0] data_o
  );

  logic [width_p-1:0] data_r;

  always_ff @ (posedge clk_i)
    if (reset_i)
      data_r <= '0;
    else
      if (clear_over_set_p)
        data_r <= (data_r | set_i) & (~clear_i);
      else
        data_r <= (data_r & ~clear_i) | set_i;

  assign data_o = data_r;

endmodule

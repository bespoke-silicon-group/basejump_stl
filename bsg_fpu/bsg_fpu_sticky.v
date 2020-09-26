/**
 *  bsg_fpu_sticky.v
 *
 *  @author tommy
 *
 *  It calculates the sticky bit for given input and shift amount.
 *
 *  Sometimes, the mantissa with lower exponent needs to be shifted right to
 *  aligned with the other mantissa. Due to finite precision, the shifted
 *  mantissa loses lower bits by the amount that was shifted. Sticky bit
 *  captures if any one of the lower bits that was shifted out was 1, so that
 *  this could be used for deciding whether to round up or not.
 *
 */

`include "bsg_defines.v"

module bsg_fpu_sticky
  #(parameter width_p="inv")
  (
    input [width_p-1:0] i // input
    , input [`BSG_WIDTH(width_p)-1:0] shamt_i // shift amount
    , output logic sticky_o
  );

  logic [width_p-1:0] scan_out;

  bsg_scan #(
    .width_p(width_p)
    ,.or_p(1)
    ,.lo_to_hi_p(1)
  ) scan0 (
    .i(i)
    ,.o(scan_out)
  );

  // answer
  logic [width_p:0] answer;
  assign answer = {scan_out, 1'b0};

  // final output
  assign sticky_o = shamt_i > width_p
    ? answer[width_p]
    : answer[shamt_i];

endmodule

`include "bsg_defines.v"

module bsg_nonsynth_triwire #
  (parameter width_p="inv"
  ,parameter real transport_delay_p = 0.0)
  (inout [width_p-1:0] a
  ,inout [width_p-1:0] b);

  // This initialization to z is important to prevent the signal from being
  // alway x
  logic [width_p-1:0] a_dly = 'bz;
  logic [width_p-1:0] b_dly = 'bz;

  always@(a) a_dly <= #(transport_delay_p) b_dly==={width_p{1'bz}}? a: 'bz;
  always@(b) b_dly <= #(transport_delay_p) a_dly==={width_p{1'bz}}? b: 'bz;

  assign b = a_dly, a = b_dly;

endmodule

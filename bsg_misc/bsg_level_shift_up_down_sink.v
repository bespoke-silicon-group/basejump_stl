// bsg_level_shift_up_down_sink
//
// This module represents a simple level shifter. In RTL, a level shifter
// is just a wire but when replaced with the hardened standard cell a level
// shifter is used to cross power domains. An up-down level shifter can
// transform a signal to a higher or lower voltage. A sink level shifter
// is designed to be in the same power domain as the signals destination.
//
// Should be swapped with the corresponding hard module in bsg_ip_cores/hard.
//
// Author: Scott Davidson
// Date:   4-4-17
//
`include "bsg_defines.v"

module bsg_level_shift_up_down_sink #(parameter width_p = "inv")
(
  input        [width_p-1:0] v0_data_i,
  input                      v1_en_i,
  output logic [width_p-1:0] v1_data_o
);

  initial
    $display("%m - warning: using non-hard up/down sink-side level shifter");

  // No logic for level shifter in RTL
  assign v1_data_o = v0_data_i & {width_p{v1_en_i}};

endmodule

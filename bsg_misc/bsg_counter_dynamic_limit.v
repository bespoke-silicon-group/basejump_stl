// This module is a counter with dynamic limit that repeats counting
// from zero to overflow value. (it would get limit_i+1 different
// values during this counting).
// module renamed from bsg_counter_w_overflow
`include "bsg_defines.v"

module bsg_counter_dynamic_limit #(parameter width_p = -1)

            ( input                      clk_i
            , input                      reset_i

            , input        [width_p-1:0] limit_i
            , output logic [width_p-1:0] counter_o
            );

always_ff @ (posedge clk_i)
  if (reset_i)
    counter_o <= 0;
  else if (counter_o == limit_i)
    counter_o <= 0;
  else
    counter_o <= counter_o + width_p'(1);

endmodule

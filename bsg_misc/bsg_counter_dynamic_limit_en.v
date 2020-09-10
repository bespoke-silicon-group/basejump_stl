//====================================================================
// bsg_counter_dynamic_limit_en.v
// 02/16/2016, shawnless.xie@gmail.com
//====================================================================
// This module implements simple counter with enable signal and dynamic
// overflow limit.
//
// The counter outputs 0 ~ (limit-1) value
//module renamed from bsg_counter_en_overflow
`include "bsg_defines.v"

module bsg_counter_dynamic_limit_en #(parameter width_p = -1)

            ( input                      clk_i
            , input                      reset_i

            , input                      en_i
            , input        [width_p-1:0] limit_i
            , output logic [width_p-1:0] counter_o
            , output                     overflowed_o
            );


wire [width_p-1:0] counter_plus_1 = counter_o + width_p'(1);
assign             overflowed_o   = ( counter_plus_1 == limit_i );
always_ff @ (posedge clk_i)
  if (reset_i)
    counter_o <= 0;
  else if (en_i) begin
    if(overflowed_o )   counter_o <= 0;
    else                counter_o <= counter_plus_1 ;
  end

endmodule

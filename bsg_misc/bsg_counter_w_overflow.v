// This module is a counter with dynamic limit that repeats counting
// from zero to overflow value. (it would get overflow_i+1 different 
// values during this counting).

module counter_w_overflow #(parameter width_p = -1)

            ( input                      clk
            , input                      reset

            , input        [width_p-1:0] overflow_i
            , output logic [width_p-1:0] counter_o
            );

always_ff @ (posedge clk)
  if (reset)
    counter_o <= 0;
  else if (counter_o == overflow_i)
    counter_o <= 0;
  else
    counter_o <= counter_o + 1;

endmodule

// This counter will counter down from val_i to 0. When the counter
// hits 0, the output clk_r_o will invert. The number of bits wide
// the counter is can be set with the width_p parameter.
//
// Random ideas: could have a variant of this that takes two inputs
// one for the high duty cycle and one for the low duty cycle.
//

`include "bsg_defines.v"

module bsg_counter_clock_downsample #(parameter width_p = "inv", parameter harden_p=0)
    (input                clk_i
    ,input                reset_i
    ,input  [width_p-1:0] val_i
    ,output logic         clk_r_o
    );

   wire strobe_r;

   // asserts a "1" every val_i cycles
   bsg_strobe #(.width_p(width_p), .harden_p(harden_p)) strobe
   (.clk_i
    ,.reset_r_i(reset_i)
    ,.init_val_r_i(val_i)
    ,.strobe_r_o(strobe_r)
    );

   // Clock output register
   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          clk_r_o <= 1'b0;
        else if (strobe_r)
          clk_r_o <= ~clk_r_o;
     end

endmodule

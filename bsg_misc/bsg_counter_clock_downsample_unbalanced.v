// This counter will count down from low_val_i to 0. When the counter
// hits 0, the clock output will go high. Then the counter will count down
// from high_val_i to 0. When the counter hits 0 again, the clock output will
// go low. In this way, we can generate a clock with an an arbitrary duty cycle.
// The number of bits wide the counter is can be set with the width_p parameter.
//

`include "bsg_defines.v"

module bsg_counter_clock_downsample_unbalanced #(parameter `BSG_INV_PARAM(width_p ), harden_p=0)
    (input                clk_i
    ,input                reset_i
    ,input  [width_p-1:0] low_i
    ,input  [width_p-1:0] high_i
    ,output logic         clk_r_o
    );

   wire low_strobe_r;

   // asserts a "1" every val_i cycles
   bsg_strobe #(.width_p(width_p), .harden_p(harden_p)) low_strobe
   (.clk_i
    ,.reset_r_i(reset_i | (~clk_r_o & ~high_strobe_r))
    ,.init_val_r_i(low_i)
    ,.strobe_r_o(low_strobe_r)
    );

  wire high_strobe_r;

   // asserts a "1" every val_i cycles
   bsg_strobe #(.width_p(width_p), .harden_p(harden_p)) high_strobe
   (.clk_i
    ,.reset_r_i(reset_i | (clk_r_o & ~low_strobe_r))
    ,.init_val_r_i(high_i)
    ,.strobe_r_o(high_strobe_r)
    );

   // Clock output register
   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          clk_r_o <= 1'b0;
        else if (high_strobe_r)
          clk_r_o <= 1'b1;
        else if (low_strobe_r)
          clk_r_o <= 1'b0;
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_clock_downsample_unbalanced)


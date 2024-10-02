// This counter will counter down from val_i to 0. When the counter
// hits 0, the output clk_r_o will invert. The number of bits wide
// the counter is can be set with the width_p parameter.
//
// Random ideas: could have a variant of this that takes two inputs
// one for the high duty cycle and one for the low duty cycle.
//

`include "bsg_defines.sv"

module bsg_counter_clock_downsample #(parameter `BSG_INV_PARAM(width_p ), harden_p=0)
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

   wire clk_n, clk_r;

   // Clock output register
   bsg_dff_en #(.width_p(1), .harden_p(harden_p)) d
   (.clk_i
    ,.en_i(strobe_r)
    ,.data_i(clk_n)
    ,.data_o(clk_r)
    );

   // Clock inverter
   bsg_clkinv #(.width_p(1), .harden_p(harden_p)) ci
   (.i(clk_r)
    ,.o(clk_n)
    );

   // Clock buffer
   bsg_clkbuf #(.width_p(1), .harden_p(harden_p)) cb
   (.i(clk_r)
    ,.o(clk_r_o)
    );

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_clock_downsample)

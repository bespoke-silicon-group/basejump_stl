// This counter will counter down from hi_val_i / lo_val_i to 0. When the counter
// hits 0, the output clk_r_o will invert and phase will toggle. The number of bits wide
// the counter is can be set with the width_p parameter.
//

`include "bsg_defines.sv"

module bsg_counter_clock_downsample_unbalanced #(parameter `BSG_INV_PARAM(width_p ), harden_p=0)
    (input                clk_i
    ,input                reset_i
    ,input  [width_p-1:0] hi_val_i
    ,input  [width_p-1:0] lo_val_i
    ,output logic         clk_r_o
    );

   wire [width_p-1:0] strobe_val;
   wire strobe_r;

   // asserts a "1" every strobe cycles
   bsg_strobe #(.width_p(width_p), .harden_p(harden_p)) strobe
   (.clk_i(clk_i)
    ,.reset_r_i(reset_i)
    ,.init_val_r_i(strobe_val)
    ,.strobe_r_o(strobe_r)
    );

   wire clk_n, clk_r;

   // Clock output register
   bsg_dff_reset_en #(.width_p(1), .harden_p(harden_p)) d
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.en_i(strobe_r)
    ,.data_i(clk_n)
    ,.data_o(clk_r)
    );

   // Clock inverter
   bsg_clkinv #(.width_p(1), .harden_p(harden_p)) ci
   (.i(clk_r)
    ,.o(clk_n)
    );

   // Select strobe_val based on phase
   bsg_mux #(.width_p(width_p), .els_p(2), .harden_p(harden_p)) m
   (.data_i({lo_val_i, hi_val_i})
    ,.sel_i(clk_r)
    ,.data_o(strobe_val)
    );

   // Clock buffer
   bsg_clkbuf #(.width_p(1), .harden_p(harden_p)) cb
   (.i(clk_r)
    ,.o(clk_r_o)
    );

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_clock_downsample)

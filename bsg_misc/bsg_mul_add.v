// 21 Jul 2021
// A special module for use with HardFloat's mulAddRecFN for 
// easy absorption of pipeline stages by the DSPs that get
// synthesised in some FPGAs. This helps in retiming the 
// paths in FPGA implementations as only immediate registers 
// are absorbed, and global retiming does not seem to do this.

`include "bsg_defines.v"
  
module bsg_mul_add_unsigned #(
    parameter width_a_p = 4
    ,parameter width_b_p = 4
    ,parameter width_c_p = width_a_p + width_b_p
    ,parameter width_o_p = `BSG_SAFE_CLOG2( ((1 << width_a_p) - 1) * ((1 << width_b_p) - 1) + 
                                                    ((1 << width_c_p)-1) + 1 )
    ,parameter pipeline_p = 0
  ) (
    input clk_i
    ,input [width_a_p-1 : 0] a_i
    ,input [width_b_p-1 : 0] b_i
    ,input [width_c_p-1 : 0] c_i
    ,output [width_o_p-1 : 0] o
    );

    localparam pre_pipeline_lp = 0;
    localparam post_pipeline_lp = pipeline_p;

    wire [width_a_p-1:0] a_r;
    wire [width_b_p-1:0] b_r;
    wire [width_c_p-1:0] c_r;

    bsg_dff_chain #(width_a_p + width_b_p + width_c_p, pre_pipeline_lp)
        pre_mul_add (
            .clk_i(clk_i)
            ,.data_i({a_i, b_i, c_i})
            ,.data_o({a_r, b_r, c_r})
        );

    wire [width_o_p-1:0] o_r = a_r * b_r + c_r;

    bsg_dff_chain #(width_o_p, post_pipeline_lp)
        post_mul_add (
            .clk_i(clk_i)
            ,.data_i(o_r)
            ,.data_o(o)
        );
endmodule

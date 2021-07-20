// A special module for use with HardFloat's mulAddRecFN for 
// easy absorption of pipeline stages by the DSPs that get
// synthesised in some FPGAs. This helps in retiming the 
// paths in FPGA implementations as only immediate registers 
// are absorbed, and global retiming does not seem to do this.

`include "bsg_defines.v"
  
module bsg_mul_add #(
    parameter width_a_p = 4
    ,parameter width_b_p = 4
    ,parameter width_o_p = width_a_p + width_b_p + 1
    ,parameter pipeline_p = 3
  ) (
    input clk_i
    ,input [width_a_p-1 : 0] a_i
    ,input [width_b_p-1 : 0] b_i
    ,input [width_a_p + width_b_p - 1 : 0] c_i
    ,output [width_o_p : 0] o
    );

    `ifdef ZYNQ
      initial assert (pipeline_p > 2) else $error ("pipeline stages may not be enough")
    `endif

    localparam pre_lp = pipeline_p > 2? 1 : 0;
    localparam post_lp = pipeline_p > 2? pipeline_p - 1 : pipeline_p;
    
    wire [width_a_p-1:0] a_r;
    wire [width_b_p-1:0] b_r;
    wire [width_a_p + width_b_p -1 : 0] c_r;
    bsg_dff_chain #($bits(a_r + b_r + c_r), pre_lp)
        pre_mul_add (
            .clk_i(clk_i)
            ,.data_i({a_i, b_i, c_i})
            ,.data_o({a_r, b_r, c_r})
        );
    wire [width_a_p + width_b_p : 0] o_r = a_r * b_r + c_r;
    bsg_dff_chain#($bits(o_r), post_lp)
        post_mul_add (
            .clk_i(clk_i)
            ,.data_i(o_r)
            ,.data_o(o)
        );
endmodule

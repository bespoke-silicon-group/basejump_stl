`timescale 1ps/1ps
/**********************************************
bsg_adder_carry_save_4_2.v
3/16/2019 sqlin@fudan.edu.cn
This is a 4-2 carry save adder used by iterative multiplier ans 4-2 wallace tree.
***********************************************/
module bsg_adder_carry_save_4_2 #(parameter integer width_p = "inv")
(
   input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input [width_p-1:0] opC_i
  ,input [width_p-1:0] opD_i

  ,output [width_p:0] outA_o
  ,output [width_p:0] outB_o
);
  wire [width_p-1:0] fa1_res_lo;
  wire [width_p-1:0] fa1_car_lo;
  bsg_adder_carry_save #(.width_p(width_p))
  fa1
  (
    .opA_i(opA_i)
    ,.opB_i(opB_i)
    ,.opC_i(opC_i)
    ,.res_o(fa1_res_lo)
    ,.car_o(fa1_car_lo)
  );

  bsg_adder_carry_save #(.width_p(width_p + 1))
  fa2
  (
    .opA_i({1'b0,fa1_res_lo})
    ,.opB_i({fa1_car_lo,1'b0})
    ,.opC_i({1'b0,opD_i})
    ,.res_o(outA_o[width_p:0])
    ,.car_o(outB_o[width_p:1])
  );
  assign outB_o[0] = 1'b0;
endmodule
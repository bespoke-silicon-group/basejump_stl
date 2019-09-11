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

  ,output [width_p-1:0] A_o
  ,output [width_p-1:0] B_o
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
  wire [width_p-1:0] fa2_car_o;
  bsg_adder_carry_save #(.width_p(width_p))
  fa2
  (
    .opA_i(fa1_res_lo)
    ,.opB_i({fa1_car_lo[width_p-2:0],1'b0})
    ,.opC_i(opD_i)
    ,.res_o(A_o[width_p-1:0])
    ,.car_o(fa2_car_o)
  );
  assign B_o[width_p-1:1] = fa2_car_o[width_p-2:0];
  assign B_o[0] = 1'b0;
endmodule

/*********************************************************
==========================================================
bsg_adder_carry_save.v
3/14/2019, sqlin16@fudan.edu.cn
==========================================================

A full adder with configurable width.


***********************************************************/


module bsg_adder_carry_save #(parameter width_p = "inv")(
   input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input [width_p-1:0] opC_i

  ,output [width_p-1:0] res_o
  ,output [width_p-1:0] car_o
);
  generate
    for(genvar i = 0; i < width_p; i++) begin : CSA_EACH
      assign {car_o[i], res_o[i]} = opA_i[i] + opB_i[i] + opC_i[i];
    end
  endgenerate
endmodule



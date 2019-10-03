/*********************************************************
==========================================================
bsg_adder_carry_save.v
3/14/2019, sqlin16@fudan.edu.cn
==========================================================

This is a carry-saved adder taking three operands and calculating the result in redundant (sum and carry) format. 
Carry propagation is needed to recover the sum.

***********************************************************/


module bsg_adder_carry_save 
#(
  parameter integer width_p = "inv"
  ,parameter bit designware_enabled_p = 0
)(
   input [width_p-1:0] opA_i
  ,input [width_p-1:0] opB_i
  ,input [width_p-1:0] opC_i

  ,output [width_p-1:0] res_o
  ,output [width_p-1:0] car_o
);
  if(designware_enabled_p == 1) begin: DW_CSA
    DW01_csa #(width_p) 
      dw_csa (
      .a(opA_i),.b(opB_i),.c(opC_i)
      ,.ci(1'b0),.sum(res_o), .carry(car_o)
      ,.co()
    );
  end
  else begin: SELF_CSA
    for(genvar i = 0; i < width_p; i++) begin
      assign {car_o[i], res_o[i]} = opA_i[i] + opB_i[i] + opC_i[i];
    end
  end
endmodule

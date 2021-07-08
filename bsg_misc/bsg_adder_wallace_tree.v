/******************************
===================================
bsg_adder_wallace_tree.v
3/16/2019 sqlin16@fudan.edu.cn
===================================

This is a wallace balanced tree consisting of 4-2 CSA adders, currently used in:
  basejump_stl/bsg_misc/bsg_mul_iterative_booth
  basejump_stl/bsg_misc/bsg_mul_iterative

For more detail in design, please refer to https://docs.google.com/document/d/14xXZklWghWiHcFhxNp3a-hCWSfYd7JXTs1lWpK89bO4/edit

******************************/
module bsg_adder_wallace_tree #(
  parameter integer width_p = "inv"
  ,parameter integer iter_step_p = "inv"
  // For signed extented operands, this parameter should be set equal to width_p.
  ,parameter integer max_out_size_lp = `BSG_SAFE_CLOG2(iter_step_p) + width_p - 1 
)
(
  input [iter_step_p-1:0][width_p-1:0] op_i
  ,output [max_out_size_lp-1:0] resA_o
  ,output [max_out_size_lp-1:0] resB_o
);
  localparam actual_iter_step = 2**`BSG_SAFE_CLOG2(iter_step_p);
  localparam level_num_lp = `BSG_SAFE_CLOG2(actual_iter_step) - 1;
  if (actual_iter_step == 1) begin: CAN_NOT_GENERATE
    initial $error("There is no need to use wallace_tree for iter_step_p=%d.",iter_step_p);
    assign resA_o = '0;
    assign resB_o = '0;
  end //CAN_NOT_GENERATE
  else if(actual_iter_step == 2) begin: NO_WALLACE_TREE
    assign resA_o = op_i[0];
    assign resB_o = op_i[1];
  end //NO_WALLACE_TREE
  else begin: WALLACE_TREE_4_2 
    wire [actual_iter_step*2 - 3:0] [max_out_size_lp - 1:0] all_wire;
    assign resA_o = all_wire[0];
    assign resB_o = all_wire[1];
    for(genvar i = 0; i < actual_iter_step; ++i) begin: CONNECTING_INPUT
      if(i < iter_step_p)
        assign all_wire[actual_iter_step - 2 + i] = op_i[i];
      else
        assign all_wire[actual_iter_step - 2 + i] = '0;
    end //CONNECTING_INPUT
    for(genvar i = 0; i < actual_iter_step/2 - 1; ++i) begin: GENERATE_CSA
      if (max_out_size_lp == `BSG_SAFE_CLOG2(actual_iter_step) + width_p - 1)
        bsg_adder_carry_save_4_2 #(.width_p(max_out_size_lp - (`BSG_SAFE_CLOG2(i + 2) - 1)))
        csa_4_2
        (
          .opA_i(all_wire[4*i + 5])
          ,.opB_i(all_wire[4*i + 4])
          ,.opC_i(all_wire[4*i + 3])
          ,.opD_i(all_wire[4*i + 2])
          ,.A_o(all_wire[2*i + 1])
          ,.B_o(all_wire[2*i])
        );
      else 
        bsg_adder_carry_save_4_2 #(.width_p(max_out_size_lp))
        csa_4_2
        (
          .opA_i(all_wire[4*i + 5])
          ,.opB_i(all_wire[4*i + 4])
          ,.opC_i(all_wire[4*i + 3])
          ,.opD_i(all_wire[4*i + 2])
          ,.A_o(all_wire[2*i + 1])
          ,.B_o(all_wire[2*i])
        );
    end //GENERATE_CSA
  end //WALLACE_TREE_4_2
endmodule


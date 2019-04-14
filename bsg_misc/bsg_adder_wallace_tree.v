/******************************
===================================
bsg_adder_wallace_tree.v
3/16/2019 sqlin16@fudan.edu.cn
===================================

This is a wallace balanced tree consisting of 4-2 CSA Adders. 
And now only the iterative multiplier use this module.

******************************/
module bsg_adder_wallace_tree #(
  parameter width_p = 32
  ,parameter iter_step_p = 2
  ,parameter max_out_size_lp = `BSG_SAFE_CLOG2(iter_step_p) + width_p - 1
)
(
  input [iter_step_p-1:0][width_p - 1:0] op_i
  ,output [max_out_size_lp - 1:0] res_A_o
  ,output [max_out_size_lp - 1:0] res_B_o
);
  localparam actual_iter_step = 2**`BSG_SAFE_CLOG2(iter_step_p);
  localparam level_num_lp = `BSG_SAFE_CLOG2(actual_iter_step) - 1;
  generate
    if (actual_iter_step == 1) begin: CAN_NOT_GENERATE
      initial $error("There is no need to use wallace_tree for iter_step_p=%d.",iter_step_p);
      assign res_A_o = '0;
      assign res_B_o = '0;
    end
    else if(actual_iter_step == 2) begin: NO_WALLACE_TREE
      assign res_A_o = op_i[0];
      assign res_B_o = op_i[1];
    end
    else begin: WALLACE_TREE_4_2 
      wire [max_out_size_lp - 1:0] all_wire[actual_iter_step*2 - 2];
      assign res_A_o = all_wire[0];
      assign res_B_o = all_wire[1];
      for(genvar i = 0; i < actual_iter_step; ++i) begin: CONNECTING_INPUT
        if(i < iter_step_p)
          assign all_wire[actual_iter_step - 2 + i] = op_i[i];
        else
          assign all_wire[actual_iter_step - 2 + i] = '0;
      end
      for(genvar i = 0; i < actual_iter_step/2 - 1; ++i) begin: GENERATE_CSA
        if (max_out_size_lp == `BSG_SAFE_CLOG2(actual_iter_step) + width_p - 1)
          bsg_adder_carry_save_4_2 #(.width_p(max_out_size_lp - (`BSG_SAFE_CLOG2(i + 2) - 1)))
          //bsg_csa_adder_4_2 #(.width_p(max_out_size_lp))
          csa_4_2
          (
            .opA_i(all_wire[4*i + 5])
            ,.opB_i(all_wire[4*i + 4])
            ,.opC_i(all_wire[4*i + 3])
            ,.opD_i(all_wire[4*i + 2])
            ,.outA_o(all_wire[2*i])
            ,.outB_o(all_wire[2*i + 1])
          );
        else 
          //bsg_csa_adder_4_2 #(.width_p(max_out_size_lp - 2*(`BSG_SAFE_CLOG2(i + 2) - 1)))
          bsg_adder_carry_save_4_2 #(.width_p(max_out_size_lp))
          csa_4_2
          (
            .opA_i(all_wire[4*i + 5])
            ,.opB_i(all_wire[4*i + 4])
            ,.opC_i(all_wire[4*i + 3])
            ,.opD_i(all_wire[4*i + 2])
            ,.outA_o(all_wire[2*i])
            ,.outB_o(all_wire[2*i + 1])
          );
      end
    end
  endgenerate
endmodule


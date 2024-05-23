//
// Davis Sauer   05/2024
//
// This module defines functional coverages of module bsg_imul_iterative
//
//

`include "bsg_defines.sv"

module bsg_imul_iterative_cov
 #(parameter width_p = "inv"
  ,localparam lg_width_p = `BSG_SAFE_CLOG2(width_p + 1)
  )
  (input clk_i
  ,input reset_i

  // interface signals
  ,input v_i
  ,input yumi_i
  ,input signed_opA_i
  ,input signed_opB_i

  // internal registers
  ,input [width_p-1:0] opA_r
  ,input [width_p-1:0] opB_r
  ,input [width_p-1:0] result_r

  ,input [width_p-1:0] adder_a
  ,input [width_p-1:0] adder_b

  ,input [width_p  :0] adder_result
  ,input [width_p  :0] shifted_adder_result

  ,input [lg_width_p-1:0] shift_counter_r
  ,input gets_high_part_r

  ,input [2:0] curr_state_r

  ,input signed_opA_r
  ,input signed_opB_r
  ,input need_neg_result_r
  );

  typedef enum logic [2:0] {IDLE, NEG_A, NEG_B, CALC, NEG_R, DONE} imul_state;

  // reset
  covergroup cg_reset @(negedge clk_i);
    coverpoint reset_i;
  endgroup

  // idle
  covergroup cg_idle @ (negedge clk_i iff ~reset_i & curr_state_r == IDLE);

    cp_v: coverpoint v_i;
    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};}

  endgroup 

  // neg_a
  covergroup cg_neg_a @ (negedge clk_i iff ~reset_i & curr_state_r == NEG_A);

    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};} 
    cp_signed_opA: coverpoint signed_opA_r;    
    cp_opA_r: coverpoint opA_r;


  endgroup 

  // neg_b
  covergroup cg_neg_b @ (negedge clk_i iff ~reset_i & curr_state_r == NEG_B);

    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};} 
    cp_signed_opB: coverpoint signed_opB_r;
    cp_opB_r: coverpoint opB_r;

  endgroup 

  // calc
  covergroup cg_calc @ (negedge clk_i iff ~reset_i & curr_state_r == CALC);

    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};}
    cp_gets_high_part_r: coverpoint gets_high_part_r;

  endgroup 

  // neg_r
  covergroup cg_neg_r @ (negedge clk_i iff ~reset_i & curr_state_r == NEG_R);

    cp_yumi: coverpoint yumi_i {illegal_bins ig = {1};}
    cp_need_neg_result_r: coverpoint need_neg_result_r;
    cp_gets_high_part_r: coverpoint gets_high_part_r;

  endgroup 

  // done
  covergroup cg_done @ (negedge clk_i iff ~reset_i & curr_state_r == DONE);

    cp_result: coverpoint result_r;
    cp_yumi: coverpoint yumi_i;
    cp_result_r: coverpoint result_r;

  endgroup 


  // create cover groups
  cg_reset cov_reset = new;
  cg_idle cov_idle = new;
  cg_neg_a cov_neg_a = new;
  cg_neg_b cov_neg_b = new;
  cg_calc cov_calc = new;
  cg_neg_r cov_neg_r = new;
  cg_done cov_done = new;
  

  // print coverages when simulation is done
  final
  begin
    $display("");
    $display("Instance: %m");
    $display("---------------------- Functional Coverage Results ----------------------");
    $display("Reset       functional coverage is %f%%", cov_reset.get_coverage());
    $display("Idle        functional coverage is %f%%", cov_idle.get_coverage());
    $display("Neg A       functional coverage is %f%%", cov_neg_a.get_coverage());
    $display("Neg B       functional coverage is %f%%", cov_neg_b.get_coverage());
    $display("Calc        functional coverage is %f%%", cov_calc.get_coverage());
    $display("Neg R       functional coverage is %f%%", cov_neg_r.get_coverage());
    $display("Done        functional coverage is %f%%", cov_done.get_coverage());
    $display("-------------------------------------------------------------------------");
    $display("");
  end

endmodule

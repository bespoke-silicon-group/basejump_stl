// This module defines functional coverages of module bsg_mesh_router
`include "bsg_defines.sv"

module bsg_mesh_router_cov
  import bsg_noc_pkg::*;
  import bsg_mesh_router_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p )
    , parameter `BSG_INV_PARAM(x_cord_width_p )
    , parameter `BSG_INV_PARAM(y_cord_width_p )
    , parameter ruche_factor_X_p = 0
    , parameter ruche_factor_Y_p = 0
    , parameter dims_p = 2
    , parameter out_dirs_lp = (2*dims_p)+1
    , parameter in_dirs_lp = out_dirs_lp
    , parameter XY_order_p = 1
    , parameter depopulated_p = 1
    , parameter bit [out_dirs_lp-1:0][in_dirs_lp-1:0]  routing_matrix_p = 
      (dims_p == 2) ? (XY_order_p ? StrictXY : StrictYX) : (
      (dims_p == 3) ? (depopulated_p ? (XY_order_p ? HalfRucheX_StrictXY : HalfRucheX_StrictYX) 
                                     : (XY_order_p ? HalfRucheX_FullyPopulated_StrictXY : HalfRucheX_FullyPopulated_StrictYX)) : (
      (dims_p == 4) ? (depopulated_p ? (XY_order_p ? FullRuche_StrictXY : FullRuche_StrictYX)
                                     : (XY_order_p ? FullRuche_FullyPopulated_StrictXY : FullRuche_FullyPopulated_StrictYX))
                    : "inv"))

    , parameter debug_p = 0
  )
  (
    input clk_i
    , input reset_i
    
    // TODO: remove unneccessary inputs to coverage module

    , input [in_dirs_lp-1:0] v_i
    , input [out_dirs_lp-1:0] ready_and_i

    // node's x and y coord
    , input [x_cord_width_p-1:0] my_x_i           
    , input [y_cord_width_p-1:0] my_y_i

    // internal registers
    , input [in_dirs_lp-1:0] yumi_o
    , input [in_dirs_lp-1:0][out_dirs_lp-1:0] req;
    , input [out_dirs_lp-1:0][in_dirs_lp-1:0] req_t;
  );

  // reset
  covergroup cg_reset @(negedge clk_i);
      coverpoint reset_i;
  endgroup

  // check unicast and multicast cases
  covergroup cg_multicast @(negedge clk_i iff ~reset_i);
    cp_num_targets: coverpoint $countones(req) {
      bins unicast = {1};
      bins multicast = {2};
      bins drop = {0};
    }
  endgroup

  // make sure all port pairs are hit
  covergroup cg_port_pairing @(negedge clk_i iff ~reset_i);
    cp_request_vector: coverpoint req {
      bins e_p = {5'b10010};
      bins w_p = {5'b10001};
      bins n_p = {5'b10100};
      bins s_p = {5'b11000};
      bins e =   {5'b00010};
      bins w =   {5'b00001};
      bins n =   {5'b00100};
      bins s =   {5'b01000};
    }
  endgroup

  covergroup cg_stall_check @(negedge clk_i iff ~reset_i);
    cp_is_mc: coverpoint ($countones(req) > 1);

    cp_not_ready: coverpoint (|~ready_and_i);

    cross_mc_stall: cross cp_is_mc, cp_not_ready {
      bins mc_while_stalled = binsof(cp_is_mc) intersect {1} && binsof(cp_not_ready) intersect {1};
    }
  endgroup

  integer target_port;
  integer num_reqs;

  covergroup cg_arbiter_contention @(negedge clk_i iff ~reset_i);
    cp_output_port: coverpoint target_port {
      bins ports[] = {[0:out_dirs_lp-1]};
    }

    cp_contention_level: coverpoint num_reqs {
      bins solo = {1};
      bins duel = {2};
      bins many = {[3:5]};
    }

    cross_port_contention: cross cp_output_port, cp_contention_level;
  endgroup

  cg_reset cov_reset = new();
  cg_multicast cov_mc = new();
  cg_port_pairing cov_pp = new();
  cg_stall_check cov_stall = new();
  cg_arbiter_contention arb_cov = new();

  always_ff @(negedge clk_i) begin
    if (!reset_i) begin 
      for (int i = 0; i < out_dirs_lp; i++) begin
        target_port = i;
        num_reqs = $countones(req_t[i]);
        if (num_reqs > 0) begin
          arb_cov.sample();
        end
      end
    end
  end
  

endmodule
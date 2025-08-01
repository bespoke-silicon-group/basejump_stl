/**
 *    bsg_mesh_router.sv
 *
 *
 *    dims_p      network
 *    ------------------------
 *      1         1-D mesh
 *      2         2-D mesh
 *      3         2-D mesh + half ruche x
 *      4         2-D mesh + full ruche
 *
 *      ruche_factor_X/Y_p determines the number of hops that ruche links extend in the direction.
 *
 *      Currently only tested for
 *      - 2-D mesh
 *      - 2-D mesh + half ruche x
 *
 *   Fixme perf: In theory, we could drop data bits (e.g. the X coordinate) as we switch to different dimensions, but the code would be a little complicated.
 *
 *   For 2D mesh network, you can feed in in_dirs_lp > out_dirs_lp, and they will act as extra P ports. You also need to feed in an appropriate routing_matrix_p.
 *   
 */  

`include "bsg_defines.sv"


module bsg_mesh_router
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

    , input [in_dirs_lp-1:0][width_p-1:0] data_i
    , input [in_dirs_lp-1:0]              v_i
    , output logic [in_dirs_lp-1:0]       yumi_o

    , input   [out_dirs_lp-1:0]               ready_and_i
    , output  [out_dirs_lp-1:0][width_p-1:0]  data_o
    , output logic [out_dirs_lp-1:0]          v_o

    // node's x and y coord
    , input   [x_cord_width_p-1:0] my_x_i           
    , input   [y_cord_width_p-1:0] my_y_i
  );


  // input x,y coords
  logic [in_dirs_lp-1:0][x_cord_width_p-1:0] x_dirs;
  logic [in_dirs_lp-1:0][y_cord_width_p-1:0] y_dirs;

  for (genvar i = 0; i < in_dirs_lp; i++) begin
    assign x_dirs[i] = data_i[i][0+:x_cord_width_p];
    assign y_dirs[i] = data_i[i][x_cord_width_p+:y_cord_width_p];
  end


  // dimension-ordered routing logic
  logic [in_dirs_lp-1:0][out_dirs_lp-1:0] req;
  logic [out_dirs_lp-1:0][in_dirs_lp-1:0] req_t;
   
  for (genvar i = 0; i < in_dirs_lp; i++) begin: dor
    logic [out_dirs_lp-1:0] temp_req;

    bsg_mesh_router_decoder_dor #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.ruche_factor_X_p(ruche_factor_X_p)
      ,.ruche_factor_Y_p(ruche_factor_Y_p)
      ,.dims_p(dims_p)
      ,.XY_order_p(XY_order_p)
      // if in_dirs_lp > out_dirs_lp, then for the purposes of dimension 
      // ordered routing only, we treat the extra directions as "P"			  
      ,.from_p((out_dirs_lp)'(1 << (i < out_dirs_lp ? i : P)))
      ,.depopulated_p(depopulated_p)
      ,.debug_p(debug_p)
    ) dor_decoder (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.x_dirs_i(x_dirs[i])
      ,.y_dirs_i(y_dirs[i])
      ,.my_x_i(my_x_i)
      ,.my_y_i(my_y_i)

      ,.req_o(temp_req)
    );
    
    assign req[i] = {out_dirs_lp{v_i[i]}} & temp_req;
  end

  bsg_transpose #(
    .width_p(out_dirs_lp)
    ,.els_p(in_dirs_lp) 
  ) req_tp (
    .i(req)
    ,.o(req_t)
  );



  // Instantiate crossbars for each output direction
   logic [out_dirs_lp-1:0][in_dirs_lp-1:0] yumi_lo;
   logic [in_dirs_lp-1:0][out_dirs_lp-1:0] yumi_lo_t;

  for (genvar i = 0; i < out_dirs_lp; i++) begin: xbar

    localparam input_els_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[i]);

    logic [input_els_lp-1:0][width_p-1:0] conc_data;
    logic [input_els_lp-1:0] conc_req;
    logic [input_els_lp-1:0] grants;
    
    bsg_array_concentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
      ,.width_p(width_p)
    ) conc0 (
      .i(data_i)
      ,.o(conc_data)
    );

    bsg_concentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
    ) conc1 (
      .i(req_t[i])
      ,.o(conc_req)
    );

    assign v_o[i] = |conc_req;

    bsg_arb_round_robin #(
      .width_p(input_els_lp)
    ) rr (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.reqs_i(conc_req)
      ,.grants_o(grants)
      ,.yumi_i(v_o[i] & ready_and_i[i])
    );

    bsg_mux_one_hot #(
      .els_p(input_els_lp)
      ,.width_p(width_p)
    ) data_mux (
      .data_i(conc_data)
      ,.sel_one_hot_i(grants)
      ,.data_o(data_o[i])
    );

    bsg_unconcentrate_static #(
      .pattern_els_p(routing_matrix_p[i])
      ,.unconnected_val_p(1'b0)
    ) unconc0 (
      .i(grants & {input_els_lp{ready_and_i[i]}})
      ,.o(yumi_lo[i])
    );

  end


  bsg_transpose #(
    .width_p(in_dirs_lp)
    ,.els_p(out_dirs_lp) 
  ) yumi_tp (
    .i(yumi_lo)
    ,.o(yumi_lo_t)
  );


  for (genvar i = 0; i < in_dirs_lp; i++) begin
    assign yumi_o[i] = |yumi_lo_t[i];
  end



`ifndef BSG_HIDE_FROM_SYNTHESIS
  if (debug_p) begin
    always_ff @ (negedge clk_i) begin

      if (~reset_i) begin
        for (integer i = 0; i < in_dirs_lp; i++) begin
          assert($countones(yumi_lo_t[i]) < 2)
            else $error("multiple yumi detected. i=%d, %b", i, yumi_lo_t[i]);
        end
      end
 
    end
  end
`endif







endmodule

`BSG_ABSTRACT_MODULE(bsg_mesh_router)

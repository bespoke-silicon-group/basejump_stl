`include "bsg_defines.sv"

module bsg_torus_router_xbar
  import bsg_mesh_router_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(XY_order_p)
    , parameter dims_p=2
    , localparam sw_dirs_lp=(dims_p*2)+1
    , parameter bit [sw_dirs_lp-1:0][sw_dirs_lp-1:0] routing_matrix_p =
      (XY_order_p ? StrictXY : StrictYX)
  )
  (
    input [sw_dirs_lp-1:0][width_p-1:0] data_i             // [in]
    , input [sw_dirs_lp-1:0][sw_dirs_lp-1:0] sel_i         // [out][in] one hot;
    , output logic [sw_dirs_lp-1:0][width_p-1:0] data_o    // [out]
  );


  for (genvar i = 0; i < sw_dirs_lp; i++) begin:xb
    localparam input_els_lp = `BSG_COUNTONES_SYNTH(routing_matrix_p[i]);

    logic [input_els_lp-1:0][width_p-1:0] conc_data;
    logic [input_els_lp-1:0] conc_sel;

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
      .i(sel_i[i])
      ,.o(conc_sel)
    );

    bsg_mux_one_hot #(
      .width_p(width_p)
      ,.els_p(input_els_lp)
    ) mux0 (
      .data_i(conc_data)
      ,.sel_one_hot_i(conc_sel)
      ,.data_o(data_o[i])
    );

  end


endmodule

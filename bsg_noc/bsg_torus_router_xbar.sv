`include "bsg_defines.sv"

module bsg_torus_router_xbar
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter dims_p=2
    , localparam dirs_lp=(dims_p*2)+1
  )
  (
    input [dirs_lp-1:0][width_p-1:0] data_i             // [in]
    , input [dirs_lp-1:0][dirs_lp-1:0] sel_i            // [out][in]
    , output logic [dirs_lp-1:0][width_p-1:0] data_o    // [out]
  );


  for (genvar i = 0; i < dirs_lp; i++) begin:xb
    bsg_mux_one_hot #(
      .width_p(width_p)
      ,.els_p(dirs_lp)
    ) mux0 (
      .data_i(data_i)
      ,.sel_one_hot_i(sel_i[i])
      ,.data_o(data_o[i])
    );
  end


endmodule

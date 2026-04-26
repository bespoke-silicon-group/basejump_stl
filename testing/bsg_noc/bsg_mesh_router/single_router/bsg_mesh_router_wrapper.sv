`include "bsg_defines.sv"

module bsg_mesh_router_wrapper
  import bsg_noc_pkg::*;
  import bsg_mesh_router_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p = 82 )
    , parameter `BSG_INV_PARAM(x_cord_width_p = 2 )
    , parameter `BSG_INV_PARAM(y_cord_width_p = 2 )
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

    bsg_mesh_router #(.width_p(width_p)
                            ,.x_cord_width_p(x_cord_width_p)
                            ,.y_cord_width_p(y_cord_width_p)
    ) dut
    (.*);

    bind bsg_mesh_router bsg_mesh_router_cov #(.width_p(width_p)
                            ,.x_cord_width_p(x_cord_width_p)
                            ,.y_cord_width_p(y_cord_width_p)
    ) bsg_mesh_router_cov
    (.*);

    // dump waveforms
    initial begin
        $fsdbDumpvars("+all");
    end         

endmodule
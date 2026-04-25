// This module defines functional coverages of module bsg_mesh_router_decoder_dor_mc
`include "bsg_defines.sv"

module bsg_mesh_router_decoder_dor_mc_cov
    import bsg_noc_pkg::*;
    import bsg_mesh_router_pkg::*;
    #(parameter `BSG_INV_PARAM(x_cord_width_p )
        , parameter `BSG_INV_PARAM(y_cord_width_p )
        , parameter dims_p = 2
        , parameter dirs_lp = (2*dims_p)+1
        , parameter ruche_factor_X_p=0
        , parameter ruche_factor_Y_p=0
        // XY_order_p = 1 :  X then Y
        // XY_order_p = 0 :  Y then X
        , parameter XY_order_p = 1
        , parameter depopulated_p = 1
        , parameter from_p = {dirs_lp{1'b0}}  // one-hot, indicates which direction is the input coming from.
    
        , parameter debug_p = 1
    )
    (
        input clk_i         // debug only
        , input reset_i     // debug only
        , input mc_x  // multicast x
        , input mc_y  // multicast y
        , input [x_cord_width_p-1:0] x_dirs_i
        , input [y_cord_width_p-1:0] y_dirs_i
    
        , input [x_cord_width_p-1:0] my_x_i
        , input [y_cord_width_p-1:0] my_y_i

        // internal registers
        , input x_eq
        , input y_eq
        , input [dirs_lp-1:0] req
    );

    // reset
    covergroup cg_reset @(negedge clk_i);
        coverpoint reset_i;
    endgroup

    // multicast in x direction
    covergroup cg_mc_x @(negedge clk_i iff ~reset_i);
        cv_x_eq: coverpoint x_eq;
        cv_mc_x: coverpoint mc_x;
    
        cross_all: cross cv_x_eq, cv_mc_x;
    endgroup

    // multicast in y direction
    covergroup cg_mc_y @(negedge clk_i iff ~reset_i);
        cv_y_eq: coverpoint y_eq;
        cv_mc_y: coverpoint mc_y;

        cross_all: cross cv_y_eq, cv_mc_y;
    endgroup

    // create multicast covergroups
    cg_reset cov_reset = new;
    // cg_p_delivery cov_p_delivery = new;
    cg_mc_x cov_mc_x = new;
    cg_mc_y cov_mc_y = new;

    // print coverages when simulation is done
    final
    begin
        $display("");
        $display("Instance: %m");
        $display("---------------------- Functional Coverage Results ----------------------");
        $display("Reset                    functional coverage is %f%%", cov_reset.get_coverage());
        // $display("P delivery               functional coverage is %f%%", cov_p_delivery.cross_all.get_coverage());
        $display("Multicast in x direction functional coverage is %f%%", cov_mc_x.cross_all.get_coverage());
        $display("Multicast in y direction functional coverage is %f%%", cov_mc_y.cross_all.get_coverage());
        $display("-------------------------------------------------------------------------");
        $display("");
    end
endmodule
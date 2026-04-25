module bsg_mesh_router_decoder_dor_mc_wrapper #(parameter x_cord_width_p = 4
                                                , parameter y_cord_width_p = 4
                                                , parameter dims_p = 2
                                                , parameter dirs_lp = (2*dims_p)+1
                                                , parameter ruche_factor_X_p=0
                                                , parameter ruche_factor_Y_p=0
                                                , parameter XY_order_p = 1
                                                , parameter depopulated_p = 1
                                                , parameter from_p = 5'b00001  // one-hot, indicates which direction is the input coming from.
                                                , parameter debug_p = 1
                                                ) 
    (
        input clk_i,
        input reset_i,          
        input mc_x,
        input mc_y,
        input [x_cord_width_p-1:0] x_dirs_i,
        input [y_cord_width_p-1:0] y_dirs_i,
        input [x_cord_width_p-1:0] my_x_i,
        input [y_cord_width_p-1:0] my_y_i,
        output [dirs_lp-1:0] req_o
    );

    // instantiate DUT
    bsg_mesh_router_decoder_dor_mc #(.x_cord_width_p(x_cord_width_p)
                                    ,.y_cord_width_p(y_cord_width_p)
                                    ,.dims_p(dims_p)
                                    ,.dirs_lp(dirs_lp)
                                    ,.ruche_factor_X_p(ruche_factor_X_p)
                                    ,.ruche_factor_Y_p(ruche_factor_Y_p)
                                    ,.XY_order_p(XY_order_p)
                                    ,.depopulated_p(depopulated_p)
                                    ,.from_p(from_p)
                                    ,.debug_p(debug_p)
                                    ) dor_decoder 
    (.*);

    // bind covergroups
    bind bsg_mesh_router_decoder_dor_mc bsg_mesh_router_decoder_dor_mc_cov
    #(.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.dims_p(dims_p)
    ,.dirs_lp(dirs_lp)
    ,.ruche_factor_X_p(ruche_factor_X_p)
    ,.ruche_factor_Y_p(ruche_factor_Y_p)
    ,.XY_order_p(XY_order_p)
    ,.depopulated_p(depopulated_p)
    ,.from_p(from_p)
    ,.debug_p(debug_p)
    ) pc_cov 
    (.*
    );

    // dump waveforms
    initial begin
        $fsdbDumpvars("+all");
    end                                         
endmodule
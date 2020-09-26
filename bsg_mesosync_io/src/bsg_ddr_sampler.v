// bsg_ddr_sampler samples them input signal on both
// edges and also provides the registered version of them
// it uses to flops for stabilizing the synchronized ones

`include "bsg_defines.v"

module bsg_ddr_sampler #(width_p = "inv")
    ( input                      clk
    , input                      reset
    , input        [width_p-1:0] to_be_sampled_i
    
    , output logic [width_p-1:0] pos_edge_value_o
    , output logic [width_p-1:0] neg_edge_value_o
    , output logic [width_p-1:0] pos_edge_synchronized_o
    , output logic [width_p-1:0] neg_edge_synchronized_o
    );

bsg_launch_sync_sync #( .width_p(width_p)
			                , .use_negedge_for_launch_p(0)
                      ) positive_edge

    ( .iclk_i(clk)
    , .iclk_reset_i(reset)
    , .oclk_i(clk)
    , .iclk_data_i(to_be_sampled_i)
    , .iclk_data_o(pos_edge_value_o)
    , .oclk_data_o(pos_edge_synchronized_o) 
    );

bsg_launch_sync_sync #( .width_p(width_p)
			                , .use_negedge_for_launch_p(1)
                      ) negative_edge

    ( .iclk_i(clk)
    , .iclk_reset_i(reset)
    , .oclk_i(clk)
    , .iclk_data_i(to_be_sampled_i)
    , .iclk_data_o(neg_edge_value_o)
    , .oclk_data_o(neg_edge_synchronized_o) 
    );

endmodule

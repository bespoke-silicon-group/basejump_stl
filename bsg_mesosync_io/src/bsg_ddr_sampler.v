// bsg_ddr_sampler samples them input signal on both
// edges and also provides the registered version of them

module bsg_ddr_sampler #(width_p = -1)
    ( input                      clk
    , input                      reset
    , input        [width_p-1:0] to_be_sampled_i
    
    , output logic [width_p-1:0] pos_edge_value_o
    , output logic [width_p-1:0] neg_edge_value_o
    , output logic [width_p-1:0] pos_edge_synchronized_o
    , output logic [width_p-1:0] neg_edge_synchronized_o
    );

always_ff @ (posedge clk)
  pos_edge_value_o <= to_be_sampled_i;

always_ff @ (negedge clk)
  neg_edge_value_o <= to_be_sampled_i;

always_ff @ (posedge clk) begin
  pos_edge_synchronized_o <= pos_edge_value_o;
  neg_edge_synchronized_o <= neg_edge_value_o;
end

endmodule



module bsg_link_iddr_phy

 #(parameter width_p = "inv")

  (input clk_i
  ,input [width_p-1:0] data_i
  ,output [2*width_p-1:0] data_o);
  
  logic [2*width_p-1:0] data_r;
  logic [width_p-1:0] data_p;
  assign data_o = data_r;

  always @(posedge clk_i)
    data_p <= data_i;
  
  always @(negedge clk_i)
    data_r <= {data_i, data_p};

endmodule

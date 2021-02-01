
//
// Paul Gao 02/2021
//
//

module bsg_link_isdr_phy

 #(parameter width_p = "inv")

  (input                clk_i
  ,input  [width_p-1:0] data_i
  ,output [width_p-1:0] data_o
  );

  bsg_dff #(.width_p(width_p)) data_ff 
  (.clk_i(clk_i),.data_i(data_i),.data_o(data_o));

endmodule

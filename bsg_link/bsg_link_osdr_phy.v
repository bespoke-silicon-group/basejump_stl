
//
// Paul Gao 02/2021
//
//

module bsg_link_osdr_phy

 #(parameter width_p = "inv")

  (input                clk_i
  ,input                reset_i
  ,input  [width_p-1:0] data_i
  ,output               clk_o
  ,output [width_p-1:0] data_o
  );

  logic clk_r_p, clk_r_n;
  assign clk_o = clk_r_p ^ clk_r_n;

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_p
  (.clk_i(clk_i),.reset_i(reset_i),.data_i(~clk_r_p),.data_o(clk_r_p));

  bsg_dff_reset #(.width_p(1),.reset_val_p(0)) clk_ff_n
  (.clk_i(~clk_i),.reset_i(reset_i),.data_i(~clk_r_n),.data_o(clk_r_n));

  bsg_dff #(.width_p(width_p)) data_ff 
  (.clk_i(clk_i),.data_i(data_i),.data_o(data_o));

endmodule

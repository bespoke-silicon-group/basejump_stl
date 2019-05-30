

module bsg_link_oddr_phy_90

 #(parameter width_p = "inv")

  (input reset_i
  ,input clk_2x_i
  ,input [2*width_p-1:0] data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic clk_r_o);
  
  logic odd, clk;
  logic [2*width_p-1:0] data_90;
  
  always_ff @(negedge clk_2x_i)
    data_90 <= data_i;

  always_ff @(posedge clk_2x_i) begin
    clk <= ~reset_i & ~clk;
    clk_r_o <= clk;
  end
    
  always_ff @(negedge clk_2x_i)
    odd <= ~reset_i & ~odd;

  always_ff @(negedge clk_2x_i)
    if(odd) 
      data_r_o <= data_90[0+:width_p];
    else 
      data_r_o <= data_90[width_p+:width_p];

endmodule
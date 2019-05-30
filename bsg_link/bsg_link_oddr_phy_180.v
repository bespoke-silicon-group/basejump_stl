

module bsg_link_oddr_phy_180

 #(parameter width_p = "inv")

  (input reset_i
  ,input clk_2x_i
  ,input [2*width_p-1:0] data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic clk_r_o);
  
  logic odd, clk;
  logic [2*width_p-1:0] data_180;
  
  always_ff @(posedge clk_2x_i)
    data_180 <= data_i;

  always_ff @(negedge clk_2x_i) begin
    clk <= reset_i | ~clk;
    clk_r_o <= clk;
  end
    
  always_ff @(posedge clk_2x_i)
    odd <= ~reset_i & ~odd;

  always_ff @(posedge clk_2x_i)
    if(odd) 
      data_r_o <= data_180[0+:width_p];
    else
      data_r_o <= data_180[width_p+:width_p];

endmodule


module bsg_link_oddr_phy

 #(parameter width_p = "inv")

  (input reset_i
  ,input clk_2x_i
  ,input [2*width_p-1:0] data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic clk_r_o);
  
  logic odd, clk;
  
  always @(negedge clk_2x_i) begin
    clk <= ~reset_i & ~clk;
    clk_r_o <= clk;
  end
    
  always @(posedge clk_2x_i)
    odd <= reset_i | ~odd;

  always @(posedge clk_2x_i)
    if(odd) 
      data_r_o <= data_i[0+:width_p];
    else 
      data_r_o <= data_i[width_p+:width_p];

endmodule


module bsg_link_oddr_phy_90

 #(parameter width_p = "inv")

  (input reset_i
  ,input clk_2x_i
  ,input [2*width_p-1:0] data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic clk_r_o);
  
  logic odd, clk;
  logic [2*width_p-1:0] data_90;
  
  always @(negedge clk_2x_i)
    data_90 <= data_i;

  always @(posedge clk_2x_i) begin
    clk <= ~reset_i & ~clk;
    clk_r_o <= clk;
  end
    
  always @(negedge clk_2x_i)
    odd <= ~reset_i & ~odd;

  always @(negedge clk_2x_i)
    if(odd) 
      data_r_o <= data_90[0+:width_p];
    else 
      data_r_o <= data_90[width_p+:width_p];

endmodule


module bsg_link_oddr_phy_180

 #(parameter width_p = "inv")

  (input reset_i
  ,input clk_2x_i
  ,input [2*width_p-1:0] data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic clk_r_o);
  
  logic odd, clk;
  logic [2*width_p-1:0] data_180;
  
  always @(posedge clk_2x_i)
    data_180 <= data_i;

  always @(negedge clk_2x_i) begin
    clk <= reset_i | ~clk;
    clk_r_o <= clk;
  end
    
  always @(posedge clk_2x_i)
    odd <= ~reset_i & ~odd;

  always @(posedge clk_2x_i)
    if(odd) 
      data_r_o <= data_180[0+:width_p];
    else
      data_r_o <= data_180[width_p+:width_p];

endmodule









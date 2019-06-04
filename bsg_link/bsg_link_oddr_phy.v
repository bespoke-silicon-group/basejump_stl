
//
// Paul Gao 03/2019
//
// This is an output DDR PHY
// Input data must be synchronous to posedge of 1x clock (generated from 2x clock)
// Output clock is center-aligned to output data
//
// Note that the output clock and data wires need length match
// Need output delay constraint(s) to ensure clock and data delay are same
//
//

module bsg_link_oddr_phy

 #(parameter width_p = "inv")

  (input                      reset_i
  ,input                      clk_2x_i
  ,input [2*width_p-1:0]      data_i
  ,output logic [width_p-1:0] data_r_o
  ,output logic               clk_r_o
  );
  
  logic odd_r, clk_r;
  
  always_ff @(negedge clk_2x_i) 
  begin
    if (reset_i)
        clk_r <= 1'b0;
    else 
        clk_r <= ~clk_r;
    // Clock output flop
    clk_r_o <= clk_r;
  end
    
  always_ff @(posedge clk_2x_i)
    if (reset_i) 
        odd_r <= 1'b1;
    else 
        odd_r <= ~odd_r;

  // Data output flop
  always_ff @(posedge clk_2x_i)
    if (odd_r) 
        data_r_o <= data_i[0+:width_p];
    else 
        data_r_o <= data_i[width_p+:width_p];

endmodule
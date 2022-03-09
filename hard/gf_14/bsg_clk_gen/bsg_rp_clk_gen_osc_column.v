
module bsg_rp_clk_gen_osc_column
 #(parameter num_row_p=2)
  (input async_reset_i
   , input clkgate_i
   , input clkdly_i
   , input clkfb_i
   , input [num_row_p-1:0] ctl_one_hot_i
   , output logic clk_o
   );

  wire clkgate_inv;
  SC7P5T_CKINVX8_SSC14SL I0 (.Z(clkgate_i), .CLK(clkgate_inv));

  wire clkdly_inv;
  SC7P5T_CKINVX8_SSC14SL I1 (.Z(clkdly_i), .CLK(clkdly_inv));

  wire [num_row_p:0] clkfb;
  assign clkfb[0] = clkfb_i;
  for (genvar i = 0; i < num_row_p; i++)
    begin : r
      bsg_clk_gen_osc_row row
        (.async_reset_i(async_reset_i)
         ,.clkgate_i(clkgate_inv)
         ,.clkdly_i(clkdly_inv)
         ,.clkfb_i(clkfb[i])
         ,.ctl_i(ctl_one_hot_i[i]
         ,.clk_o(clkfb[i+1])
         );
    end
  assign clk_o = clkfb[num_row_p];

endmodule


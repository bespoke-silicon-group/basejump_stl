
module bsg_dmc_dly_line_v3
 #(parameter `BSG_INV_PARAM(num_taps_p)
   )
  (input clk_i
   , input async_reset_i
   , output logic clk_o
   );

  bsg_rp_dly_line_v3 dly_BSG_DONT_TOUCH
   (.clk_i(clk_i)
    ,.async_reset_i(async_reset_i)
    ,.clk_o(clk_o)
    );

endmodule


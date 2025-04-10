
module bsg_sync_sync_async_reset_unit
 (input oclk_i
  , input iclk_reset_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic bsg_SYNC_1_r, bsg_SYNC_2_r;

  bsg_dff_async_reset #(.width_p(1)) sync_int1
   (.clk_i(oclk_i)
    ,.async_reset_i(iclk_reset_i)
    ,.data_i(iclk_data_i)
    ,.data_o(bsg_SYNC_1_r)
    );

  bsg_dff_async_reset #(.width_p(1)) sync_int2
   (.clk_i(oclk_i)
    ,.async_reset_i(iclk_reset_i)
    ,.data_i(bsg_SYNC_1_r)
    ,.data_o(bsg_SYNC_2_r)
    );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


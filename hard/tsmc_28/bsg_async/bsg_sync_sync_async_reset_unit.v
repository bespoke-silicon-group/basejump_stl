
module bsg_sync_sync_async_reset_unit
 (input oclk_i
  , input iclk_reset_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic bsg_SYNC_1_r, bsg_SYNC_2_r;

  DFCNQD4BWP7T30P140ULVT hard_sync_int1
   (.CP(oclk_i)
   ,.CDN(~iclk_reset_i)
   ,.D(iclk_data_i)
   ,.Q(bsg_SYNC_1_r)
   );

  DFCNQD4BWP7T30P140ULVT hard_sync_int2
   (.CP(oclk_i)
   ,.CDN(~iclk_reset_i)
   ,.D(bsg_SYNC_1_r)
   ,.Q(bsg_SYNC_2_r)
   );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


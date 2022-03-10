
module bsg_sync_sync_unit
 (input oclk_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic bsg_SYNC_1_r, bsg_SYNC_2_r;

  DFQD4BWP7T30P140ULVT hard_sync_int1_BSG_SYNC
   (.CP(oclk_i)
   ,.D(iclk_data_i)
   ,.Q(bsg_SYNC_1_r)
   );

  DFQD4BWP7T30P140ULVT hard_sync_int2_BSG_SYNC
   (.CP(oclk_i)
   ,.D(bsg_SYNC_1_r)
   ,.Q(bsg_SYNC_2_r)
   );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


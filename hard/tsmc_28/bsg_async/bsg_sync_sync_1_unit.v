
module bsg_sync_sync_1_unit
 (input oclk_i
  , input iclk_reset_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic [width_p-1:0] bsg_SYNC_1_r, bsg_SYNC_2_r;

  DFQD4BWP7T40P140LVT hard_sync_int1
   (.CP(oclk_i)
   ,.D(iclk_data_i[i])
   ,.Q(bsg_SYNC_1_r[i])
   );

  DFQD4BWP7T40P140LVT hard_sync_int2
   (.CP(oclk_i)
   ,.D(bsg_SYNC_1_r[i])
   ,.Q(bsg_SYNC_2_r[i])
   );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


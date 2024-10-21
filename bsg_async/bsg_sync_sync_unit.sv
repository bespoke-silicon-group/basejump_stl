
module bsg_sync_sync_unit #(parameter harden_p=1)
 (input oclk_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic bsg_SYNC_1_r, bsg_SYNC_2_r;

  bsg_dff #(.width_p(1), .harden_p(harden_p)) hard_sync_int1_BSG_SYNC
   (.clk_i(oclk_i)
    ,.data_i(iclk_data_i)
    ,.data_o(bsg_SYNC_1_r)
    );

  bsg_dff #(.width_p(1), .harden_p(harden_p) hard_sync_int2_BSG_SYNC
   (.clk_i(oclk_i)
    ,.data_i(bsg_SYNC_1_r)
    ,.data_o(bsg_SYNC_2_r)
    );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


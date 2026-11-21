
//
// Context: Some PDKs do not have a sync cell
//   to use explicitly, so we compose one ourselves and call
//   it a synchronization 'unit'.
//
// bsg_SYNC_1_r and bsg_SYNC_2_r should be placed abutted if possible
//   so that there is a small max path between them.
//
// In synopsys flows, rp_groups can be used and this file can be annotated.
// In cadence flows, SDP groups serve the same purpose, but are contained within
//   external files.
// We have also seen good results with magnet placement of these two cells
//
// Users should
//   set_false_path -to bsg_SYNC_1_r/D
//   to avoid false CDC violations. With high clock uncertainty, we've also
//   observed violating min paths between the flops. If the placement is
//   correct, then this uncertainty is pessimistic and can be waived with
//   set_false_path -hold -from bsg_SYNC_1_r/Q -to bsg_SYNC_1_r/D
//
module bsg_sync_sync_async_reset_unit #(parameter `BSG_INV_PARAM(width_p)
                                        , parameter `BSG_INV_PARAM(harden_p)
                                        )
 (input oclk_i
  , input iclk_reset_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic [width_p-1:0] bsg_SYNC_1_r, bsg_SYNC_2_r;

  bsg_dff_async_reset
   #(.width_p(width_p), .harden_p(harden_p))
   hard_sync_int1_BSG_SYNC
    (.clk_i(oclk_i)
     ,.async_reset_i(iclk_reset_i)
     ,.data_i(iclk_data_i)
     ,.data_o(bsg_SYNC_1_r)
     );

  bsg_dff_async_reset
   #(.width_p(width_p), .harden_p(harden_p))
   hard_sync_int2_BSG_SYNC
    (.clk_i(oclk_i)
     ,.async_reset_i(iclk_reset_i)
     ,.data_i(bsg_SYNC_1_r)
     ,.data_o(bsg_SYNC_2_r)
     );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule

`BSG_ABSTRACT_MODULE(bsg_sync_sync_async_reset_unit)


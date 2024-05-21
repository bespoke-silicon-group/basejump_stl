
//
// Context: The tsmc28 PDK we used did not have a sync cell
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
module bsg_sync_sync_unit
 (input oclk_i
  , input iclk_data_i
  , output oclk_data_o // after sync flops
  );

  logic bsg_SYNC_1_r, bsg_SYNC_2_r;

  sky130_fd_sc_hd__dfxtp_1 hard_sync_int1_BSG_SYNC
   (.CLK(oclk_i)
   ,.D(iclk_data_i)
   ,.Q(bsg_SYNC_1_r)
   );

  wire bsg_SYNC_2_n;
  bsg_nonsynth_delay_line #(.width_p(1), .delay_p(10)) hard_sync_buf_BSG_DONT_TOUCH
   (.o(bsg_SYNC_2_n), .i(bsg_SYNC_1_r));

  sky130_fd_sc_hd__dfxtp_1 hard_sync_int2_BSG_SYNC
   (.CLK(oclk_i)
   ,.D(bsg_SYNC_2_n)
   ,.Q(bsg_SYNC_2_r)
   );

  assign oclk_data_o = bsg_SYNC_2_r;

endmodule


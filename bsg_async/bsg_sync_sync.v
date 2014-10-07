// MBT 7/24/2014
//
// bsg_sync_sync
//
// This is just two synchronization flops.
//

module bsg_sync_sync #(parameter width_p = "inv")
   (
      input oclk_i
    , input  [width_p-1:0] iclk_data_i
    , output [width_p-1:0] oclk_data_o // after sync flops
    );

   logic [width_p-1:0] bsg_sync1_flop_r;
   logic [width_p-1:0] bsg_sync2_flop_r;

   assign oclk_data_o = bsg_sync2_flop_r;

   // mbt fixme, for GF28, we should be instantiating the meta-hardened flop
   // mbt fixme; might want to put an explicit buffer on output iclk_data_o
   // to reduce loading on launch flop

   always @(posedge oclk_i)
     begin
        bsg_sync1_flop_r <= iclk_data_i;
        bsg_sync2_flop_r <= bsg_sync1_flop_r;
     end

endmodule

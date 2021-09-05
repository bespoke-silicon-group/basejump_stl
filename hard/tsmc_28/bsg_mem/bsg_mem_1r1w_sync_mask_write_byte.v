//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//

`include "bsg_defines.v"

module bsg_mem_1r1w_sync_mask_write_byte #(parameter `BSG_INV_PARAM(width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter addr_width_lp=$clog2(els_p)
                         , parameter write_mask_width_lp = data_width_p>>3
                          // whether to substitute a 1r1w
                          , parameter read_write_same_addr_p=0
                          , parameter disable_collision_warning_p=0
                          , parameter harden_p=1)
   (input   clk_i
    , input reset_i

    , input w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0] w_data_i
    , input [write_mask_width_lp-1:0] w_mask_i

    , input r_v_i
    , input [addr_width_lp-1:0] r_addr_i
    , output logic [width_p-1:0] r_data_o
    );

  logic [width_p-1:0] w_mask_li;
  bsg_expand_bitmask
   #(.in_width_p(write_mask_width_lp), .expand_p(8))
   wmask_expand
    (.i(w_mask_i)
     ,.o(w_mask_li)
     );

  bsg_mem_1r1w_sync_mask_write_bit
   #(.width_p(width_p), .els_p(els_p))
   bit_mem
    (.w_mask_i(w_mask_li), .*);

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_byte)

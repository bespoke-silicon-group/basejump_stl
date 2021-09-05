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

    , input a_v_i
    , input a_w_i
    , input [addr_width_lp-1:0] a_w_addr_i
    , input [width_p-1:0] a_data_i
    , input [write_mask_width_lp-1:0] a_w_mask_i

    , input b_v_i
    , input b_w_i
    , input [addr_width_lp-1:0] b_w_addr_i
    , input [width_p-1:0] b_data_i
    , input [write_mask_width_lp-1:0] b_w_mask_i

    , output logic [width_p-1:0] a_data_o
    , output logic [width_p-1:0] b_data_o
    );

  logic [width_p-1:0] a_w_mask_li;
  bsg_expand_bitmask
   #(.in_width_p(write_mask_width_lp), .expand_p(8))
   a_wmask_expand
    (.i(a_w_mask_i)
     ,.o(a_w_mask_li)
     );

  logic [width_p-1:0] b_w_mask_li;
  bsg_expand_bitmask
   #(.in_width_p(write_mask_width_lp), .expand_p(8))
   b_wmask_expand
    (.i(b_w_mask_i)
     ,.o(b_w_mask_li)
     );

  bsg_mem_2rw_sync_mask_write_bit
   #(.width_p(width_p), .els_p(els_p))
   bit_mem
    (.a_w_mask_i(a_w_mask_li), .b_w_mask_i(b_w_mask_i), .*);

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_byte)

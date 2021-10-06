
module bsg_mem_1rw_sync_mask_write_byte #( parameter `BSG_INV_PARAM(width_p)
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter write_mask_width_lp = data_width_p>>3
                         , parameter harden_p = 1
                         , parameter latch_last_read_p = 1
                         )
  ( input                           clk_i
  , input                           reset_i

  , input [width_p-1:0]             data_i
  , input [addr_width_lp-1:0]       addr_i
  , input                           v_i
  , input                           w_i
  , input [write_mask_width_lp-1:0] w_mask_i

  , output logic [width_p-1:0]      data_o
  );

  logic [width_p-1:0] w_mask_li;
  bsg_expand_bitmask
   #(.in_width_p(write_mask_width_lp), .expand_p(8))
   wmask_expand
    (.i(w_mask_i)
     ,.o(w_mask_li)
     );

  bsg_mem_1rw_sync_mask_write_bit
   #(.width_p(width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p))
   bit_mem
    (.w_mask_i(w_mask_li), .*);

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_byte)


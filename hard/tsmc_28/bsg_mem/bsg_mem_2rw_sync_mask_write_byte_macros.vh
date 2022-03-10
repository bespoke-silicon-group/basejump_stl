`ifndef BSG_MEM_2RW_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_2RW_SYNC_MASK_WRITE_BYTE_MACROS_VH

`define bsg_mem_2rw_sync_mask_write_byte_2rf_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_2rw_sync_mask_write_byte_2sram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_2rw_sync_mask_write_byte_2hdsram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_byte_macro(words,bits)

`define bsg_mem_2rw_sync_mask_write_byte_macro(words,bits) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: wrap                                                   \
  logic [width_p-1:0] a_w_mask_li;                              \
  bsg_expand_bitmask                                            \
   #(.in_width_p(write_mask_width_lp), .expand_p(8))            \
   a_wmask_expand                                               \
    (.i(a_w_mask_i)                                             \
     ,.o(a_w_mask_li)                                           \
     );                                                         \
                                                                \
  logic [width_p-1:0] b_w_mask_li;                              \
  bsg_expand_bitmask                                            \
   #(.in_width_p(write_mask_width_lp), .expand_p(8))            \
   b_wmask_expand                                               \
    (.i(b_w_mask_i)                                             \
     ,.o(b_w_mask_li)                                           \
     );                                                         \
                                                                \
  bsg_mem_2rw_sync_mask_write_bit                               \
   #(.width_p(width_p), .els_p(els_p))                          \
   bit_mem                                                      \
    (.a_w_mask_i(a_w_mask_li), .b_w_mask_i(b_w_mask_i), .*);    \
  end

`endif 

`ifndef BSG_MEM_1R1W_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MASK_WRITE_BYTE_MACROS_VH

//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//

`define bsg_mem_1r1w_sync_mask_write_byte_2rf_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_1r1w_sync_mask_write_byte_2sram_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_1r1w_sync_mask_write_byte_2hdsram_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_mask_write_byte_macro(words,bits)

`define bsg_mem_1r1w_sync_mask_write_byte_macro(words,bits) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: wrap                                                   \
    logic [width_p-1:0] w_mask_li;                              \
    bsg_expand_bitmask                                          \
     #(.in_width_p(write_mask_width_lp), .expand_p(8))          \
     wmask_expand                                               \
      (.i(w_mask_i)                                             \
       ,.o(w_mask_li)                                           \
       );                                                       \
                                                                \
    bsg_mem_1r1w_sync_mask_write_bit                            \
     #(.width_p(width_p), .els_p(els_p))                        \
     bit_mem                                                    \
      (.w_mask_i(w_mask_li), .*);                               \
  end

`endif 

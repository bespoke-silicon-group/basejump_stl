`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS_VH

`define bsg_mem_1rw_sync_mask_write_byte_1rf_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits)
`define bsg_mem_1rw_sync_mask_write_byte_1hdsram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits)

`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits) \
if (harden_p && els_p == words && data_width_p == bits)         \
  begin: wrap                                                   \
    logic [data_width_p-1:0] w_mask_li;                         \
    bsg_expand_bitmask                                          \
     #(.in_width_p(write_mask_width_lp), .expand_p(8))          \
     wmask_expand                                               \
      (.i(write_mask_i)                                         \
       ,.o(w_mask_li)                                           \
       );                                                       \
                                                                \
    bsg_mem_1rw_sync_mask_write_bit                             \
     #(.width_p(data_width_p), .els_p(els_p))                   \
     bit_mem                                                    \
      (.w_mask_i(w_mask_li), .*);                               \
  end

`define bsg_mem_1rw_sync_mask_write_byte_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && data_width_p == bits) begin: macro        \
      bsg_mem_1rw_sync_mask_write_byte_banked #(                              \
        .data_width_p(data_width_p)                                           \
        ,.els_p(els_p)                                                        \
        ,.latch_last_read_p(latch_last_read_p)                                \
        ,.num_width_bank_p(wbank)                                             \
        ,.num_depth_bank_p(dbank)                                             \
      ) bmem (                                                                \
        .clk_i(clk_i)                                                         \
        ,.reset_i(reset_i)                                                    \
        ,.v_i(v_i)                                                            \
        ,.w_i(w_i)                                                            \
        ,.addr_i(addr_i)                                                      \
        ,.data_i(data_i)                                                      \
        ,.write_mask_i(write_mask_i)                                          \
        ,.data_o(data_o)                                                      \
      );                                                                      \
    end: macro

`endif 

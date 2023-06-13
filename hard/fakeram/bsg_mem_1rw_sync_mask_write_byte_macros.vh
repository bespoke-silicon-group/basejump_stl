
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS

`define bsg_mem_1rw_sync_mask_write_byte_1rf_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits)
`define bsg_mem_1rw_sync_mask_write_byte_1hdsram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits)

`define bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits,tag) \
  if (els_p == words && data_width_p == bits)                        \
    begin: macro                                                     \
       logic [data_width_p-1:0] w_mask_lo;                           \
       bsg_expand_bitmask                                            \
        #(.in_width_p(write_mask_width_lp), .expand_p(8))            \
        wmask_expand                                                 \
         (.i(write_mask_i)                                           \
          ,.o(w_mask_lo)                                             \
          );                                                         \
                                                                     \
       fakeram_d``words``_w``bits`` mem                              \
         (.clk(clk_i)                                                \
         ,.ce_in(v_i)                                                \
         ,.we_in(w_i)                                                \
         ,.wd_in(data_i)                                             \
         ,.w_mask_in(w_mask_lo)                                      \
         ,.addr_in(addr_i)                                           \
         ,.rd_out(data_o)                                            \
         );                                                          \
    end

`endif
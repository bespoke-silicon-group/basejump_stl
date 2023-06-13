
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS

`define bsg_mem_1rw_sync_mask_write_bit_1rf_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_bit_1sram_macro(words,bits)
`define bsg_mem_1rw_sync_mask_write_bit_1hdsram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_bit_1sram_macro(words,bits)

`define bsg_mem_1rw_sync_mask_write_bit_1sram_macro(words,bits,tag) \
  if (els_p == words && width_p == bits)                            \
    begin: macro                                                    \
       fakeram_d``words``_w``bits`` mem                             \
         (.clk(clk_i)                                               \
         ,.ce_in(v_i)                                               \
         ,.we_in(w_i)                                               \
         ,.wd_in(data_i)                                            \
         ,.w_mask_in(w_mask_i)                                      \
         ,.addr_in(addr_i)                                          \
         ,.rd_out(data_o)                                           \
         );                                                         \
    end

`endif
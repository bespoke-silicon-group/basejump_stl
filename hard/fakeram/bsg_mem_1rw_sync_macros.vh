
`ifndef BSG_MEM_1RW_SYNC_MACROS
`define BSG_MEM_1RW_SYNC_MACROS

`define bsg_mem_1rw_sync_1sram_macro(words,bits,tag) \
  if (els_p == words && width_p == bits)             \
    begin: macro                                     \
       fakeram_d``words``_w``bits`` mem              \
         (.clk(i_clk)                                \
         ,.ce_in(clk_en_lo)                          \
         ,.we_in(w_i)                                \
         ,.wd_in(data_i)                             \
         ,.w_mask_in(-1)                             \
         ,.addr_in(addr_i)                           \
         ,.rd_out(data_o)                            \
         );                                          \
    end

`endif
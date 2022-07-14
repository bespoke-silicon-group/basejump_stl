
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS

`define bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits,tag) \
  if (els_p == words && data_width_p == bits)                        \
    begin: macro                                                     \
       wire [data_width_p-1:0]w_mask_lo;                             \
       genvar i;                                                     \
       for(i=0; i<data_width_p; i++)                                 \
          assign w_mask_lo[i] = write_mask_i[i>>3];                  \
                                                                     \
       fakeram_d``words``_w``bits`` mem                              \
         (.clk(i_clk)                                                \
         ,.ce_in(clk_en_lo)                                          \
         ,.we_in(w_i)                                                \
         ,.wd_in(data_i)                                             \
         ,.w_mask_in(w_mask_lo)                                      \
         ,.addr_in(addr_i)                                           \
         ,.rd_out(data_o)                                            \
         );                                                          \
    end

`endif
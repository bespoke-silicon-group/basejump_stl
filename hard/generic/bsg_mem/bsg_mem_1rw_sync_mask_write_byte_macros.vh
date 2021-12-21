
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS

`define bsg_mem_1rw_sync_mask_write_byte_1rf_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,tag)
`define bsg_mem_1rw_sync_mask_write_byte_1sram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,tag)
`define bsg_mem_1rw_sync_mask_write_byte_1hdsram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,tag)

`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,tag) \
  if (harden_p && els_p == words && data_width_p == bits)      \
    begin: macro                                               \
      bsg_mem_1rw_sync_mask_write_byte_w``bits``_d``words``_``tag``_hard mem (.*); \
    end: macro

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


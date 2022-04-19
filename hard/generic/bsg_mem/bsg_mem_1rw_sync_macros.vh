
`ifndef BSG_MEM_1RW_SYNC_MACROS_VH
`define BSG_MEM_1RW_SYNC_MACROS_VH

`define bsg_mem_1rw_sync_1rf_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_macro(words,bits,tag)
`define bsg_mem_1rw_sync_1sram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_macro(words,bits,tag)
`define bsg_mem_1rw_sync_1hdsram_macro(words,bits,tag) \
  `bsg_mem_1rw_sync_macro(words,bits,tag)

`define bsg_mem_1rw_sync_macro(words,bits,tag)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      bsg_mem_1rw_sync_w``bits``_d``words``_``tag``_hard mem (.*); \
    end: macro

`define bsg_mem_1rw_sync_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro \
    bsg_mem_1rw_sync_banked #(                                              \
      .width_p(width_p)                                                     \
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
      ,.data_o(data_o)                                                      \
    );                                                                      \
  end: macro

`endif


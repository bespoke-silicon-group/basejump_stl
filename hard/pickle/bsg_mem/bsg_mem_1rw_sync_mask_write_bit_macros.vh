
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits) \
  if (els_p == words && width_p == bits)                  \
    begin: macro                                          \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper  \
        mem                                               \
          (.clk_i   (clk_i)                               \
          ,.reset_i (reset_i)                             \
          ,.data_i  (data_i)                              \
          ,.addr_i  (addr_i)                              \
          ,.v_i     (v_i)                                 \
          ,.w_mask_i(w_mask_i)                            \
          ,.w_i     (w_i)                                 \
          ,.data_o  (data_o)                              \
          );                                              \
    end: macro

`define bsg_mem_1rw_sync_mask_write_bit_banked_macro(words,bits,wbank,dbank) \
  if (els_p == words && width_p == bits) begin: macro                         \
      bsg_mem_1rw_sync_mask_write_bit_banked #(                               \
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
        ,.w_mask_i(w_mask_i)                                                  \
        ,.data_o(data_o)                                                      \
      );                                                                      \
    end: macro

`endif


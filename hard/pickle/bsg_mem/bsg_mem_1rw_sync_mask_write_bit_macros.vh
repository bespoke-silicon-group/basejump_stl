
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

`define bsg_mem_1rw_sync_mask_write_bit_macro_banks(words,bits) \
  if (els_p == words && width_p == 2*``bits``)                  \
    begin: macro                                                \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper        \
        mem0                                                    \
          (.clk_i   (clk_i)                                     \
          ,.reset_i (reset_i)                                   \
          ,.data_i  (data_i[width_p/2-1:0])                     \
          ,.addr_i  (addr_i)                                    \
          ,.v_i     (v_i)                                       \
          ,.w_mask_i(w_mask_i[width_p/2-1:0])                   \
          ,.w_i     (w_i)                                       \
          ,.data_o  (data_o[width_p/2-1:0])                     \
          );                                                    \
      hard_mem_1rw_bit_mask_d``words``_w``bits``_wrapper        \
        mem1                                                    \
          (.clk_i   (clk_i)                                     \
          ,.reset_i (reset_i)                                   \
          ,.data_i  (data_i[width_p-1:width_p/2])               \
          ,.addr_i  (addr_i)                                    \
          ,.v_i     (v_i)                                       \
          ,.w_mask_i(w_mask_i[width_p-1:width_p/2])             \
          ,.w_i     (w_i)                                       \
          ,.data_o  (data_o[width_p-1:width_p/2])               \
          );                                                    \
    end: macro

`endif


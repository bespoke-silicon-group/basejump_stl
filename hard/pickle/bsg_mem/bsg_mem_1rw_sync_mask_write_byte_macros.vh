
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS_VH

`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits) \
  if (els_p == words && data_width_p == bits)              \
    begin: macro                                           \
      hard_mem_1rw_byte_mask_d``words``_w``bits``_wrapper  \
        mem                                                \
          (.clk_i        (clk_i)                           \
          ,.reset_i      (reset_i)                         \
          ,.v_i          (v_i)                             \
          ,.w_i          (w_i)                             \
          ,.addr_i       (addr_i)                          \
          ,.data_i       (data_i)                          \
          ,.write_mask_i (write_mask_i)                    \
          ,.data_o       (data_o)                          \
          );                                               \
    end: macro

`endif


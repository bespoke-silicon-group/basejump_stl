
`ifndef BSG_MEM_1R1W_SYNC_MASK_WRITE_BIT_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MASK_WRITE_BIT_MACROS_VH

`define bsg_mem_1r1w_sync_mask_write_bit_macro(words,bits,mux)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_1r1w_sync_mask_write_bit_synth #(               \
        .width_p(width_p)                                     \
        ,.els_p(els_p)                                        \
        ,.read_write_same_addr_p(read_write_same_addr_p)      \
      ) synth (.*);                                           \
    end
      
`endif



`ifndef BSG_MEM_1R1W_SYNC_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MACROS_VH

`define bsg_mem_1r1w_sync_macro(words,bits,mux)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_1r1w_sync_synth #(                              \
        .width_p(width_p)                                     \
        ,.els_p(els_p)                                        \
        ,.read_write_same_addr_p(read_write_same_addr_p)      \
      ) synth (.*);                                           \
    end
      
`endif



`ifndef BSG_MEM_1RW_SYNC_MACROS_VH
`define BSG_MEM_1RW_SYNC_MACROS_VH

`define bsg_mem_1rw_sync_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      bsg_mem_1rw_sync_synth #(                      \
        .width_p(width_p)                            \
        ,.els_p(els_p)                               \
        ,.latch_last_read_p(latch_last_read_p)       \
      ) synth (.*);                                  \
    end: macro

`endif


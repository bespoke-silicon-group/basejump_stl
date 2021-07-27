
`ifndef BSG_MEM_1RW_SYNC_MACROS_VH
`define BSG_MEM_1RW_SYNC_MACROS_VH

`define bsg_mem_1rw_sync_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      bsg_mem_1rw_sync_w``bits``_d``words``_m``mux``_hard mem (.*); \
    end: macro

`endif


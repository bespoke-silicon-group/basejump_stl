
`ifndef BSG_MEM_1R1W_SYNC_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MACROS_VH

`define bsg_mem_1r1w_sync_2rf_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_macro(words,bits,tag)
`define bsg_mem_1r1w_sync_2sram_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_macro(words,bits,tag)
`define bsg_mem_1r1w_sync_2hdsram_macro(words,bits,tag) \
  `bsg_mem_1r1w_sync_macro(words,bits,tag)

`define bsg_mem_1r1w_sync_macro(words,bits,tag)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_1r1w_sync_w``bits``_d``words``_``tag``_hard mem (.*); \
    end
      
`endif


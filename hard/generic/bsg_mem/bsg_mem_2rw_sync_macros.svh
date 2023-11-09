
`ifndef BSG_MEM_2RW_SYNC_MACROS_VH
`define BSG_MEM_2RW_SYNC_MACROS_VH

`define bsg_mem_2rw_sync_2rf_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_macro(words,bits,tag)
`define bsg_mem_2rw_sync_2sram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_macro(words,bits,tag)
`define bsg_mem_2rw_sync_2hdsram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_macro(words,bits,tag)

`define bsg_mem_2rw_sync_macro(words,bits,tag)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_2rw_sync_w``bits``_d``words``_``tag``_hard mem (.*); \
    end
      
`endif


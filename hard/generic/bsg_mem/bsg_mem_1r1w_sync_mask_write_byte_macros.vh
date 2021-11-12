
`ifndef BSG_MEM_1R1W_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MASK_WRITE_BYTE_MACROS_VH

`define bsg_mem_1r1w_sync_mask_write_byte_macro(words,bytes,tag)\
  if (harden_p && els_p == words && width_p == bytes)         \
    begin: macro                                              \
      bsg_mem_1r1w_sync_mask_write_byte_w``bits``_d``words``_``tag``_hard mem (.*); \
    end
      
`endif



`ifndef BSG_MEM_2RW_SYNC_MASK_WRITE_BYTE_MACROS_VH
`define BSG_MEM_2RW_SYNC_MASK_WRITE_BYTE_MACROS_VH

`define bsg_mem_2rw_sync_mask_write_byte_macro(words,bits,tag)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_2rw_sync_mask_write_byte_w``bits``_d``words``_``tag``_hard mem (.*); \
    end
      
`endif


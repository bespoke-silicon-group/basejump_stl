
`ifndef BSG_MEM_2RW_SYNC_MASK_WRITE_BIT_MACROS_VH
`define BSG_MEM_2RW_SYNC_MASK_WRITE_BIT_MACROS_VH

`define bsg_mem_2rw_sync_mask_write_bit_2rf_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_bit_macro(words,bits,tag)
`define bsg_mem_2rw_sync_mask_write_bit_2sram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_bit_macro(words,bits,tag)
`define bsg_mem_2rw_sync_mask_write_bit_2hdsram_macro(words,bits,tag) \
  `bsg_mem_2rw_sync_mask_write_bit_macro(words,bits,tag)

`define bsg_mem_2rw_sync_mask_write_bit_macro(words,bits,tag)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      bsg_mem_2rw_sync_mask_write_bit_w``bits``_d``words``_``tag``_hard mem (.*); \
    end
      
`endif


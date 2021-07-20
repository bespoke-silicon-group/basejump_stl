
`ifndef BSG_MEM_3R1W_SYNC_MACROS_VH
`define BSG_MEM_3R1W_SYNC_MACROS_VH

`define bsg_mem_3r1w_sync_macro(words,bits)      \
  if (els_p == words && width_p == bits)         \
    begin: macro                                 \
      hard_mem_1r1w_d``words``_w``bits``_wrapper \
        mem0                                     \
          (.clk_i   ( clk_i     )                \
          ,.reset_i ( reset_i   )                \
          ,.w_v_i   ( w_v_i     )                \
          ,.w_addr_i( w_addr_i  )                \
          ,.w_data_i( w_data_i  )                \
          ,.r_v_i   ( r0_v_i    )                \
          ,.r_addr_i( r0_addr_i )                \
          ,.r_data_o( r0_data_o )                \
          );                                     \
      hard_mem_1r1w_d``words``_w``bits``_wrapper \
        mem1                                     \
          (.clk_i   ( clk_i     )                \
          ,.reset_i ( reset_i   )                \
          ,.w_v_i   ( w_v_i     )                \
          ,.w_addr_i( w_addr_i  )                \
          ,.w_data_i( w_data_i  )                \
          ,.r_v_i   ( r1_v_i    )                \
          ,.r_addr_i( r1_addr_i )                \
          ,.r_data_o( r1_data_o )                \
          );                                     \
      hard_mem_1r1w_d``words``_w``bits``_wrapper \
        mem2                                     \
          (.clk_i   ( clk_i     )                \
          ,.reset_i ( reset_i   )                \
          ,.w_v_i   ( w_v_i     )                \
          ,.w_addr_i( w_addr_i  )                \
          ,.w_data_i( w_data_i  )                \
          ,.r_v_i   ( r2_v_i    )                \
          ,.r_addr_i( r2_addr_i )                \
          ,.r_data_o( r2_data_o )                \
          );                                     \
    end

`endif


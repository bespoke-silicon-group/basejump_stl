
`ifndef BSG_MEM_3R1W_SYNC_MACROS
`define BSG_MEM_3R1W_SYNC_MACROS

`define bsg_mem_3r1w_sync_2rf_macro(words,bits,tag)  \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1r1w_d``words``_w``bits``_``tag``_2rf    \
        mem0                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r0_v_i   )                     \
          , .AA    ( r0_addr_i )                     \
          , .QA    ( r0_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
      gf14_1r1w_d``words``_w``bits``_``tag``_2rf    \
        mem1                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r1_v_i   )                     \
          , .AA    ( r1_addr_i )                     \
          , .QA    ( r1_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
      gf14_1r1w_d``words``_w``bits``_``tag``_2rf    \
        mem2                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r2_v_i   )                     \
          , .AA    ( r2_addr_i )                     \
          , .QA    ( r2_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
    end: macro

`define bsg_mem_3r1w_sync_2sram_macro(words,bits,tag)\
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1r1w_d``words``_w``bits``_``tag``_2sram  \
        mem0                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r0_v_i   )                     \
          , .AA    ( r0_addr_i )                     \
          , .QA    ( r0_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
      gf14_1r1w_d``words``_w``bits``_``tag``_2sram  \
        mem1                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r1_v_i   )                     \
          , .AA    ( r1_addr_i )                     \
          , .QA    ( r1_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
      gf14_1r1w_d``words``_w``bits``_``tag``_2sram  \
        mem2                                         \
          ( .CLKA  ( clk_i     )                     \
          , .CLKB  ( clk_i     )                     \
          , .CENA  ( ~r2_v_i   )                     \
          , .AA    ( r2_addr_i )                     \
          , .QA    ( r2_data_o )                     \
          , .CENB  ( ~w_v_i    )                     \
          , .AB    ( w_addr_i  )                     \
          , .DB    ( w_data_i  )                     \
          , .EMAA  ( 3'b011    )                     \
          , .EMAB  ( 3'b011    )                     \
          , .EMASA ( 1'b0      )                     \
          , .STOV  ( 1'b0      )                     \
          , .RET1N ( 1'b1      )                     \
          );                                         \
    end: macro

`endif


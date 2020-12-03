
`ifndef BSG_MEM_1R1W_SYNC_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MACROS_VH

`define bsg_mem_1r1w_sync_macro(words,bits,mux)\
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
    gf14_1r1w_d``words``_w``bits``_m``mux                     \
      mem (                                                   \
      .CLKA   (clk_i)                                         \
      ,.CLKB  (clk_i)                                         \
      ,.CENA  (~r_v_i)                                        \
      ,.AA    (r_addr_i)                                      \
      ,.QA    (r_data_o)                                      \
      ,.CENB  (~w_v_i)                                        \
      ,.AB    (w_addr_i)                                      \
      ,.DB    (w_data_i)                                      \
      ,.EMAA  (3'b011)                                        \
      ,.EMAB  (3'b011)                                        \
      ,.EMASA (1'b0)                                          \
      ,.STOV  (1'b0)                                          \
      ,.RET1N (1'b1)                                          \
    );                                                        \
  end
      
`endif


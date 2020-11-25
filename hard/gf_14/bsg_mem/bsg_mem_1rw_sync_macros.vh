
`ifndef BSG_MEM_1RW_SYNC_MACROS_VH
`define BSG_MEM_1RW_SYNC_MACROS_VH

`define bsg_mem_1rw_sync_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1rw_d``words``_w``bits``_m``mux           \
        mem                                          \
          ( .CLK   ( clk_i  )                        \
          , .A     ( addr_i )                        \
          , .D     ( data_i )                        \
          , .Q     ( data_o )                        \
          , .CEN   ( ~v_i   )                        \
          , .GWEN  ( ~w_i   )                        \
          , .RET1N ( 1'b1   )                        \
          , .STOV  ( 1'b0   )                        \
          , .EMA   ( 3'b011 )                        \
          , .EMAW  ( 2'b01  )                        \
          , .EMAS  ( 1'b0   )                        \
          );                                         \
    end: macro

`endif


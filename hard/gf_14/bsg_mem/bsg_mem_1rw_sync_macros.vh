
`ifndef BSG_MEM_1RW_SYNC_MACROS_VH
`define BSG_MEM_1RW_SYNC_MACROS_VH

`define bsg_mem_1rw_sync_1rf_macro(words,bits,tag)   \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1rw_d``words``_w``bits``_``tag``_1rf      \
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

`define bsg_mem_1rw_sync_1sram_macro(words,bits,tag) \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1rw_d``words``_w``bits``_``tag``_1sram    \
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

`define bsg_mem_1rw_sync_1hdsram_macro(words,bits,tag) \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1rw_d``words``_w``bits``_``tag``_1hdsram  \
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

`define bsg_mem_1rw_sync_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro \
    bsg_mem_1rw_sync_banked #(                                              \
      .width_p(width_p)                                                     \
      ,.els_p(els_p)                                                        \
      ,.latch_last_read_p(latch_last_read_p)                                \
      ,.num_width_bank_p(wbank)                                             \
      ,.num_depth_bank_p(dbank)                                             \
    ) bmem (                                                                \
      .clk_i(clk_i)                                                         \
      ,.reset_i(reset_i)                                                    \
      ,.v_i(v_i)                                                            \
      ,.w_i(w_i)                                                            \
      ,.addr_i(addr_i)                                                      \
      ,.data_i(data_i)                                                      \
      ,.data_o(data_o)                                                      \
    );                                                                      \
  end: macro

`endif


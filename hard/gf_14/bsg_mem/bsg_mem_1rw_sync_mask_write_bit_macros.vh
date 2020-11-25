
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BIT_MACROS

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits,mux) \
  if (harden_p && els_p == words && width_p == bits)          \
    begin: macro                                              \
      gf14_1rw_d``words``_w``bits``_m``mux``_bit              \
        mem                                                   \
          ( .CLK   ( clk_i     )                              \
          , .A     ( addr_i    )                              \
          , .D     ( data_i    )                              \
          , .Q     ( data_o    )                              \
          , .CEN   ( ~v_i      )                              \
          , .GWEN  ( ~w_i      )                              \
          , .WEN   ( ~w_mask_i )                              \
          , .RET1N ( 1'b1      )                              \
          , .STOV  ( 1'b0      )                              \
          , .EMA   ( 3'b011    )                              \
          , .EMAW  ( 2'b01     )                              \
          , .EMAS  ( 1'b0      )                              \
          );                                                  \
    end: macro

`define bsg_mem_1rw_sync_mask_write_bit_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro \
    bsg_mem_1rw_sync_mask_write_bit_banked #(                     \
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
      ,.w_mask_i(w_mask_i)                                                  \
      ,.data_o(data_o)                                                      \
    );                                                                      \
  end: macro

`endif


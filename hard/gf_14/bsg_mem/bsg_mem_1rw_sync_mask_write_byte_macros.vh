
`ifndef BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS
`define BSG_MEM_1RW_SYNC_MASK_WRITE_BYTE_MACROS

`define bsg_mem_1rw_sync_mask_write_byte_macro(words,bits,mux) \
  if (harden_p && els_p == words && data_width_p == bits)      \
    begin: macro                                               \
      wire [data_width_p-1:0] wen;                             \
      genvar j;                                                \
      for(j = 0; j < write_mask_width_lp; j++)                 \
        assign wen[8*j+:8] = {8{write_mask_i[j]}};             \
                                                               \
      gf14_1rw_d``words``_w``bits``_m``mux``_byte              \
        mem                                                    \
          ( .CLK   ( clk_i  )                                  \
          , .A     ( addr_i )                                  \
          , .D     ( data_i )                                  \
          , .Q     ( data_o )                                  \
          , .CEN   ( ~v_i   )                                  \
          , .GWEN  ( ~w_i   )                                  \
          , .WEN   ( ~wen   )                                  \
          , .RET1N ( 1'b1   )                                  \
          , .STOV  ( 1'b0   )                                  \
          , .EMA   ( 3'b011 )                                  \
          , .EMAW  ( 2'b01  )                                  \
          , .EMAS  ( 1'b0   )                                  \
          );                                                   \
    end: macro

`define bsg_mem_1rw_sync_mask_write_byte_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && data_width_p == bits) begin: macro        \
      bsg_mem_1rw_sync_mask_write_byte_banked #(                              \
        .data_width_p(data_width_p)                                           \
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
        ,.write_mask_i(write_mask_i)                                          \
        ,.data_o(data_o)                                                      \
      );                                                                      \
    end: macro

`endif


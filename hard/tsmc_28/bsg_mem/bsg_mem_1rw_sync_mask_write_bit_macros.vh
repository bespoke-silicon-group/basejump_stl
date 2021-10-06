
`define bsg_mem_1rw_sync_mask_write_bit_1rf_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1rf_bit mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
             ,.CLKW     ( clk_i         )                       \
            );                                                  \
    end

`define bsg_mem_1rw_sync_mask_write_bit_1sram_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1sram_bit mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
             ,.CLKW     ( clk_i         )                       \
            );                                                  \
    end

`define bsg_mem_1rw_sync_1hdsram_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1hdsram_bit mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
             ,.RTSEL    ( 2'01          )                       \
             ,.WTSEL    ( 2'00          )                       \
            );                                                  \
    end

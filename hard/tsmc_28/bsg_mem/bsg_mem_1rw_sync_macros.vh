
`define bsg_mem_1rw_sync_1rf_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1rf mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
            );                                                  \
    end

`define bsg_mem_1rw_sync_1sram_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1sram mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
            );                                                  \
    end

`define bsg_mem_1rw_sync_1hdsram_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1hdsram mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
             ,.RTSEL    ( 2'01          )                       \
             ,.WTSEL    ( 2'00          )                       \
            );                                                  \
    end

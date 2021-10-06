//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//

`define bsg_mem_1r1w_sync_2rf_macro(words,bits,mux) \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          tsmc28_1r1w_d``words``_w``bits``_m``mux``_2rf mem \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.REB      ( ~r_v_i        )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r_data_o      )                       \
            );                                                  \
  end

`define bsg_mem_1r1w_sync_mask_write_2sram_bit_macro(words,bits,mux) \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_m``mux``_2sram_bit mem \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( '1            )                       \
             ,.WEBB     ( '1            )                       \
             ,.CEBB     ( ~r_v_i        )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.QB       ( r_data_o      )                       \
                                                                \
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \
            );                                                  \
  end

`define bsg_mem_1r1w_sync_mask_write_2hdsram_bit_macro(words,bits,mux) \
if (els_p == words && width_p == bits)                          \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_m``mux``_2hdsram_bit mem \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( '1            )                       \
             ,.WEBB     ( '1            )                       \
             ,.CEBB     ( ~r_v_i        )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.QB       ( r_data_o      )                       \
                                                                \
             ,.WTSEL    ( 2'b00         )                       \
             ,.RTSEL    ( 2'b00         )                       \
             ,.PTSEL    ( 2'b00         )                       \
            );                                                  \
  end

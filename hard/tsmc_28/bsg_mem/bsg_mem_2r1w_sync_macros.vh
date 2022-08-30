
`ifndef BSG_MEM_2R1W_SYNC_MACROS_VH
`define BSG_MEM_2R1W_SYNC_MACROS_VH

`define bsg_mem_2r1w_sync_2rf_macro(words,bits,tag) \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                                \
          tsmc28_1r1w_d``words``_w``bits``_``tag``_2rf mem0     \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r0_addr_i     )                       \
             ,.REB      ( ~r0_v_i       )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r0_data_o     )                       \
            );                                                  \
          tsmc28_1r1w_d``words``_w``bits``_``tag``_2rf mem1     \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r1_addr_i     )                       \
             ,.REB      ( ~r1_v_i       )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r1_data_o     )                       \
            );                                                  \
    end: macro

`define bsg_mem_2r1w_sync_2sram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2sram mem0    \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r0_addr_i     )                       \
             ,.DB       ( {bits{1'b1}   )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r0_v_i       )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.QB       ( r0_data_o     )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \
            );                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2sram mem1    \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r1_addr_i     )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r1_v_i       )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.QB       ( r1_data_o     )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \
            );                                                  \
  end

`define bsg_mem_2r1w_sync_2hdsram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2hdsram mem0  \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLK      ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r0_addr_i     )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r0_v_i       )                       \
             ,.QB       ( r0_data_o     )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b00         )                       \
             ,.RTSEL    ( 2'b00         )                       \
             ,.PTSEL    ( 2'b00         )                       \
            );                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2hdsram mem1  \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLK      ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r1_addr_i     )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r1_v_i       )                       \
             ,.QB       ( r1_data_o     )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b00         )                       \
             ,.RTSEL    ( 2'b00         )                       \
             ,.PTSEL    ( 2'b00         )                       \
            );                                                  \
  end

`endif


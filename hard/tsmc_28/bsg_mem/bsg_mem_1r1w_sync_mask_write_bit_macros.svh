`ifndef BSG_MEM_1R1W_SYNC_MASK_WRITE_BIT_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MASK_WRITE_BIT_MACROS_VH

`define bsg_mem_1r1w_sync_mask_write_bit_2rf_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_1r1w_d``words``_w``bits``_``tag``_bit_2rf mem  \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.D        ( w_data_i      )                       \
             ,.WEB      ( ~w_v_i        )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
             ,.CLKW     ( clk_i         )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.REB      ( ~r_v_i        )                       \
             ,.CLKR     ( clk_i         )                       \
             ,.Q        ( r_data_o      )                       \
            );                                                  \
  end

`define bsg_mem_1r1w_sync_mask_write_bit_2sram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_bit_2sram mem \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.BWEBA    ( ~w_mask_i     )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
             ,.BWEBB    ( {bits{1'b1}}  )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r_v_i        )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.QB       ( r_data_o      )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \
            );                                                  \
  end

`define bsg_mem_1r1w_sync_mask_write_bit_2hdsram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_bit_2hdsram mem \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.BWEBA    ( ~w_mask_i     )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLK      ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
             ,.BWEBB    ( {bits{1'b1}}  )                       \
             ,.WEBB     ( 1'b1          )                       \
             ,.CEBB     ( ~r_v_i        )                       \
             ,.QB       ( r_data_o      )                       \
                                                                \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b00         )                       \
             ,.RTSEL    ( 2'b00         )                       \
             ,.PTSEL    ( 2'b00         )                       \
            );                                                  \
  end

`endif 

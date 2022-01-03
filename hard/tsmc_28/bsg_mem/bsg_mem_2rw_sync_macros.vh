`ifndef BSG_MEM_2RW_SYNC_MACROS_VH
`define BSG_MEM_2RW_SYNC_MACROS_VH

`define bsg_mem_2rw_sync_2sram_macro(words,bits,tag)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2sram mem  \
            (                                                   \
              .CLKA     ( clk_i         )                       \
             ,.CEBA     ( ~a_v_i        )                       \
             ,.WEBA     ( ~a_w_i        )                       \
             ,.AA       ( a_addr_i      )                       \
             ,.DA       ( a_data_i      )                       \
             ,.QA       ( a_data_o      )                       \
             ,.CLKB     ( clk_i         )                       \
             ,.CEBB     ( ~b_v_i        )                       \
             ,.WEBB     ( ~b_w_i        )                       \
             ,.AB       ( b_addr_i      )                       \
             ,.DB       ( b_data_i      )                       \
             ,.QB       ( b_data_o      )                       \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \
            );                                                  \
    end


`define bsg_mem_2rw_sync_2hdsram_macro(words,bits,tag)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2hdsram mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEBA     ( ~a_v_i        )                       \
             ,.WEBA     ( ~a_w_i        )                       \
             ,.AA       ( a_addr_i      )                       \
             ,.DA       ( a_data_i      )                       \
             ,.QA       ( a_data_o      )                       \
             ,.CEBB     ( ~b_v_i        )                       \
             ,.WEBB     ( ~b_w_i        )                       \
             ,.AB       ( b_addr_i      )                       \
             ,.DB       ( b_data_i      )                       \
             ,.QB       ( b_data_o      )                       \
             /* According to TSMC, other settings are for debug only */ \
             ,.WTSEL    ( 2'b00         )                       \
             ,.RTSEL    ( 2'b00         )                       \
             ,.PTSEL    ( 2'b00         )                       \
            );                                                  \
    end

`endif 

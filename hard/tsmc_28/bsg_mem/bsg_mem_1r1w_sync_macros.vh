`ifndef BSG_MEM_1R1W_SYNC_MACROS_VH
`define BSG_MEM_1R1W_SYNC_MACROS_VH

//
// Synchronous 2-port ram.
//
// When read and write with the same address, the behavior depends on which
// clock arrives first, and the read/write clock MUST be separated at least
// twrcc, otherwise will incur indeterminate result. 
//

`define bsg_mem_1r1w_sync_2rf_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_1r1w_d``words``_w``bits``_``tag``_2rf mem      \
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

`define bsg_mem_1r1w_sync_2sram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2sram mem     \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLKA     ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
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

`define bsg_mem_1r1w_sync_2hdsram_macro(words,bits,tag) \
if (harden_p && els_p == words && width_p == bits)              \
  begin: macro                                                  \
          tsmc28_2rw_d``words``_w``bits``_``tag``_2hdsram mem   \
            (                                                   \
              .AA       ( w_addr_i      )                       \
             ,.DA       ( w_data_i      )                       \
             ,.WEBA     ( ~w_v_i        )                       \
             ,.CEBA     ( ~w_v_i        )                       \
             ,.CLK      ( clk_i         )                       \
             ,.QA       (               )                       \
                                                                \
             ,.AB       ( r_addr_i      )                       \
             ,.DB       ( {bits{1'b1}}  )                       \
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

`define bsg_mem_1r1w_sync_banked_macro(words,bits,wbank,dbank) \
  if (harden_p && els_p == words && width_p == bits) begin: macro \
    bsg_mem_1r1w_sync_banked #(                                             \
      .width_p(width_p)                                                     \
      ,.els_p(els_p)                                                        \
      ,.read_write_same_addr_p(read_write_same_addr_p)                      \
      ,.num_width_bank_p(wbank)                                             \
      ,.num_depth_bank_p(dbank)                                             \
    ) bmem (                                                                \
      .clk_i(clk_i)                                                         \
      ,.reset_i(reset_i)                                                    \
      ,.w_v_i(w_v_i)                                                        \
      ,.w_addr_i(w_addr_i)                                                  \
      ,.w_data_i(w_data_i)                                                  \
      ,.r_v_i(r_v_i)                                                        \
      ,.r_addr_i(r_addr_i)                                                  \
      ,.r_data_o(r_data_o)                                                  \
    );                                                                      \
  end: macro

`endif

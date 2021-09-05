
`define bsg_mem_2rw_sync_2sram_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_2rw_d``words``_w``bits``_m``mux``_2sram mem  \
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
             ,.WTSEL    ( 2'b01         )                       \
             ,.RTSEL    ( 2'b01         )                       \
             ,.VG       ( 1'b1          )                       \
             ,.VS       ( 1'b1          )                       \             
            );                                                  \
    end

module bsg_mem_2rw_sync #( parameter `BSG_INV_PARAM(width_p )
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter harden_p = 1
                         )
  ( input                      clk_i
  , input                      reset_i

  , input [width_p-1:0]        a_data_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [width_p-1:0]        b_data_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [width_p-1:0] a_data_o
  , output logic [width_p-1:0] b_data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_2rw_sync_2sram_macro(512,64,4) else
    begin: notmacro
      bsg_mem_2rw_sync_synth # (.width_p(width_p), .els_p(els_p))
        synth
          (.*);
    end // block: notmacro


  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, (%m)",width_p,els_p);
    end
  // synopsys translate_on

endmodule

`BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync)

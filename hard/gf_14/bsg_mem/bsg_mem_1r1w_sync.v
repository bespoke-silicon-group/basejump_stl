
`define bsg_mem_1r1w_sync_macro(words,bits,mux)      \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
      gf14_1r1w_d``words``_w``bits``_m``mux          \
        mem                                          \
          ( .CLKA  ( clk_i    )                      \
          , .CLKB  ( clk_i    )                      \
          , .AA    ( r_addr_i )                      \
          , .AB    ( w_addr_i )                      \
          , .DB    ( w_data_i )                      \
          , .QA    ( r_data_o )                      \
          , .CENA  ( ~r_v_i   )                      \
          , .CENB  ( ~w_v_i   )                      \
          , .RET1N ( 1'b1     )                      \
          , .STOV  ( 1'b0     )                      \
          , .EMA   ( 3'b011   )                      \
          , .EMAW  ( 2'b01    )                      \
          , .EMAS  ( 1'b0     )                      \
          );                                         \
    end: macro

module bsg_mem_1r1w_sync #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter read_write_same_addr_p=0
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter harden_p=1
                           , parameter disable_collision_warning_p=1
                           , parameter enable_clock_gating_p=0
                           )
   (input                        clk_i
    , input                      reset_i

    , input                      w_v_i
    , input [addr_width_lp-1:0]  w_addr_i
    , input [width_p-1:0]        w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1r1w_sync_macro(512,64,4) else
  `bsg_mem_1r1w_sync_macro(640,32,4) else
  `bsg_mem_1r1w_sync_macro(32,30,4) else

  // no hardened version found
  begin : notmacro
    bsg_mem_1rw_sync_synth # (.width_p(width_p), .els_p(els_p))
      synth
        (.*);
  end


  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
    end
  // synopsys translate_on

endmodule

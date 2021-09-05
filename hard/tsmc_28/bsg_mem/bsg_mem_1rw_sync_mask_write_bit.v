
`define bsg_mem_1rw_sync_mask_write_bit_1rf_macro(words,bits,mux)       \
  if (harden_p && els_p == words && width_p == bits) \
    begin: macro                                     \
          tsmc28_1rw_d``words``_w``bits``_m``mux``_1rf_bit mem  \
            (                                                   \
              .CLK      ( clk_i         )                       \
             ,.CEB      ( ~v_i          )                       \
             ,.WEB      ( ~w_i          )                       \
             ,.BWEB     ( ~w_mask_i     )                       \
              .A        ( addr_i        )                       \
             ,.D        ( data_i        )                       \
             ,.Q        ( data_o        )                       \
             ,.CLKW     ( clk_i         )                       \
            );                                                  \
    end

module bsg_mem_1rw_sync_mask_write_bit #( parameter `BSG_INV_PARAM(width_p)
                         , parameter `BSG_INV_PARAM(els_p )
                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                         , parameter harden_p = 1
                         , parameter latch_last_read_p = 1
                         )
  ( input                     clk_i
  , input                     reset_i

  , input [width_p-1:0]       data_i
  , input [addr_width_lp-1:0] addr_i
  , input                     v_i
  , input                     w_i
  , input [width_p-1:0]       w_mask_i

  , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_bit_1rf_macro(512,64,4) else
    begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth
       #(.width_p(width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p))
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

`BSG_ABSTRACT_MODULE(bsg_mem_1rw_sync_mask_write_bit)

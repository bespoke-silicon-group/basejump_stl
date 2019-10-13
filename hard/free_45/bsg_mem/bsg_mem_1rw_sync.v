// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_macro(words,bits)  \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       free45_1rw_d``words``_w``bits`` mem  \
         (.clk       ( clk_i      )         \
         ,.ce_in     ( v_i        )         \
         ,.we_in     ( w_i        )         \
         ,.addr_in   ( addr_i     )         \
         ,.wd_in     ( data_i     )         \
         ,.w_mask_in ( '1         )         \
         ,.rd_out    ( data_o     )         \
         );                                 \
    end

module bsg_mem_1rw_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter addr_width_lp=$clog2(els_p)
                         )
  (input                      clk_i
  ,input                      reset_i
  ,input [width_p-1:0]        data_i
  ,input [addr_width_lp-1:0]  addr_i
  ,input                      v_i
  ,input                      w_i
  ,output logic [width_p-1:0] data_o
  );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_macro(512,512) else
  `bsg_mem_1rw_sync_macro(256,48) else

      begin: notmacro

        // Instantiate a synthesizable 1rw sync ram
        bsg_mem_1rw_sync_synth #(.width_p(width_p), .els_p(els_p)) synth
          (.*);

      end // block: notmacro

  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d, substitute_1r1w_p=%d (%m)",width_p,els_p,substitute_1r1w_p);
    end
  // synopsys translate_on

endmodule

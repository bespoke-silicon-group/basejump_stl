// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`define bsg_mem_1rw_sync_mask_write_bit_macro(words,bits)  \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       free45_1rw_d``words``_w``bits`` mem  \
         (.clk       ( clk_i     )          \
         ,.ce_in     (  v_i      )          \
         ,.we_in     (  w_i      )          \
         ,.addr_in   ( addr_i    )          \
         ,.wd_in     ( data_i    )          \
         ,.rd_out    ( data_o    )          \
         ,.w_mask_in ( w_mask_i  )          \
         );                                 \
    end

`define bsg_mem_1rw_sync_mask_write_bit_macro_banks(words,bits,banks)  \
  if (els_p == words && width_p == banks*bits)                                   \
    begin: macro                                                                 \
      for (genvar i = 0; i < banks; i++)                                         \
        begin: bank                                                              \
          free45_1rw_d``words``_w``bits`` mem                                    \
            (.clk       ( clk_i                                       )          \
            ,.ce_in     ( v_i                                         )          \
            ,.we_in     ( w_i                                         )          \
            ,.addr_in   ( addr_i                                      )          \
            ,.wd_in     ( data_i[i*(width_p/banks)+:width_p/banks]    )          \
            ,.rd_out    ( data_o[i*(width_p/banks)+:width_p/banks]    )          \
            ,.w_mask_in ( w_mask_i[i*(width_p/banks)+:width_p/banks]  )          \
            );                                                                   \
        end                                                                      \
    end

module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter harden_p = 1
                           )
   (input   clk_i
    , input reset_i
    , input v_i
    , input w_i
    , input [addr_width_lp-1:0] addr_i
    , input [width_p-1:0] data_i
    , input [width_p-1:0] w_mask_i
    , output [width_p-1:0]  data_o
    );

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_mask_write_bit_macro (736, 64) else
  `bsg_mem_1rw_sync_mask_write_bit_macro_banks(64,124,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro_banks(64,62,8) else

  // no hardened version found
    begin: notmacro

   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ) synth
       (.*);

    end // block: notmacro


   // synopsys translate_off

   always_ff @(posedge clk_lo)
     if (v_i === 1)
       assert ((reset_i === 'X) || (reset_i === 1'b1) || (addr_i < els_p))
         else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_lo=%b)\n", addr_i, els_p, reset_i, v_i, clk_lo);

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end

  // synopsys translate_on

   
endmodule

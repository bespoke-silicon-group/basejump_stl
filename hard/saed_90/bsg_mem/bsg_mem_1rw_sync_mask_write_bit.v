// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.

`define bsg_mem_1rw_sync_mask_write_bit_macro(bits,words)  \
  if (els_p == words && width_p == bits)    \
    begin: macro                            \
       saed90_``bits``x``words``_1P_bit mem \
         (.CE1  (clk_lo)                     \
         ,.WEB1 (~w_i)                      \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (~v_i)                      \
         ,.A1   (addr_i)                    \
         ,.I1   (data_i)                    \
         ,.O1   (data_o)                    \
         ,.WBM1 (w_mask_i)              \
         );                                 \
    end

module bsg_mem_1rw_sync_mask_write_bit #(parameter width_p=-1
			               , parameter els_p=-1
			               , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                     , parameter enable_clock_gating_p=1'b0
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

   wire clk_lo;

   bsg_clkgate_optional icg
     (.clk_i( clk_i )
     ,.en_i( v_i )
     ,.bypass_i( ~enable_clock_gating_p )
     ,.gated_clock_o( clk_lo )
     );


  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_mask_write_bit_macro (736, 64) else
  `bsg_mem_1rw_sync_mask_write_bit_macro ( 96, 64) else


  // Hack fo 7 bit ram to use 8 bit ram
  if (els_p == 64 && width_p == 7)
    begin: macro
       logic [7:0] data_lo;
       saed90_8x64_1P_bit mem
         (.CE1  (clk_lo)
         ,.WEB1 (~w_i)
         ,.OEB1 (1'b0)
         ,.CSB1 (~v_i)
         ,.A1   (addr_i)
         ,.I1   ({1'b0, data_i})
         ,.O1   (data_lo)
         ,.WBM1 ({1'b0, w_mask_i})
         );
      assign data_o = data_lo[6:0];
    end
  else
  
  // no hardened version found
    begin: notmacro

   bsg_mem_1rw_sync_mask_write_bit_synth
     #(.width_p(width_p)
       ,.els_p(els_p)
       ) synth
       (.clk_i (clk_lo)
       ,.reset_i
       ,.data_i
       ,.addr_i
       ,.v_i
       ,.w_mask_i
       ,.w_i
       ,.data_o
       );

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

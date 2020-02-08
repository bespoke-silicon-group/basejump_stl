// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//

`define bsg_mem_1rw_sync_mask_write_byte_macro(bits,words)  \
  if (els_p == words && data_width_p == bits)    \
    begin: macro                            \
       saed90_``bits``x``words``_1P_BM mem  \
         (.CE1  (clk_lo)                     \
         ,.WEB1 (~w_i)                      \
         ,.OEB1 (1'b0)                      \
         ,.CSB1 (~v_i)                      \
         ,.A1   (addr_i)                    \
         ,.I1   (data_i)                    \
         ,.O1   (data_o)                    \
         ,.WBM1 (write_mask_i)              \
         );                                 \
    end

module bsg_mem_1rw_sync_mask_write_byte #(parameter els_p = -1
                                         ,parameter data_width_p = -1
                                         ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         ,parameter write_mask_width_lp = data_width_p>>3
                                         ,parameter enable_clock_gating_p=1'b0
                                         )
  (input                           clk_i
  ,input                           reset_i
  ,input                           v_i
  ,input                           w_i
  ,input [addr_width_lp-1:0]       addr_i
  ,input [data_width_p-1:0]        data_i
  ,input [write_mask_width_lp-1:0] write_mask_i
  ,output [data_width_p-1:0]       data_o
  );

   wire clk_lo;
   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( v_i )
         ,.bypass_i( ~enable_clock_gating_p )
         ,.gated_clock_o( clk_lo )
         );
      end
   else
     begin
       assign clk_lo = clk_i;
     end
   

  // TODO: ADD ANY NEW RAM CONFIGURATIONS HERE
  `bsg_mem_1rw_sync_mask_write_byte_macro (64, 512) else
  
  // no hardened version found
    begin: notmacro

      // Instantiate a synthesizale 1rw sync mask write byte
      bsg_mem_1rw_sync_mask_write_byte_synth #(.els_p(els_p), .data_width_p(data_width_p)) synth 
       (.clk_i(clk_lo)
       ,.reset_i
       ,.v_i
       ,.w_i
       ,.addr_i
       ,.data_i
       ,.write_mask_i
       ,.data_o
       );


    end // block: notmacro

  // synopsys translate_off
  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

  initial
    begin
      $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
   
endmodule

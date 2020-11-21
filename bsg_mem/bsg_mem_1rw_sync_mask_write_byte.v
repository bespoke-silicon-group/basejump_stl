`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                          ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)

                                          ,parameter data_width_p = -1
                                          ,parameter latch_last_read_p=0
                                          ,parameter write_mask_width_lp = data_width_p>>3
                                          ,parameter enable_clock_gating_p=0
                                         )
  ( input clk_i
   ,input reset_i

   ,input v_i
   ,input w_i

   ,input [addr_width_lp-1:0]       addr_i
   ,input [`BSG_SAFE_MINUS(data_width_p, 1):0]        data_i
    // for each bit set in the mask, a byte is written
   ,input [`BSG_SAFE_MINUS(write_mask_width_lp, 1):0] write_mask_i

   ,output logic [`BSG_SAFE_MINUS(data_width_p, 1):0] data_o
  );

   wire clk_lo;

   if (enable_clock_gating_p)
     begin
       bsg_clkgate_optional icg
         (.clk_i( clk_i )
         ,.en_i( v_i )
         ,.bypass_i( 1'b0 )
         ,.gated_clock_o( clk_lo )
         );
     end
   else
     begin
       assign clk_lo = clk_i;
     end

   bsg_mem_1rw_sync_mask_write_byte_synth
     #(.els_p(els_p), .data_width_p(data_width_p), .latch_last_read_p(latch_last_read_p))
   synth
   (.clk_i(clk_lo)
   ,.reset_i
   ,.v_i
   ,.w_i
   ,.addr_i
   ,.data_i
   ,.write_mask_i
   ,.data_o
   );

  // synopsys translate_off

  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

   initial
     begin
        $display("## %L: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
     end

  // synopsys translate_on

   
endmodule

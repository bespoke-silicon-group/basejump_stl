module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                          ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)

                                          ,parameter data_width_p = -1
                                          ,parameter write_mask_width_lp = data_width_p>>3
                                          ,parameter enable_clock_gating_p=0
                                         )
  ( input clk_i
   ,input reset_i

   ,input v_i
   ,input w_i

   ,input [addr_width_lp-1:0]       addr_i
   ,input [data_width_p-1:0]        data_i
    // for each bit set in the mask, a byte is written
   ,input [write_mask_width_lp-1:0] write_mask_i

   ,output [data_width_p-1:0] data_o
  );

   wire clk_lo;

   bsg_clkgate_optional icg
     (.clk_i( clk_i )
     ,.en_i( w_v_i | r_v_i )
     ,.bypass_i( enable_clock_gating_p )
     ,.gated_clock_o( clk_lo )
     );

   bsg_mem_1rw_sync_mask_write_byte_synth
     #(.els_p(els_p), .data_width_p(data_width_p))
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

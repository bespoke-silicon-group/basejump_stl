module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                          ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)

                                          ,parameter data_width_p = -1
                                          ,parameter write_mask_width_lp = data_width_p>>3
                                          ,parameter debug_p =0
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

   bsg_mem_1rw_sync_mask_write_byte_synth
     #(.els_p(els_p), .data_width_p(data_width_p))
   synth (.*);

  // synopsys translate_off

  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");
  
  if( debug_p ) begin
   initial
     begin
        $display("## %L: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
     end
  end
  // synopsys translate_on

   
endmodule

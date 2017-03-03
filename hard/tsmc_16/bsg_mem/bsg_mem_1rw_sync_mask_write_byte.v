// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//
module bsg_mem_1rw_sync_mask_write_byte #(parameter els_p = -1
                                         ,parameter data_width_p = -1
                                         ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         ,parameter write_mask_width_lp = data_width_p>>3
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

  if ((els_p == 1024) & (data_width_p == 32))
    begin : macro
      wire [31:0] wen = ~{{8{write_mask_i[3]}}
                         ,{8{write_mask_i[2]}}
                         ,{8{write_mask_i[1]}}
                         ,{8{write_mask_i[0]}}};
      tsmc16_1rw_lg10_w32_byte mem
        (.CLK   (clk_i )
        ,.Q     (data_o) // out
        ,.CEN   (~v_i  ) // lo true
        ,.WEN   (wen   )
        ,.GWEN  (~w_i  ) // lo true
        ,.A     (addr_i) // in
        ,.D     (data_i) // in
        ,.STOV  (1'd0  ) // Self-timing Override - disabled
        ,.EMA   (3'd3  ) // Extra Margin Adjustment - default value
        ,.EMAW  (2'd1  ) // Extra Margin Adjustment Write - default value
        ,.EMAS  (1'd0  ) // Extra Margin Adjustment Sense Amp. - default value
        ,.RET1N (1'b1  ) // Retention Mode (active low) - disabled
        );
    end // block: macro
  
  // no hardened version found
  else
    begin: notmacro

      // Instantiate a synthesizale 1rw sync mask write byte
      bsg_mem_1rw_sync_mask_write_byte_synth #(.els_p(els_p), .data_width_p(data_width_p)) synth (.*);

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

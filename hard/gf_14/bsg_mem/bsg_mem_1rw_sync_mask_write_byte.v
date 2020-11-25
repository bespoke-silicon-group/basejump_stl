
`include "bsg_mem_1rw_sync_mask_write_byte_macros.vh"

module bsg_mem_1rw_sync_mask_write_byte #( parameter els_p = -1
                                         , parameter data_width_p = -1
                                         , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                         , parameter write_mask_width_lp = data_width_p>>3
                                         , parameter harden_p = 1
                                         , parameter latch_last_read_p = 1
                                         )

  ( input                           clk_i
  , input                           reset_i
  , input                           v_i
  , input                           w_i
  , input [addr_width_lp-1:0]       addr_i
  , input [data_width_p-1:0]        data_i
  , input [write_mask_width_lp-1:0] write_mask_i
  , output logic [data_width_p-1:0] data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_byte_macro(512,64,2) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024,32,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(2048,64,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(4096,64,4) else
  `bsg_mem_1rw_sync_mask_write_byte_macro(1024,32,4) else
  `bsg_mem_1rw_sync_mask_write_byte_banked_macro(1024,256,8,1) else
  // no hardened version found
    begin : notmacro
      bsg_mem_1rw_sync_mask_write_byte_synth #(.data_width_p(data_width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p))
        synth
          (.*);
    end // block: notmacro


  // synopsys translate_off
  always_comb
    begin
      assert (data_width_p % 8 == 0)
        else $error("data width should be a multiple of 8 for byte masking");
    end

  initial
    begin
      $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
   
endmodule


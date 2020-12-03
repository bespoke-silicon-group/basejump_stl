
`include "bsg_mem_1rw_sync_mask_write_bit_macros.vh"

module bsg_mem_1rw_sync_mask_write_bit #( parameter width_p = -1
                                        , parameter els_p = -1
                                        , parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p = 1
                                        , parameter latch_last_read_p = 1
                                        )
  ( input                       clk_i
  , input                       reset_i
  , input [width_p-1:0]         data_i
  , input [addr_width_lp-1:0]   addr_i
  , input                       v_i
  , input [width_p-1:0]         w_mask_i
  , input                       w_i
  , output logic [width_p-1:0]  data_o
  );

  wire unused = reset_i;

  // TODO: Define more hardened macro configs here
  `bsg_mem_1rw_sync_mask_write_bit_macro( 64,15,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro( 64, 7,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,48,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,30,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(256,34,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,4,2) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(512,32,4) else
  `bsg_mem_1rw_sync_mask_write_bit_macro(128,152,2) else

  `bsg_mem_1rw_sync_mask_write_bit_macro(64,58,2) else
  `bsg_mem_1rw_sync_mask_write_bit_banked_macro(64,116,2,1) else
  
    begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth #(.width_p(width_p), .els_p(els_p), .latch_last_read_p(latch_last_read_p))
        synth
          (.*);
    end // block: notmacro

  // synopsys translate_off
  always_ff @(posedge clk_i)
    begin
      if (v_i)
        assert (addr_i < els_p)
          else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);
    end

  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
    end
// synopsys translate_on

endmodule


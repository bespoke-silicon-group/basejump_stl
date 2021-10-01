
  `include "bsg_mem_1rw_sync_mask_write_bit_macros.vh"

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit #(parameter `BSG_INV_PARAM(width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter latch_last_read_p=0
                          , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                          , parameter enable_clock_gating_p=0
                          , parameter harden_p=1
                          )
   (input   clk_i
    , input reset_i
    , input [`BSG_SAFE_MINUS(width_p,1):0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [`BSG_SAFE_MINUS(width_p,1):0] w_mask_i
    , input w_i
    , output logic [`BSG_SAFE_MINUS(width_p,1):0]  data_o
    );

    initial begin
      if (latch_last_read_p && !0)
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !0)
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end

    if (0) begin end else
    // Hardened macro selections
    	`bsg_mem_1rw_sync_mask_write_bit_banked_macro(1024,128,2,2) else
	`bsg_mem_1rw_sync_mask_write_bit_1rf_macro(512,64,2) else
	`bsg_mem_1rw_sync_mask_write_bit_1sram_macro(128,32,2) else

      begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

endmodule
  
  

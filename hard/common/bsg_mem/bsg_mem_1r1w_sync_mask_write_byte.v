
  `include "bsg_mem_1r1w_sync_mask_write_byte_macros.vh"
  
  module bsg_mem_1r1w_sync_mask_write_byte
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter write_mask_width_lp=width_p>>3
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i
      
      , input w_v_i
      , input [`BSG_SAFE_MINUS(write_mask_width_lp,1):0] w_mask_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i
  
      , input r_v_i
      , input [addr_width_lp-1:0] r_addr_i
      
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r_data_o
    );
  
    initial begin
      if (read_write_same_addr_p && !0)
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !0)
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !0)
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
  
    if (0) begin end else
    // Hardened macro selections
    	`bsg_mem_1r1w_sync_mask_write_byte_2rf_macro(512,64,2) else
	`bsg_mem_1r1w_sync_mask_write_byte_2sram_macro(1024,32,2) else

      begin: notmacro
      bsg_mem_1r1w_sync_mask_write_byte_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*); 
    end
  
    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

  endmodule
  
  `BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_byte)
  

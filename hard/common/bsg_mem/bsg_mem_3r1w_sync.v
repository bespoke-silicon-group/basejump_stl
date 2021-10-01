
  `include "bsg_mem_3r1w_sync_macros.vh"
  
  module bsg_mem_3r1w_sync
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i
      
      , input w_v_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i
  
      , input r0_v_i
      , input [addr_width_lp-1:0] r0_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r0_data_o

      , input r1_v_i
      , input [addr_width_lp-1:0] r1_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r1_data_o

      , input r2_v_i
      , input [addr_width_lp-1:0] r2_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r2_data_o
    );
  
    initial begin
      if (read_write_same_addr_p && !0)
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported")
      if (enable_clock_gating_p && !0)
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported")
    end
  
    if (0) begin end else
    // Hardened macro selections
    	`bsg_mem_3r1w_sync_2sram_macro(32,66,2)

      begin: notmacro
      bsg_mem_3r1w_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*); 
    end

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p)
        end
    //synopsys translate_on

  endmodule
  
  `BSG_ABSTRACT_MODULE(bsg_mem_3r1w_sync)
  

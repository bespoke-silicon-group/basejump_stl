/*
 *  bsg_mem_1rw_sync_segmented.sv
 *
 *  This module has the same interface/functionality as bsg_mem_1rw_sync
    when num_segments_p = 1. When num_segments_p > 1, it has the similar
    functionality as bsg_mem_1rw_sync_mask_write_byte

 *  This module behaves like an N bsg_mem_1rw_sync memories in parallel.
    This module is useful when we have a big SRAM, but we want a 
    functionality of partial SRAM by creating N logical SRAMs. Since v_i 
    is independent per logical SRAM,we can either perform read or write 
    at a time partially from the big SRAM.

 *
 *  - width_p : width of the total memory
 *  - els_p   : depth of the total memory
 *
 *  - num_segments_p : Number of logical banks for the memory's width. width_p has
 *                    to be a multiple of this number.
 */

  // For segmented SRAMs, all logical SRAMs must either read or write from the same address at once. 
  // There could be an implementation to support independent segment r/w by using a 1r1w backing SRAM. 
  // This may make sense in an FPGA environment, but we leave this to future work.


`include "bsg_defines.sv"

module bsg_mem_1rw_sync_segmented
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter `BSG_INV_PARAM(latch_last_read_p)
    , parameter `BSG_INV_PARAM(num_segments_p)

      // Don't support depth segments due to conflicts
    , localparam segment_width_lp = width_p/num_segments_p
    , localparam mask_width_lp    = segment_width_lp >>3
    , localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )
  (   input clk_i
  	, input reset_i
   	, input [num_segments_p-1:0] v_i
  	, input w_i
    , input [num_segments_p-1:0][mask_width_lp-1:0] w_mask_i
  	, input [num_segments_p-1:0][segment_width_lp-1:0] data_i
  	, input [lg_els_lp-1:0] addr_i
  	, output logic [num_segments_p-1:0][segment_width_lp-1:0] data_o
  );

    logic [num_segments_p-1:0][segment_width_lp-1:0] data_lo;

    if (num_segments_p == 1) begin: no_mask_sram

      bsg_mem_1rw_sync #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p && num_segments_p == 1)
      ) 
      bank 
      ( .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.v_i(|v_i)
        ,.w_i(w_i)
        ,.addr_i(addr_i)
        ,.data_i(data_i)
        ,.data_o(data_lo)
      );

    end //no_mask_sram

    else begin: byte_mask_sram

      logic [num_segments_p-1:0][mask_width_lp-1:0] w_mask_lo;

      for (genvar i = 0; i < num_segments_p; i++) begin
        for (genvar j = 0; j < mask_width_lp; j++) 
          assign w_mask_lo[i][j] = w_mask_i[i][j] & v_i[i];
      end // for (genvar i = 0; i < num_segments_p; i++)
  
      bsg_mem_1rw_sync_mask_write_byte #(
        .data_width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(0)
      ) 
      bank 
      ( .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.v_i(|v_i)
        ,.w_i(w_i)
        ,.addr_i(addr_i)
        ,.data_i(data_i)
        ,.write_mask_i(w_mask_lo)
        ,.data_o(data_lo)
      );
    
    end //byte_mask_sram

    if (latch_last_read_p && num_segments_p > 1) begin: llr
  
      wire [num_segments_p-1:0] read_en;
      wire [num_segments_p-1:0] read_en_r;

      for (genvar i = 0; i < num_segments_p; i++) begin: bk1

        assign read_en[i] = v_i[i] & ~w_i; 

        bsg_dff #(
          .width_p(1)
        ) read_en_dff (
          .clk_i(clk_i)
          ,.data_i(read_en[i])
          ,.data_o(read_en_r[i])
        );
        
        bsg_dff_en_bypass #(
          .width_p(segment_width_lp)
        ) dff_bypass (
          .clk_i(clk_i)
          ,.en_i(read_en_r[i])
          ,.data_i(data_lo[i])
          ,.data_o(data_o[i])
        );

      end // for (genvar i = 0; i < num_segments_p; i++)

    end // (latch_last_read_p && num_segments_p > 1)
        
    else begin: no_llr
      assign data_o = data_lo;
    end

    if (!(`BSG_IS_POW2(width_p) && (`BSG_IS_POW2(els_p) || (els_p == 0))))
      $error("width_p and els_p should be power of 2");      

    if (!(num_segments_p > 1) && !(segment_width_lp%8 == 0))
      $error("For byte-mask SRAM, segment_width_lp should be a multiple of 8");

endmodule

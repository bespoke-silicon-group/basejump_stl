/*
 *  bsg_mem_1rw_sync_subbanked.v
 *
 *  This module has the same interface/functionality as bsg_mem_1rw_sync
    when num_subbank_p = 1. When num_subbank_p > 1, it has the similar
    functionality as bsg_mem_1rw_sync_mask_write_byte
 *
 *  - width_p : width of the total memory
 *  - els_p   : depth of the total memory
 *
 *  - num_subbank_p : Number of banks for the memory's width. width_p has
 *                    to be a multiple of this number.
 *
 */

  // For subbanked SRAMs, all subbanks must either read or write from the same address at once. 
  // There could be an implementation to support independent subbank r/w by using a 1r1w backing SRAM. 
  // This may make sense in an FPGA environment, but we leave this to future work.

`include "bsg_defines.v"

module bsg_mem_1rw_sync_subbanked
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter `BSG_INV_PARAM(latch_last_read_p)
    , parameter `BSG_INV_PARAM(num_subbank_p)

      // Don't support depth subbanks due to conflicts
    , localparam subbank_width_lp = width_p/num_subbank_p
    , localparam mask_width_lp     = subbank_width_lp >>3
    , localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )
  (   input clk_i
  	, input reset_i
   	, input [num_subbank_p-1:0] v_i
  	, input w_i
    , input [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_i
  	, input [num_subbank_p-1:0][subbank_width_lp-1:0] data_i
  	, input [lg_els_lp-1:0] addr_i
  	, output logic [num_subbank_p-1:0][subbank_width_lp-1:0] data_o
  );

    logic [num_subbank_p-1:0][subbank_width_lp-1:0] data_lo;

    if (num_subbank_p == 1) begin: no_mask_sram

      bsg_mem_1rw_sync #(
        .width_p(width_p)
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
        ,.data_o(data_lo)
      );

    end //no_mask_sram

    else begin: byte_mask_sram

      logic [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_lo;

      for (genvar i = 0; i < num_subbank_p; i++) begin
        for (genvar j = 0; j < mask_width_lp; j++) 
          assign w_mask_lo[i][j] = w_mask_i[i][j] & v_i[i];
      end // for (genvar i = 0; i < num_subbank_p; i++)
  
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

    if (latch_last_read_p) begin: llr

      wire [num_subbank_p-1:0] read_en;
      wire [num_subbank_p-1:0] read_en_r;

      for (genvar i = 0; i < num_subbank_p; i++) begin: bk1

        assign read_en[i] = v_i[i] & ~w_i; 

        bsg_dff #(
          .width_p(1)
        ) read_en_dff (
          .clk_i(clk_i)
          ,.data_i(read_en[i])
          ,.data_o(read_en_r[i])
        );
        
        bsg_dff_en_bypass #(
          .width_p(subbank_width_lp)
        ) dff_bypass (
          .clk_i(clk_i)
          ,.en_i(read_en_r[i])
          ,.data_i(data_lo[i])
          ,.data_o(data_o[i])
        );

      end // for (genvar i = 0; i < num_subbank_p; i++)

    end // if (latch_last_read_p)
      
    else begin: no_llr
      assign data_o = data_lo;
    end

    if (!(`BSG_IS_POW2(width_p) && `BSG_IS_POW2(els_p)))
      $error("width_p and els_p should be power of 2"); 

    if (num_subbank_p == 0)
      $error("Number of subbanks should not be equal to 0");     

    if (!(num_subbank_p > 1) && !(subbank_width_lp%8 == 0))
      $error("For byte-mask SRAM, subbank_width_lp should be a multiple of 8");

endmodule

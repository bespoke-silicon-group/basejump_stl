/*
 *  bsg_mem_1rw_sync_mask_write_bit_subbanked.v
 *
 *  This module has the same interface/functionality as
    bsg_mem_1rw_sync_mask_write_bit.
 *
 *  - width_p : width of the total memory
 *  - els_p   : depth of the total memory
 *
 *  - num_subbank_p : Number of banks for the memory's width. width_p has
 *                    to be a multiple of this number.
 *
 */

`include "bsg_defines.v"

module bsg_mem_1rw_sync_mask_write_bit_subbanked
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter latch_last_read_p = 0
    , parameter num_subbank_p = 4
    , parameter mask_granularity_p = 1

      // Don't support depth subbanks due to conflicts
    , localparam subbank_width_lp = width_p/num_subbank_p
    , localparam els_lp = `BSG_SAFE_CLOG2(els_p)
    , localparam mask_width_lp = subbank_width_lp/mask_granularity_p
  )
  (   input clk_i
  	, input reset_i
   	, input [num_subbank_p-1:0] v_i
  	, input [num_subbank_p-1:0] w_i
  	, input [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_i
  	, input [num_subbank_p-1:0][subbank_width_lp-1:0] data_i
  	, input [els_lp-1:0] addr_i
  	, output logic [num_subbank_p-1:0][subbank_width_lp-1:0] data_o
  );

    wire [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_lo;

    for (genvar i = 0; i < num_subbank_p; i++) begin
      for (genvar j = 0; j < mask_width_lp; j++) 
        assign w_mask_lo[i][j] = w_mask_i[i][j] & v_i[i] & w_i[i];
    end

    bsg_mem_1rw_sync_mask_write_bit #(
      .width_p(width_p)
      ,.els_p(els_p)
      ,.latch_last_read_p(latch_last_read_p)
    ) 
    subbanks 
    ( .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(|v_i)
      ,.w_i(|w_i)
      ,.addr_i(addr_i)
      ,.data_i(data_i)
      ,.w_mask_i(w_mask_lo)
      ,.data_o(data_o)
    );

    always@(*) begin
      assert (`BSG_IS_POW2(width_p) && `BSG_IS_POW2(els_p));
      assert (width_p%num_subbank_p == 0);
    end

endmodule

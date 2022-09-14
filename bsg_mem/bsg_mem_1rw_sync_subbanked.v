/*
 *  bsg_mem_1rw_sync_subbanked.v
 *
 *  This module has the same interface/functionality as
    N bsg_mem_1rw_sync.
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
    , parameter latch_last_read_p=0
    , parameter num_subbank_p=1

      // width = no mask, mask ignored
      // We set this as a separate parameter so that we can substitute out the type of ram appropriately
    , parameter mask_granularity_p=1
    , parameter mask_width_lp = width_p/mask_granularity_p

    , localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)

      // Don't support depth subbanks due to conflicts
    , localparam subbank_width_lp=width_p/num_subbank_p
    )
    (   input clk_i
    	, input reset_i

    	, input v_i
    	, input w_i
    	, input [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_i
    	, input [num_subbank_p-1:0][subbank_width_lp-1:0] data_i
    	, input [lg_els_lp-1:0] addr_i

    	, output [num_subbank_p-1:0][subbank_width_lp-1:0] data_o
    );

	if (num_subbank_p == 1) begin 

    bsg_mem_1rw_sync_mask_write_bit #(
      .width_p(subbank_width_lp)
      ,.els_p(els_p)
      ,.latch_last_read_p(latch_last_read_p)
    ) sub_bank (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.v_i(v_i)
      ,.w_i(w_i)
      ,.addr_i(addr_i)
      ,.data_i(data_i[0+:subbank_width_lp-1])
      ,.w_mask_i(w_mask_i[0+:subbank_width_lp-1])
      ,.data_o(data_o[0+:subbank_width_lp-1])
    );
		
	end // if (num_subbank_p == 1)

	else begin // !(num_subbank_p == 1)

    logic [subbank_width_lp-1:0] bank_data_lo [num_subbank_p-1:0];
		wire [mask_width_lp-1] w_mask_expanded;

    for (genvar j = 0; j < num_subbank_p; j++) begin 

			bsg_expand_bitmask #(
				.in_width_p(mask_width_lp)
    		,.expand_p(1)
    	)
    	w_mask_expanded
    	(
				.i(w_mask_i[j][j*subbank_width_lp+:subbank_width_lp-1])
    		,.o(w_mask_expanded)
      );

      bsg_mem_1rw_sync_mask_write_bit #(
        .width_p(subbank_width_lp)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) 
			bank 
      ( .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.v_i(v_i)
        ,.w_i(w_i)
        ,.addr_i(addr_i)
        ,.data_i(data_i[j][j*subbank_width_lp+:subbank_width_lp-1])
        ,.w_mask_i(w_mask_expanded)
        ,.data_o(bank_data_lo[j])
      );

		end // for (genvar j = 0; j < num_depth_bank_p; j++)

		assign data_o [j][j*subbank_width_lp+:subbank_width_lp-1] = bank_data_lo[j];

	end // !(num_subbank_p == 1)

endmodule
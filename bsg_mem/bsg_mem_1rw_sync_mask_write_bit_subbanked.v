/*
 *  bsg_mem_1rw_sync_mask_write_bit_subbanked.v
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

    , localparam els_lp = `BSG_SAFE_CLOG2(els_p)

      // Don't support depth subbanks due to conflicts
    , localparam subbank_width_lp=width_p/num_subbank_p
    )
    (   input clk_i
    	, input reset_i

    	, input v_i
    	, input w_i
    	, input [num_subbank_p-1:0][subbank_width_lp-1:0] w_mask_i
    	, input [num_subbank_p-1:0][subbank_width_lp-1:0] data_i
    	, input [els_lp-1:0] addr_i

    	, output logic [num_subbank_p-1:0][subbank_width_lp-1:0] data_o
    );

    logic [width_p-1:0] bank_data_lo [els_lp-1:0];
		wire [width_p-1:0] w_mask_expand;
    wire read_en;

    //for (genvar j = 0; j < num_subbank_p; j++) begin 

			bsg_expand_bitmask #(
				.in_width_p(1)
    		,.expand_p(width_p)
    	)
    	w_mask_expanded
    	(
				.i(w_mask_i)
    		,.o(w_mask_expand)
      );

      bsg_mem_1rw_sync_mask_write_bit #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) 
			bank 
      ( .clk_i(clk_i)
        ,.reset_i(reset_i)
        ,.v_i(v_i)
        ,.w_i(w_i)
        ,.addr_i(addr_i)
        ,.data_i(data_i)
        ,.w_mask_i(w_mask_expand)
        ,.data_o(bank_data_lo[addr_i])
      );

		  //assign data_o  = bank_data_lo[addr_i];



    //end

    assign read_en = v_i & ~w_i;

    always@(posedge clk_i) begin
      if (read_en)
       data_o = bank_data_lo[addr_i];
    end

endmodule

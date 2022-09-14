/*
 *  bsg_mem_1rw_sync_subbanked.v
 *
 *  This module has the same interface/functionality as
    bsg_mem_1rw_sync.
 *
 *  - width_p : width of the total memory
 *  - els_p   : depth of the total memory
 *
 *  - num_subbank_p : Number of banks for the memory's width. width_p has
 *                    to be a multiple of this number.
 *
 */


`include "bsg_defines.v"

module bsg_mem_1rw_sync_subbanked
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
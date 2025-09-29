/**
 *    bsg_id_pool.sv
 *
 *    This module maintains of a pool of IDs, and supports allocation and deallocation of these IDs.
 *    Often used to implement a "coatcheck", where you need to retain metadata for a set of transactions,
 *    which may come back out-of-order.
 */

`include "bsg_defines.sv"

module bsg_id_pool
  #(parameter `BSG_INV_PARAM(els_p)
    , parameter id_width_lp=`BSG_SAFE_CLOG2(els_p)
  ) 
  (
    input clk_i,
    input reset_i

    // next available id
    , output logic [id_width_lp-1:0] alloc_id_o
    , output logic alloc_v_o
    , input alloc_yumi_i

    // id to return
    , input dealloc_v_i
    , input [id_width_lp-1:0] dealloc_id_i    

    , output empty_o
  );

  bsg_id_pool_with_reserve #(.els_p(els_p)) idpr
  (.clk_i(clk_i)
   ,.reset_i(reset_i)
   ,.alloc_id_o(alloc_id_o)
   ,.alloc_v_o(alloc_v_o)
   ,.alloc_yumi_i(alloc_yumi_i)
   ,.dealloc_v_i(dealloc_v_i)
   ,.dealloc_id_i(dealloc_id_i)
   ,.reserve_i('0)
   ,.empty_o(empty_o)
  );
                             

endmodule

`BSG_ABSTRACT_MODULE(bsg_id_pool)

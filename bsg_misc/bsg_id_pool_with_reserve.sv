/**
 *    bsg_id_pool_with_reserve.sv
 *
 *    This module maintains of a pool of IDs, and supports allocation and deallocation of these IDs.
 *    Often used to implement a "coatcheck", where you need to retain metadata for a set of transactions,
 *    which may come back out-of-order.
 *
 *   The reserve feature allows certain IDs to be removed from the pool, for example to work around defects
 *   in hardware.
 * 
 *   Note that deallocated ID's are bypassed into allocation.
 *   It is forbid to immediately in the same cycle deallocate an allocated ID.
 */



`include "bsg_defines.sv"

module bsg_id_pool_with_reserve
  #(parameter `BSG_INV_PARAM(els_p)
    , parameter id_width_lp=`BSG_SAFE_CLOG2(els_p)
  ) 
  (
    input clk_i,
    input reset_i

    // IDs that you do not want to be allocated (one hot)
    // this can be changed on the fly and does not prevent
    // previously allocated from be returned
    , input logic [els_p-1:0] reserve_i

    // next available id
    , output logic [id_width_lp-1:0] alloc_id_o
    , output logic alloc_v_o
    , input alloc_yumi_i

    // id to return, should come early in cycle
    , input dealloc_v_i
    , input [id_width_lp-1:0] dealloc_id_i    

   // no id's are allocated
    , output empty_o
  );
   
   logic [els_p-1:0] allocated_r;
   
   assign empty_o = ~(|allocated_r);
   
  // next id to dealloc
  logic [els_p-1:0] dealloc_decode;
  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) d1 (
    .i(dealloc_id_i)
    ,.v_i(dealloc_v_i)
    ,.o(dealloc_decode)
  );

  // keeps track of which id has been allocated.
  logic [els_p-1:0] allocated_or_reserved_li;

  assign allocated_or_reserved_li = (allocated_r & ~dealloc_decode) | reserve_i;
  
  // find the next available id.
  logic [id_width_lp-1:0] alloc_id_lo;
  logic alloc_v_lo;
  logic [els_p-1:0] one_hot_out;

   // We use this v_o instead of the v_o of bsg_encode_one_hot
   //   because it has better critical path
  bsg_priority_encode_one_hot_out #(
    .width_p(els_p)
    ,.lo_to_hi_p(1)
  ) pe0 (
    .i(~allocated_or_reserved_li)
    ,.o(one_hot_out)
    ,.v_o(alloc_v_lo)
  );

  bsg_encode_one_hot #(
    .width_p(els_p)
    ,.lo_to_hi_p(1)
  ) enc0 (
    .i(one_hot_out)
    ,.addr_o(alloc_id_lo)
    ,.v_o()
  );

  assign alloc_id_o = alloc_id_lo;
  assign alloc_v_o = alloc_v_lo;

  // next id to alloc
  wire [els_p-1:0] alloc_decode = one_hot_out & {els_p{alloc_yumi_i}};

  // Immediately allocating the deallocated id is allowed.
  bsg_dff_reset_set_clear #(
    .width_p(els_p)
  ) dff_alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(alloc_decode)
    ,.clear_i(dealloc_decode)
    ,.data_o(allocated_r)
  );


`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @ (posedge clk_i) begin
    if (~reset_i) begin
      if (dealloc_v_i) begin
        assert(allocated_r[dealloc_id_i]) else $error("Cannot deallocate an id that hasn't been allocated.");
        assert(!reserve_i [dealloc_id_i]) else $warning("Warning: deallocating an id (%b) that is reserved.",dealloc_id_i);
        assert(dealloc_id_i < els_p) else $error("Cannot deallocate an id that is outside the range.");
      end

      if (alloc_yumi_i)
        assert(alloc_v_o) else $error("Handshaking error. alloc_yumi_i raised without alloc_v_o.");

      if (alloc_yumi_i & dealloc_v_i & (alloc_id_o == dealloc_id_i))
        assert(allocated_r[dealloc_id_i]) else $error("Cannot immediately dellocate an allocated id.");
      
    end
  end
`endif


endmodule

`BSG_ABSTRACT_MODULE(bsg_id_pool_with_reserve)

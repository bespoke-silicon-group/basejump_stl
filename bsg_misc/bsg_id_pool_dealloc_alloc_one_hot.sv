/**
 *    bsg_id_pool_dealloc_alloc_one_hot
 *
 *    This module maintains of a pool of IDs, and supports allocation and deallocation of these IDs,
 *    and also live tracking of which ones are active.
 *
 *    Only one item can be allocated per cycle (for now), but any number can be deallocated per cycle.
 *
 *    order of precedence:
 *
 *    actives_id_r_o     is before any request to deallocate or allocate has been processed (early)
 *    alloc_id_one_hot_o is before any request to deallocate has been processed (middle)
 *    dealloc_ids_i      *can* be applied to an alloc'd ID (but not necessarily recommended) (late)
 *    yumi_i             (late)
 *
 *    deallocating ID in same cycle as allocating is not allowed
 *
 *    This module is helpful on all outputs.
 *
 *    The interface has a different priority of alloc versus dealloc versus
 *    bsg_id_pool; should either rename that one to bsg_id_pool_alloc_dealloc
 *    or consider refactoring that interface, depending on how that one seems to
 *    be used over time.
 */

`include "bsg_defines.sv"

module bsg_id_pool_dealloc_alloc_one_hot
  #(parameter `BSG_INV_PARAM(els_p))
  (
    input clk_i
    , input reset_i

   // bitvector of all active IDs, before any allocation or deallocation is done
    , output [els_p-1:0] active_ids_r_o
    
    // next available id
    , output logic [els_p-1:0] alloc_id_one_hot_o

    // whether any bit of the above is set
    , output logic alloc_id_v_o
    
    // whether the client accepts the proferred ID
    , input alloc_yumi_i

    // bitmask; can actually deallocate multiple in parallel
    // can deallocate something that was just allocated (although this may
    // impact critical path)
    , input [els_p-1:0] dealloc_ids_i    
  );
  
  // keeps track of which id has been allocated.
  logic [els_p-1:0] allocated_r;
  
  // find the next available id.
  bsg_priority_encode_one_hot_out #(
    .width_p(els_p)
    ,.lo_to_hi_p(1)
  ) pe0 (
    .i(~allocated_r)
    ,.o(alloc_id_one_hot_o)
    ,.v_o(alloc_id_v_o)
  );

  // update internal state with allocated ID, if it is accepted.
  wire [els_p-1:0] alloc_set = alloc_id_one_hot_o & {els_p{alloc_yumi_i}};

  // bsg_id_pool_one_hot will never allocate an item that is being deallocated in the same
  // cycle, to avoid critical paths.
  //
  // bsg_id_pool_one_hot *does* allow the outer logic to clear an item that was just allocated,
  // although this may impact the critical path.

  bsg_dff_reset_set_clear #(
    .width_p(els_p)
    ,.clear_over_set_p(1)
  ) dff_alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(alloc_set)
    ,.clear_i(dealloc_ids_i)
    ,.data_o(allocated_r)
  );

  assign active_ids_r_o = allocated_r;
  

`ifndef BSG_HIDE_FROM_SYNTHESIS
    
  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      assert ((dealloc_ids_i & ~(allocated_r | alloc_set)) == '0)
       else $error("Cannot deallocate an id that hasn't been allocated.");

      if (alloc_yumi_i)
        assert(alloc_id_v_o) else $error("Handshaking error. alloc_yumi_i raised without alloc_v_o.");
 
      //$display("bsg_id_pool_one_hot: allocated_r=%b dealloc_ids_i=%b alloc_id_v_o=%b", allocated_r, dealloc_ids_i, alloc_id_v_o);
    end
  end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_id_pool_dealloc_alloc_one_hot)

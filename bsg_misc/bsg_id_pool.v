/**
 *    bsg_id_pool.v
 *
 *    This module maintains of a pool of IDs, and supports allocation and deallocation of these IDs.
 *
 */



module bsg_id_pool
  #(parameter els_p="inv"
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
  );


  // keeps track of which id has been allocated.
  logic [els_p-1:0] allocated_r;

  // next id to dealloc
  logic [els_p-1:0] dealloc_decode;
  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) d1 (
    .i(dealloc_id_i)
    ,.v_i(dealloc_v_i)
    ,.o(dealloc_decode)
  );
  
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
    .i(~allocated_r | dealloc_decode)
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


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      allocated_r <= '0;
    end
    else begin

      for (integer i = 0; i < els_p; i++) begin
        // this allows immediately allocating the deallocated id.
        if (alloc_decode[i])
          allocated_r[i] <= 1'b1;
        else if (dealloc_decode[i])
          allocated_r[i] <= 1'b0;
      end

    end
  end


  // synopsys translate_off
  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin
      if (dealloc_v_i) begin
        assert(allocated_r[dealloc_id_i]) else $error("Cannot deallocate an id that hasn't been allocated.");
        assert(dealloc_id_i < els_p) else $error("Cannot deallocate an id that is outside the range.");
      end

      if (alloc_yumi_i)
        assert(alloc_v_o) else $error("Handshaking error. alloc_yumi_i raised without alloc_v_o.");

      if (alloc_yumi_i & dealloc_v_i & (alloc_id_o == dealloc_id_i))
        assert(allocated_r[dealloc_id_i]) else $error("Cannot immediately dellocate an allocated id.");
      
    end
  end
  // synopsys translate_on


endmodule

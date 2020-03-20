/**
 *    bsg_fifo_reorder.v
 *
 */


module bsg_fifo_reorder
  #(parameter width_p="inv"
    , parameter els_p="inv"
    , parameter lg_els_lp=`BSG_SAFE_CLOG2(els_p)
  )
  (
    input clk_i
    , input reset_i

    // FIFO allocates the next available addr
    , output fifo_alloc_v_o
    , output [lg_els_lp-1:0] fifo_alloc_id_o
    , input fifo_alloc_yumi_i
    
    // random access write
    // data can be written out of order
    , input write_v_i
    , input [lg_els_lp-1:0] write_id_i
    , input [width_p-1:0] write_data_i

    // dequeue written items in order
    , output fifo_deq_v_o
    , output [width_p-1:0] fifo_deq_data_o
    , input fifo_deq_yumi_i

    // this signals that the FIFO is empty
    // i.e. there is no reserved spot for returning data,
    // and all valid data in the FIFO has been consumed.
    , output logic empty_o
  );


  // fifo tracker
  // enque when id is allocated.
  // deque when data is dequeued.
  logic [lg_els_lp-1:0] wptr_r, rptr_r;
  logic full, empty;
  logic enq, deq;

  bsg_fifo_tracker #(
    .els_p(els_p)
  ) tracker0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.enq_i(enq)
    ,.deq_i(deq)
    ,.wptr_r_o(wptr_r)
    ,.rptr_r_o(rptr_r)
    ,.rptr_n_o()
    
    ,.full_o(full)
    ,.empty_o(empty)
  );

  assign fifo_alloc_v_o = ~full;
  assign enq = ~full & fifo_alloc_yumi_i;
  assign fifo_alloc_id_o = wptr_r;
    
  assign empty_o = empty;
 

  // valid bit for each entry
  // this valid bit is cleared, when the valid data is dequeued.
  // this valid bit is set, when the valid data is written.
  logic [els_p-1:0] valid_r;
  logic [els_p-1:0] set_valid;
  logic [els_p-1:0] clear_valid;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) demux0 (
    .i(write_id_i)
    ,.v_i(write_v_i)
    ,.o(set_valid)
  );

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) demux1 (
    .i(rptr_r)
    ,.v_i(deq)
    ,.o(clear_valid)
  );

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      valid_r <= '0;
    end
    else begin

      for (integer i = 0; i < els_p; i++) begin
        if (set_valid[i])
          valid_r[i] <= 1'b1;
        else if (clear_valid[i])
          valid_r[i] <= 1'b0;
      end

    end
  end


  // deque logic
  wire fifo_deq_v_lo = valid_r[rptr_r] & ~empty;
  assign fifo_deq_v_o = fifo_deq_v_lo;
  assign deq = fifo_deq_yumi_i;


  // data storage
  bsg_mem_1r1w #(
    .width_p(width_p)
    ,.els_p(els_p)
  ) mem0 (
    .w_clk_i(clk_i)
    ,.w_reset_i(reset_i)

    ,.w_v_i(write_v_i)
    ,.w_addr_i(write_id_i)
    ,.w_data_i(write_data_i)

    ,.r_v_i(fifo_deq_v_lo)
    ,.r_addr_i(rptr_r)
    ,.r_data_o(fifo_deq_data_o)
  );


  // synopsys translate_off

  always_ff @ (negedge clk_i) begin
    if (~reset_i) begin

      if (fifo_alloc_yumi_i)
        assert(fifo_alloc_v_o) else $error("Handshaking error. fifo_alloc_yumi_i raised without fifo_alloc_v_o.");

      if (fifo_deq_yumi_i) 
        assert(fifo_deq_v_o) else $error("Handshaking error. fifo_deq_yumi_i raised without fifo_deq_v_o.");

      if (write_v_i)
        assert(~valid_r[write_id_i]) else $error("Cannot write to an already valid data.");

    end    
  end

  // synopsys translate_on


endmodule

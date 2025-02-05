// mbt & ChatGPT o1 (AI-generated)

`include "bsg_defines.sv"

// bsg_fifo_reorder_sync

module bsg_fifo_reorder_sync
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )
  (
    input                         clk_i
    , input                       reset_i

    // Allocate next FIFO address
    , output                      fifo_alloc_v_o
    , output [lg_els_lp-1:0]      fifo_alloc_id_o
    , input                       fifo_alloc_yumi_i

    // Random access write
    , input                       write_v_i
    , input [lg_els_lp-1:0]       write_id_i
    , input [width_p-1:0]         write_data_i

    // Dequeue in order
    , output                      fifo_deq_v_o
    , output [width_p-1:0]        fifo_deq_data_o
    , output [lg_els_lp-1:0]      fifo_deq_id_o
    , input                       fifo_deq_yumi_i

    // Indicates we have consumed everything from the reorder fifo that was allocated
    , output logic                empty_o
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial begin
    // If you want a run-time check:
    if (!`BSG_IS_POW2(els_p)) begin
      $error("%m ERROR: els_p(%0d) is not a power of two", els_p);
    end
  end
`endif

  // ----------------------------------------------------------------
  // (1) FIFO TRACKER
  // ----------------------------------------------------------------
  logic [lg_els_lp-1:0] wptr_r, rptr_r, rptr_n, rptr_r_p1;
  logic full_lo;

  bsg_fifo_tracker #(
    .els_p(els_p)
  ) tracker0 (
    .clk_i   (clk_i),
    .reset_i (reset_i),

    .enq_i   (fifo_alloc_yumi_i),
    .deq_i   (fifo_deq_yumi_i),
    .wptr_r_o(wptr_r),
    .rptr_r_o(rptr_r),
    .rptr_n_o(rptr_n), // combinationally dependent on deq_i

    .full_o  (full_lo),
    .empty_o (empty_o)
  );

  assign fifo_alloc_v_o  = ~full_lo;
  assign fifo_alloc_id_o = wptr_r;


  // ----------------------------------------------------------------
  // (2) VALID BITS
  // ----------------------------------------------------------------
  logic [els_p-1:0] valid_r;
  logic [els_p-1:0] set_valid, clear_valid;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) set_demux (
    .i   (write_id_i),
    .v_i (write_v_i),
    .o   (set_valid)
  );

  bsg_dff_reset_set_clear #(
    .width_p(els_p)
  ) valid_bits (
    .clk_i   (clk_i),
    .reset_i (reset_i),
    .set_i   (set_valid),
    .clear_i (clear_valid),
    .data_o  (valid_r)
  );

// the next read slot, requires power of 2 els_p
assign rptr_r_p1 = rptr_r+1'b1;

logic loaded_r;

 // we read the memory if we have a deque, and the data in the next slot is valid
 // or, when it is not a deque, and the current slot is valid but we have not loaded it
 // we do not bypass
 wire mem_r_v = fifo_deq_yumi_i ? valid_r[rptr_r_p1] : (valid_r[rptr_r] & ~loaded_r);

 always_ff @(posedge clk_i)
 begin
   if (reset_i)
     loaded_r <= 1'b0;
    else
     loaded_r <= fifo_deq_yumi_i ? valid_r[rptr_r_p1] : (loaded_r | valid_r[rptr_r]);
 end

  logic [width_p-1:0] mem_data_lo;

  bsg_mem_1r1w_sync #(
    .width_p                (width_p),
    .els_p                  (els_p),
    .read_write_same_addr_p (0),
    .latch_last_read_p      (1)    
  ) mem0 (
    .clk_i   (clk_i),
    .reset_i (reset_i),

    // write port
    .w_v_i   (write_v_i),
    .w_addr_i(write_id_i),
    .w_data_i(write_data_i),

    // read port
    .r_v_i   (mem_r_v),
    .r_addr_i(rptr_n),
    .r_data_o(mem_data_lo)
  );

  assign fifo_deq_v_o    = loaded_r;     
  assign fifo_deq_id_o   = rptr_r;
  assign fifo_deq_data_o = mem_data_lo;

  // One-hot decode of data_id_r

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) clear_demux (
    .i  (rptr_r),
    .v_i(fifo_deq_yumi_i),
    .o  (clear_valid)
  );

  // ----------------------------------------------------------------
  // (10) Assertions (optional)
  // ----------------------------------------------------------------
`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(negedge clk_i) begin
    if (~reset_i) begin
      // Allocate handshake
      if (fifo_alloc_yumi_i)
        assert(fifo_alloc_v_o)
          else $error("Handshake error: fifo_alloc_yumi_i with fifo_alloc_v_o=0.");
      // Dequeue handshake
      if (fifo_deq_yumi_i)
        assert(fifo_deq_v_o)
          else $error("Handshake error: fifo_deq_yumi_i with fifo_deq_v_o=0.");

      // If you disallow overwriting a valid slot, you can check:
      // if (overwrite)
      //   $error("Overwriting a valid slot, which is not allowed by design!");
    end
  end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_reorder_sync)

// mbt & ChatGPT o1 (AI-generated)

// This module extends bsg_fifo_reorder_sync
// by allowing multiple allocation.

`include "bsg_defines.v"

module bsg_fifo_reorder_sync_variable
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)

    // how many entries to lookahead at to provide
    // contiguous availability
    
    , parameter deq_v_width_p = 1'b1

    , localparam lg_els_lp          = `BSG_SAFE_CLOG2(els_p)

    // Because we can allocate up to els_p items in a cycle, set:
    , localparam enq_amount_max_lp  = els_p
    // Allow a single dequeue per cycle.
    , localparam deq_amount_max_lp  = 1
  )
  (
    input                               clk_i
    , input                             reset_i

    // VARIABLE ALLOCATION:
    // Each cycle, fifo_alloc_yumi_variable_i (0..els_p) indicates
    // how many items to allocate in this cycle. The user is responsible
    // for not exceeding the available free entries.
    , input  [`BSG_WIDTH(els_p)-1:0]    fifo_alloc_yumi_variable_i

    // We provide how many free entries are currently available.
    // The user can check (fifo_alloc_v_count_o >= fifo_alloc_yumi_variable_i)
    // before allocating a nonzero amount.
    , output [`BSG_WIDTH(els_p)-1:0]    fifo_alloc_v_count_o

    // OUTPUT: Base pointer (ID) for the newly allocated block of slots.
    // If you allocate X slots, you get { wptr_r, wptr_r+1, ..., wptr_r+X-1 },
    // wrapping around circularly if needed.
    , output [lg_els_lp-1:0]            fifo_alloc_id_o

    // RANDOM ACCESS WRITE
    , input                             write_v_i
    , input  [lg_els_lp-1:0]            write_id_i
    , input  [width_p-1:0]              write_data_i

    // DEQUEUE in order (single item)
    , output [deq_v_width_p-1:0]        fifo_deq_v_o
    , output [width_p-1:0]              fifo_deq_data_o
    , output [lg_els_lp-1:0]            fifo_deq_id_o
    , input                             fifo_deq_yumi_i

    // Indicates the FIFO has no allocated entries
    , output logic                      empty_o
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial begin
    // If you want a run-time check:
    if (!`BSG_IS_POW2(els_p)) begin
      $error("%m ERROR: els_p(%0d) is not a power of two", els_p);
    end
  end
`endif

  // ------------------------------------------------------------
  // (1) FIFO TRACKER (bsg_fifo_tracker_variable)
  // ------------------------------------------------------------
  logic [lg_els_lp-1:0]          wptr_r, rptr_r, rptr_n;
  logic [`BSG_WIDTH(els_p)-1:0]  free_entries_r, used_entries_r;

  bsg_fifo_tracker_variable #(
    .els_p            (els_p),
    .enq_amount_max_p (enq_amount_max_lp),
    .deq_amount_max_p (deq_amount_max_lp)
  ) tracker0 (
    .clk_i           (clk_i),
    .reset_i         (reset_i),

    // Up to els_p allocated (enqueued) in a single cycle
    .enq_amount_i    (fifo_alloc_yumi_variable_i),

    // Single dequeue (1 if dequeuing, else 0)
    .deq_amount_i    (fifo_deq_yumi_i),

    // Pointers
    .wptr_r_o        (wptr_r),
    .rptr_r_o        (rptr_r),
    .rptr_n_o        (rptr_n),

    // Number of unallocated / allocated entries
    .free_entries_r_o(free_entries_r),
    .used_entries_r_o(used_entries_r)
  );

  // Expose how many entries are free
  assign fifo_alloc_v_count_o = free_entries_r;

  // Return the "base pointer" for the newly allocated block
  // If the user requests N > 0, these IDs are wptr_r..(wptr_r+N-1).
  assign fifo_alloc_id_o      = wptr_r;

  // ------------------------------------------------------------
  // (2) VALID BITS for random-access writes
  // ------------------------------------------------------------
  // We only set a valid bit when we actually write to a slot (write_v_i).
  // We clear the valid bit once the slot is dequeued.
  logic [els_p-1:0] valid_r;
  logic [els_p-1:0] set_valid, clear_valid;

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) set_demux (
    .i   (write_id_i),
    .v_i (write_v_i),
    .o   (set_valid)
  );

  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) clear_demux (
    .i   (rptr_r),
    .v_i (fifo_deq_yumi_i),
    .o   (clear_valid)
  );

  // Valid bits register
  bsg_dff_reset_set_clear #(
    .width_p(els_p)
  ) valid_bits (
    .clk_i   (clk_i),
    .reset_i (reset_i),
    .set_i   (set_valid),
    .clear_i (clear_valid),
    .data_o  (valid_r)
  );

  // ------------------------------------------------------------
  // (3) SYNCHRONOUS MEMORY (1R/1W) with address selection
  // ------------------------------------------------------------
  // We read from rptr_r_p1 if we are dequeuing this cycle (looking ahead to
  // the next slot), or from rptr_r if we are not dequeuing. Then we gate the
  // read enable based on whether the relevant slot is valid and not yet loaded.
  // ------------------------------------------------------------

  // Next pointer is rptr_r+1 (for power-of-2 indexing)
  wire [lg_els_lp-1:0] rptr_r_p1 = rptr_r + 1'b1;

  // Memory read address
  wire [lg_els_lp-1:0] mem_r_addr = fifo_deq_yumi_i
                                    ? rptr_r_p1
                                    : rptr_r;

  // Memory read enable: we only read if we are about to load new data
  wire mem_r_v = fifo_deq_yumi_i
                 ? valid_r[rptr_r_p1]
                 : (valid_r[rptr_r] & ~loaded_r);

  logic [width_p-1:0] mem_data_lo;

  bsg_mem_1r1w_sync #(
    .width_p                (width_p),
    .els_p                  (els_p),
    .read_write_same_addr_p (0),
    .latch_last_read_p      (1)
  ) mem0 (
    .clk_i   (clk_i),
    .reset_i (reset_i),

    // WRITE PORT
    .w_v_i   (write_v_i),
    .w_addr_i(write_id_i),
    .w_data_i(write_data_i),

    // READ PORT
    .r_v_i   (mem_r_v),
    .r_addr_i(mem_r_addr),
    .r_data_o(mem_data_lo)
  );

  // ------------------------------------------------------------
  // (4) SINGLE-ITEM DEQUEUE HANDSHAKE
  // ------------------------------------------------------------
  // We'll use a small "loaded_r" register to track if we have valid data
  // latched in mem_data_lo for the current rptr_r.
  // ------------------------------------------------------------
  logic loaded_r;

  always_ff @(posedge clk_i) begin
    if (reset_i) begin
      loaded_r <= 1'b0;
    end
    else begin
      // If we dequeued, we move on to rptr_r_p1 => see if that slot is valid
      if (fifo_deq_yumi_i) begin
        loaded_r <= valid_r[rptr_r_p1];
      end
      else begin
        // If we didn't dequeue, remain loaded or become loaded if rptr_r is valid
        loaded_r <= loaded_r | valid_r[rptr_r];
      end
    end
  end

  // Dequeue signals
  assign fifo_deq_v_o[0] = loaded_r;
  assign fifo_deq_id_o   = rptr_r;
  assign fifo_deq_data_o = mem_data_lo;

  wire [deq_v_width_p-1:0] valid_r_vector, scan_vector;

  generate
    
  genvar i;

  assign valid_r_vector[0] = loaded_r;
  
  for (i = 1; i < deq_v_width_p; i=i+1)
    begin
      assign valid_r_vector[i] = valid_r[(r_ptr_r + i) & (els_p-1)];
    end

  endgenerate
    
  bsg_scan #(.width_p(deq_v_width_p)
             ,.and_p(1'b1)
             ,.lo_to_hi_p(1'b1)
            ) scan
  (.i(valid_r_vector)
   ,.o(scan_vector)
  );

  
  // ------------------------------------------------------------
  // (5) EMPTY INDICATOR
  // ------------------------------------------------------------
  // The FIFO is empty if used_entries_r == 0. This does NOT mean we won't stall
  // if the next pointer is not valid (i.e., never written), but it means no
  // entries have been officially allocated.
  // ------------------------------------------------------------
  assign empty_o = (used_entries_r == '0);

  // ------------------------------------------------------------
  // (6) OPTIONAL ASSERTIONS
  // ------------------------------------------------------------
`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(negedge clk_i) begin
    if (~reset_i) begin
      // Check user does not allocate more than available
      if (fifo_alloc_yumi_variable_i > 0) begin
        assert(fifo_alloc_yumi_variable_i <= free_entries_r)
          else $error("%m Error: Over-allocation attempt (requested=%0d, free=%0d).",
                      fifo_alloc_yumi_variable_i, free_entries_r);
      end

      // Dequeue handshake
      if (fifo_deq_yumi_i) begin
        assert(fifo_deq_v_o)
          else $error("%m Error: Dequeue handshake with no valid data (fifo_deq_v_o=0).");
      end
    end
  end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_reorder_sync_variable)



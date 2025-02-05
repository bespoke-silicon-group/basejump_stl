`include "bsg_defines.v"

module bsg_fifo_reorder_sync_variable
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)

    // Number of slots to allocate (enqueue) atomically in one cycle
    , parameter `BSG_INV_PARAM(alloc_amount_p)

    , localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p)
  )
  (
    input                         clk_i
    , input                       reset_i

    // Allocate next FIFO addresses
    // We allocate alloc_amount_p slots beginning at fifo_alloc_id_o
    // in a single cycle if fifo_alloc_v_o & fifo_alloc_yumi_i handshake.
    , output                      fifo_alloc_v_o
    , output [lg_els_lp-1:0]      fifo_alloc_id_o
    , input                       fifo_alloc_yumi_i

    // Random access write
    , input                       write_v_i
    , input  [lg_els_lp-1:0]      write_id_i
    , input  [width_p-1:0]        write_data_i

    // Dequeue in order
    // For simplicity, we dequeue one item at a time in-order.
    , output                      fifo_deq_v_o
    , output [width_p-1:0]        fifo_deq_data_o
    , output [lg_els_lp-1:0]      fifo_deq_id_o
    , input                       fifo_deq_yumi_i

    // Indicates we have consumed everything that has been allocated
    , output logic                empty_o
  );

  // ---------------------------
  // (1) FIFO TRACKER (variable)
  //     We allow up to alloc_amount_p enqueues in one cycle,
  //     and 1 dequeue in one cycle.
  // ---------------------------
  localparam enq_amount_max_lp = alloc_amount_p;
  localparam deq_amount_max_lp = 1;

  // Pointers and counters from the tracker
  logic [lg_els_lp-1:0] wptr_r, rptr_r, rptr_n;
  logic [`BSG_WIDTH(els_p)-1:0] free_entries_r, used_entries_r;

  bsg_fifo_tracker_variable #(
    .els_p              (els_p),
    .enq_amount_max_p   (enq_amount_max_lp),
    .deq_amount_max_p   (deq_amount_max_lp)
  ) tracker0 (
    .clk_i           (clk_i),
    .reset_i         (reset_i),

    // Amount we want to enqueue/dequeue this cycle
    .enq_amount_i    (fifo_alloc_yumi_i ? alloc_amount_p : '0),
    .deq_amount_i    (fifo_deq_yumi_i    ? 1 : '0),

    // Tracker outputs
    .wptr_r_o        (wptr_r),
    .rptr_r_o        (rptr_r),
    .rptr_n_o        (rptr_n),

    .free_entries_r_o(free_entries_r),
    .used_entries_r_o(used_entries_r)
  );

  // ---------------------------
  // (2) ALLOC HANDSHAKE
  //
  // fifo_alloc_v_o goes high only if we have enough
  // space to allocate `alloc_amount_p` items.
  // ---------------------------
  assign fifo_alloc_v_o  = (free_entries_r >= alloc_amount_p);
  assign fifo_alloc_id_o = wptr_r;

  // ---------------------------
  // (3) VALID BITS
  //
  // We set valid bits only when there is a random-access write.
  // The "allocate" itself does not automatically set valid bits,
  // since you may fill those addresses later.  If you do not
  // write all allocated addresses, the FIFO will stall on dequeue
  // once it reaches an un-written (invalid) slot.
  // ---------------------------
  logic [els_p-1:0] valid_r;
  logic [els_p-1:0] set_valid, clear_valid;

  // Mark the slot as valid when we do a write
  bsg_decode_with_v #(
    .num_out_p(els_p)
  ) set_demux (
    .i   (write_id_i),
    .v_i (write_v_i),
    .o   (set_valid)
  );

  // Mark the slot as invalid (cleared) once we dequeue it
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

  // ---------------------------
  // (4) SYNCHRONOUS MEMORY
  //
  // One read port, one write port. We latch the read data
  // so we can hold it stable while the pointers move.
  // ---------------------------
  // We read the slot that we will be dequeueing next cycle.
  // Because we are popping one item at a time, the next read
  // address is rptr_n, which depends combinationally on fifo_deq_yumi_i.
  // ---------------------------
  logic [width_p-1:0] mem_data_lo;

  // We use a "read valid" to reduce spurious memory reads:
  // * If we are dequeuing this cycle, next cycle's pointer is rptr_n,
  //   so we read that address for next data.
  // * If we are not dequeuing, we read the same pointer we would
  //   dequeue next time.  However, we also need to ensure we
  //   actually have a valid next slot before reading.
  //
  // A simpler approach is always read rptr_n each cycle, but
  // below is an illustration for optional gating.
  //
  wire read_v = (fifo_deq_yumi_i)
                ? valid_r[rptr_n]    // after pointer is advanced
                : valid_r[rptr_r];   // if we are not advancing

  bsg_mem_1r1w_sync #(
    .width_p                (width_p),
    .els_p                  (els_p),
    .read_write_same_addr_p (0),
    .latch_last_read_p      (1)
  ) mem0 (
    .clk_i   (clk_i),
    .reset_i (reset_i),

    // Write port
    .w_v_i   (write_v_i),
    .w_addr_i(write_id_i),
    .w_data_i(write_data_i),

    // Read port
    .r_v_i   (read_v),
    .r_addr_i(fifo_deq_yumi_i ? rptr_n : rptr_r),
    .r_data_o(mem_data_lo)
  );

  // ---------------------------
  // (5) DEQUEUE HANDSHAKE
  //
  // We have valid data (fifo_deq_v_o = 1) if the current slot
  // has been written (valid_r[rptr_r]) and we have latched it
  // from memory. We use a small register loaded_r to track when
  // we have captured valid data in mem_data_lo.
  // ---------------------------
  logic loaded_r;

  always_ff @(posedge clk_i) begin
    if (reset_i)
      loaded_r <= 1'b0;
    else begin
      // If we just dequeued, next cycle's data will come from rptr_n if valid
      // If we did not dequeue, we become loaded if current pointer has valid data
      if (fifo_deq_yumi_i)
        loaded_r <= valid_r[rptr_n];
      else
        loaded_r <= loaded_r | valid_r[rptr_r];
    end
  end

  // Output handshake
  assign fifo_deq_v_o    = loaded_r;
  assign fifo_deq_id_o   = rptr_r;
  assign fifo_deq_data_o = mem_data_lo;

  // ---------------------------
  // (6) FIFO EMPTY
  // ---------------------------
  // bsg_fifo_tracker_variable doesn't directly give "empty_o",
  // so we compute it from the used-entries count.
  // (Alternatively, you can track it inside an always_comb.)
  // ---------------------------
  assign empty_o = (used_entries_r == '0);

  // ---------------------------
  // (7) Optional run-time checks
  // ---------------------------
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
    end
  end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_reorder_sync_variable)

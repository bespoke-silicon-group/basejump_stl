`timescale 1ns/1ps
`include "bsg_defines.sv"

// ---------------------------------------------------------------
// Testbench for bsg_fifo_1r1w_small_hardened_multi
// ---------------------------------------------------------------
module tb_bsg_fifo_1r1w_small_hardened_multi
  #(parameter int WIDTH = 32
    , parameter int ELS = 4
    , parameter int FIFOS = 4
    , parameter int NUM_CYC = 200000
    , parameter int ENQ_PCT = 60
    , parameter int DEQ_PCT = 60
    );

  localparam int LG_FIFOS = (FIFOS <= 1) ? 1 : $clog2(FIFOS);
  localparam int SEQ_WIDTH = WIDTH - LG_FIFOS;
  localparam int FIFO0_ID = 0;
  localparam int FIFO1_ID = (FIFOS > 1) ? 1 : 0;
  localparam int FIFO2_ID = (FIFOS > 2) ? 2 : FIFO1_ID;

  initial begin
    if (SEQ_WIDTH <= 0) begin
      $error("WIDTH must be > LG_FIFOS (WIDTH=%0d LG_FIFOS=%0d)", WIDTH, LG_FIFOS);
      $fatal(1);
    end
  end

  // ------------------------ Clock / Reset -----------------------
  logic clk, reset;
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1'b1;
    repeat (10) @(posedge clk);
    reset = 1'b0;
  end

  // ------------------------ DUT Signals -------------------------
  logic                   v_i;
  logic [LG_FIFOS-1:0]    enq_id_i;
  logic [FIFOS-1:0]       ready_param_o;
  logic [WIDTH-1:0]       data_i;

  logic [FIFOS-1:0]       v_o;
  logic [FIFOS-1:0][WIDTH-1:0] data_o;
  logic [LG_FIFOS-1:0]    deq_id_i;
  logic [FIFOS-1:0]       yumi_i;

  // ------------------------ DUT Instantiation -------------------
  bsg_fifo_1r1w_small_hardened_multi
    #(.width_p(WIDTH)
      ,.els_p(ELS)
      ,.fifos_p(FIFOS)
      )
  dut
    (.clk_i(clk)
     ,.reset_i(reset)
     ,.v_i(v_i)
     ,.ready_param_o(ready_param_o)
     ,.data_i(data_i)
     ,.v_o(v_o)
     ,.data_o(data_o)
     ,.yumi_i(yumi_i)
     ,.enq_id_i(enq_id_i)
     );

  // ------------------------ Scoreboard --------------------------
  typedef logic [WIDTH-1:0] data_t;
  data_t exp_q [FIFOS][$];
  logic [SEQ_WIDTH-1:0] enq_seq [FIFOS];
  int unsigned enq_cnt [FIFOS];
  int unsigned deq_cnt [FIFOS];

  // Data generator: {fifo_id, seq}
  always_comb begin
    data_i = {enq_id_i, enq_seq[enq_id_i]};
  end

  // ------------------------ Random seed -------------------------
  int unsigned seed;
  initial begin
    seed = 32'hBADC0FFE;
    void'($value$plusargs("seed=%d", seed));
    void'($urandom(seed));
  end

  // ------------------------ Phase control -----------------------
  int unsigned rand_cycles_left;
  logic directed_active;
  int unsigned directed_step;
  wire drain_mode = (!directed_active) && (rand_cycles_left == 0);

  always_ff @(posedge clk) begin
    if (reset)
      rand_cycles_left <= NUM_CYC;
    else if (!directed_active && rand_cycles_left != 0)
      rand_cycles_left <= rand_cycles_left - 1;
  end

  // ------------------------ Utility: first hot index ------------
  function automatic [LG_FIFOS-1:0] first_hot_idx (input logic [FIFOS-1:0] vec);
    int j;
    first_hot_idx = '0;
    for (j = 0; j < FIFOS; j++) begin
      if (vec[j]) begin
        first_hot_idx = j[LG_FIFOS-1:0];
        break;
      end
    end
  endfunction

  function automatic [FIFOS-1:0] onehot_from_idx (input logic [LG_FIFOS-1:0] idx);
    onehot_from_idx = '0;
    onehot_from_idx[idx] = 1'b1;
  endfunction

  // ------------------------ Handshake wires ---------------------
  wire ready_sel   = ready_param_o[enq_id_i];
  wire do_enq_now  = v_i & ready_sel;
  wire do_deq_now  = |yumi_i;
  wire [LG_FIFOS-1:0] deq_id_sel = first_hot_idx(v_o);

  // ------------------------ Driver (directed + random) ----------
  logic do_enq_req, do_deq_req;
  logic [LG_FIFOS-1:0] enq_id_rand, deq_id_rand;

  always_ff @(negedge clk) begin
    if (reset) begin
      v_i <= 1'b0;
      enq_id_i <= '0;
      yumi_i <= '0;
      deq_id_i <= '0;
      directed_active <= 1'b1;
      directed_step <= 0;
      do_enq_req <= 1'b0;
      do_deq_req <= 1'b0;
      enq_id_rand <= '0;
      deq_id_rand <= '0;
    end
    else if (directed_active) begin
      v_i <= 1'b0;
      enq_id_i <= '0;
      yumi_i <= '0;
      deq_id_i <= '0;

      unique case (directed_step)
        0: begin
          directed_step <= 1;
        end
        // Empty -> enqueue -> dequeue (bypass path)
        1: begin
          enq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          if (do_enq_now)
            directed_step <= 2;
        end
        2: begin
          deq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          yumi_i <= v_o[FIFO0_ID]
            ? onehot_from_idx(FIFO0_ID[LG_FIFOS-1:0])
            : '0;
          if (do_deq_now)
            directed_step <= 3;
        end
        // One element -> enq+deq same cycle (bypass set dominates clear)
        3: begin
          enq_id_i <= FIFO1_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          if (do_enq_now)
            directed_step <= 4;
        end
        4: begin
          enq_id_i <= FIFO1_ID[LG_FIFOS-1:0];
          deq_id_i <= FIFO1_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          yumi_i <= v_o[FIFO1_ID]
            ? onehot_from_idx(FIFO1_ID[LG_FIFOS-1:0])
            : '0;
          if (do_enq_now && do_deq_now)
            directed_step <= 5;
        end
        5: begin
          deq_id_i <= FIFO1_ID[LG_FIFOS-1:0];
          yumi_i <= v_o[FIFO1_ID]
            ? onehot_from_idx(FIFO1_ID[LG_FIFOS-1:0])
            : '0;
          if (do_deq_now)
            directed_step <= 6;
        end
        // Two+ elements + dequeue, and cross-fifo enq/deq
        6: begin
          enq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          if (do_enq_now)
            directed_step <= 7;
        end
        7: begin
          enq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          if (do_enq_now)
            directed_step <= 8;
        end
        8: begin
          enq_id_i <= FIFO2_ID[LG_FIFOS-1:0];
          deq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          v_i <= 1'b1;
          yumi_i <= v_o[FIFO0_ID]
            ? onehot_from_idx(FIFO0_ID[LG_FIFOS-1:0])
            : '0;
          if (do_enq_now && do_deq_now)
            directed_step <= 9;
        end
        9: begin
          deq_id_i <= FIFO0_ID[LG_FIFOS-1:0];
          yumi_i <= v_o[FIFO0_ID]
            ? onehot_from_idx(FIFO0_ID[LG_FIFOS-1:0])
            : '0;
          if (do_deq_now)
            directed_active <= 1'b0;
        end
        default: directed_active <= 1'b0;
      endcase
    end
    else if (!drain_mode) begin
      do_enq_req  <= ($urandom_range(99) < ENQ_PCT);
      enq_id_rand <= $urandom_range(FIFOS-1, 0);
      v_i      <= do_enq_req;
      enq_id_i <= enq_id_rand;

      do_deq_req  <= ($urandom_range(99) < DEQ_PCT);
      deq_id_rand <= $urandom_range(FIFOS-1, 0);
      yumi_i   <= (do_deq_req & v_o[deq_id_rand])
        ? onehot_from_idx(deq_id_rand)
        : '0;
      deq_id_i <= deq_id_rand;
    end
    else begin
      v_i <= 1'b0;
      enq_id_i <= '0;
      if (v_o != '0) begin
        deq_id_i <= deq_id_sel;
        yumi_i <= onehot_from_idx(deq_id_sel);
      end
      else begin
        yumi_i <= '0;
        deq_id_i <= '0;
      end
    end
  end

  // ------------------------ Data checks (cycle-accurate) --------
  always_ff @(negedge clk) begin
    if (!reset) begin
      for (int i = 0; i < FIFOS; i++) begin
        if (v_o[i] !== (exp_q[i].size() != 0)) begin
          $error("[%0t] v_o mismatch fifo %0d exp=%0d got=%0b",
                 $time, i, exp_q[i].size(), v_o[i]);
          $fatal(1);
        end
        if (ready_param_o[i] !== (exp_q[i].size() < ELS)) begin
          $error("[%0t] ready mismatch fifo %0d exp=%0d got=%0b",
                 $time, i, (exp_q[i].size() < ELS), ready_param_o[i]);
          $fatal(1);
        end
        if (v_o[i]) begin
          if (exp_q[i].size() == 0) begin
            $error("[%0t] TB underflow on fifo %0d", $time, i);
            $fatal(1);
          end
          if (data_o[i] !== exp_q[i][0]) begin
            $error("[%0t] data mismatch fifo %0d exp=%0h got=%0h",
                   $time, i, exp_q[i][0], data_o[i]);
            $fatal(1);
          end
        end
      end
    end
  end

  // ------------------------ Scoreboard update -------------------
  always_ff @(posedge clk) begin
    if (reset) begin
      for (int i = 0; i < FIFOS; i++) begin
        enq_seq[i] <= '0;
        enq_cnt[i] <= 0;
        deq_cnt[i] <= 0;
        exp_q[i].delete();
      end
    end
    else begin
      if (do_deq_now) begin
        if (exp_q[deq_id_i].size() == 0) begin
          $error("[%0t] TB underflow on fifo %0d", $time, deq_id_i);
          $fatal(1);
        end
        exp_q[deq_id_i].pop_front();
        deq_cnt[deq_id_i] <= deq_cnt[deq_id_i] + 1;
      end

      if (do_enq_now) begin
        exp_q[enq_id_i].push_back(data_i);
        enq_seq[enq_id_i] <= enq_seq[enq_id_i] + 1'b1;
        enq_cnt[enq_id_i] <= enq_cnt[enq_id_i] + 1;
      end
    end
  end

  // ------------------------ Completion checks -------------------
  initial begin : finish_block
    @(negedge reset);
    wait (directed_active == 1'b0);
    wait (rand_cycles_left == 0);
    wait (v_o == '0);
    repeat (4) @(posedge clk);

    for (int i = 0; i < FIFOS; i++) begin
      if (exp_q[i].size() != 0) begin
        $error("FIFO %0d not empty at end: occ=%0d", i, exp_q[i].size());
        $fatal(1);
      end
      if ((enq_cnt[i] - deq_cnt[i]) != 0) begin
        $error("FIFO %0d count mismatch: enq=%0d deq=%0d", i, enq_cnt[i], deq_cnt[i]);
        $fatal(1);
      end
    end

    $display("PASS: all FIFOs drained; counts match; data ordering verified.");
    $finish;
  end

endmodule

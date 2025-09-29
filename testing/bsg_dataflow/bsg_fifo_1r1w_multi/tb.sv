`timescale 1ns/1ps
`include "bsg_defines.sv"

// ---------------------------------------------------------------
// Testbench for bsg_fifo_1r1w_multi
// ---------------------------------------------------------------
module tb_bsg_fifo_1r1w_multi
  #(parameter int N        = 4,
    parameter int K        = 64,
    parameter int LO_BITS  = 24,
    parameter int NUM_CYC  = 20000000,
    parameter int ENQ_PCT  = 60,
    parameter int DEQ_PCT  = 60
    );

  // ------------------------ Local params ------------------------
  localparam int LG_N  = (N <= 1) ? 1 : $clog2(N);
  localparam int LG_K  = (K <= 1) ? 1 : $clog2(K);
  localparam int DW    = LG_N + LO_BITS;

  // ------------------------ Clock / Reset -----------------------
  logic clk, reset;

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;         // 100 MHz
  end

  initial begin
    reset = 1'b1;
    repeat (10) @(posedge clk);
    reset = 1'b0;
  end

  // ------------------------ DUT Signals -------------------------
  logic                   v_i;
  logic [LG_N-1:0]        enq_id_i;
  wire                    ready_and_o;

  wire [N-1:0]            v_o;

  logic [LG_N-1:0]        deq_id_i;
  logic                   yumi_i;

  wire [LG_K-1:0]         raddr_o;
  wire [LG_K-1:0]         waddr_o;

  // ------------------------ DUT Instantiation -------------------
  bsg_fifo_1r1w_multi
    #(.fifos_p(N)
      ,.total_els_p(K)
      )
  dut
    (.clk_i     (clk)
     ,.reset_i  (reset)
     ,.v_i      (v_i)
     ,.enq_id_i (enq_id_i)
     ,.ready_and_o(ready_and_o)
     ,.v_o      (v_o)
     ,.deq_id_i (deq_id_i)
     ,.yumi_i   (yumi_i)
     ,.raddr_o  (raddr_o)
     ,.waddr_o  (waddr_o)
     );

  // ------------------------ Payload RAM model -------------------
  // Simple synchronous 1R1W model: read returns data next cycle.
  logic [DW-1:0] payload_mem [0:K-1];

  // 1-cycle read pipeline
  logic          rd_v_q;
  logic [DW-1:0] rd_data_q, exp_data_q;

  // ------------------------ Scoreboard / State ------------------
  typedef logic [DW-1:0] data_t;

  // A queue per FIFO storing expected outputs
  data_t exp_q [N][$];

  // Per-FIFO sequence counters (low bits embedded in payload)
  logic [LO_BITS-1:0] enq_seq [N];

  // Per-FIFO accounting
  int unsigned enq_cnt [N];
  int unsigned deq_cnt [N];

// ----- Coverage sample signals -----
   int unsigned occ_i   [N];
   bit enq_evt [N];
   bit deq_evt [N];


   
  // ------------------------ Random seeds ------------------------
  int unsigned seed;
  initial begin
    seed = 32'hD00D_F00D;
    void'($value$plusargs("seed=%d", seed));
    void'($urandom(seed));
  end

  // ------------------------ Phase control -----------------------
  // After NUM_CYC, testbench transitions to drain mode automatically.
  int unsigned rand_cycles_left;
  wire drain_mode = (rand_cycles_left == 0);

  always_ff @(posedge clk) begin
    if (reset) rand_cycles_left <= NUM_CYC;
    else if (rand_cycles_left != 0) rand_cycles_left <= rand_cycles_left - 1;
  end

  // ------------------------ Utility: first hot index ------------
  function automatic [LG_N-1:0] first_hot_idx (input logic [N-1:0] vec);
    int j;
    first_hot_idx = '0;
    for (j = 0; j < N; j++) begin
      if (vec[j]) begin
        first_hot_idx = j[LG_N-1:0];
        break;
      end
    end
  endfunction

  // ------------------------ Driver (single source) --------------
  // One and only one process drives v_i/enq_id_i/yumi_i/deq_id_i.
  // Random phase: randomized enq/deq attempts.
  // Drain phase : stop enq, deq from first non-empty FIFO each cycle.
  logic do_enq_req, do_deq_req;
  logic [LG_N-1:0] enq_id_rand, deq_id_rand;

  always_ff @(negedge clk) begin
    if (reset) begin
      v_i         <= 1'b0;
      enq_id_i    <= '0;
      yumi_i      <= 1'b0;
      deq_id_i    <= '0;
      do_enq_req  <= 1'b0;
      do_deq_req  <= 1'b0;
      enq_id_rand <= '0;
      deq_id_rand <= '0;
    end
    else if (!drain_mode) begin
      // Random phase
      do_enq_req  <= ($urandom_range(99) < ENQ_PCT);
      enq_id_rand <= $urandom_range(N-1, 0);

      v_i      <= do_enq_req;
      enq_id_i <= enq_id_rand;

      do_deq_req  <= ($urandom_range(99) < DEQ_PCT);
      deq_id_rand <= $urandom_range(N-1, 0);

      // Only dequeue from non-empty to respect DUT assertion
      yumi_i   <= (do_deq_req & v_o[deq_id_rand]);
      deq_id_i <= deq_id_rand;
    end
    else begin
      // Drain phase
      v_i      <= 1'b0;                 // stop enqueue
      enq_id_i <= '0;

      if (v_o != '0) begin
        yumi_i   <= 1'b1;               // deq every cycle while non-empty
        deq_id_i <= first_hot_idx(v_o); // pick first non-empty FIFO
      end
      else begin
        yumi_i   <= 1'b0;
        deq_id_i <= '0;
      end
    end
  end

  // ------------------------ Handshakes as wires -----------------
  wire do_enq_now = (v_i & ready_and_o);
  wire do_deq_now = yumi_i;

  // ------------------------ Scoreboard + RAM IO -----------------
  // On each posedge:
  //   - Check last cycle's dequeue (rd_v_q) -> compare rd_data_q vs exp_data_q
  //   - Handle this cycle's enqueue/dequeue and model payload RAM sync read/write
  always_ff @(posedge clk) begin
    if (reset) begin
      rd_v_q     <= 1'b0;
      rd_data_q  <= '0;
      exp_data_q <= '0;

      for (int i = 0; i < N; i++) begin
        enq_seq[i] <= '0;
        enq_cnt[i] <= 0;
        deq_cnt[i] <= 0;
        exp_q[i].delete();
      end
    end
    else begin
      // 1) Check prior read against scoreboard
      if (rd_v_q) begin
        if (rd_data_q !== exp_data_q) begin
          $error("[%0t] MISMATCH: rd_data=%0h exp=%0h", $time, rd_data_q, exp_data_q);
          $fatal(1);
        end
      end

      // 2) Dequeue bookkeeping and read capture
      if (do_deq_now) begin
        if (exp_q[deq_id_i].size() == 0) begin
          $error("[%0t] TB underflow on fifo %0d", $time, deq_id_i);
          $fatal(1);
        end

        rd_v_q     <= 1'b1;                 // sync read: check next cycle
        rd_data_q  <= payload_mem[raddr_o];
        exp_data_q <= exp_q[deq_id_i][0];
        exp_q[deq_id_i].pop_front();
        deq_cnt[deq_id_i] <= deq_cnt[deq_id_i] + 1;
      end
      else begin
        rd_v_q <= 1'b0;
      end

      // 3) Enqueue write and scoreboard push
      if (do_enq_now) begin
        payload_mem[waddr_o] <= { enq_id_i, enq_seq[enq_id_i] };
        exp_q[enq_id_i].push_back({ enq_id_i, enq_seq[enq_id_i] });
        enq_seq[enq_id_i]     <= enq_seq[enq_id_i] + 1'b1;
        enq_cnt[enq_id_i]     <= enq_cnt[enq_id_i] + 1;
      end
    end
  end



   always_ff @(posedge clk)
     if (reset) 
       begin
	  for (int i = 0; i < N; i++) 
	    begin
	       occ_i  [i] <= '0;
	       enq_evt[i] <= 1'b0;
	       deq_evt[i] <= 1'b0;
	    end
       end // if (reset)
     else 
       begin
	  // Update coverage sample signals
	  for (int i = 0; i < N; i++) 
	    begin
	       occ_i[i]   <= exp_q[i].size();
	       // current occupancy
	       enq_evt[i] <= (do_enq_now && (enq_id_i == i[LG_N-1:0]));
	       // enq accepted for this FIFO
	       deq_evt[i] <= (do_deq_now && (deq_id_i == i[LG_N-1:0]));
	       // deq accepted for this FIFO
	    end
       end // else: !if(reset)

// -----------------------------------------------------------------------------
   // Functional coverage: for each FIFO, cover occupancy X enq X deq
   // -----------------------------------------------------------------------------
   generate
      for (genvar gi = 0; gi < N; gi++) begin : g_cov
	 localparam int ID = gi;
	 // One covergroup per FIFO instance, sampled on posedge clk
	 covergroup cg_fifo_occ_enq_deq @(posedge clk);
	    option.per_instance = 1;
	    
	    cp_occ : coverpoint occ_i[ID] iff (!reset) {
               bins occ[] = {[0:K]};
            }
	    // Enqueue accepted for this FIFO (0/1)
	    cp_enq : coverpoint enq_evt[ID] iff (!reset) {
               bins no  = {0};
               bins yes = {1};
            }
          // Dequeue accepted for this FIFO (0/1)
          // Dequeue accepted for this FIFO (0/1)
           cp_deq : coverpoint deq_evt[ID] iff (!reset) {
               bins no  = {0};
               bins yes = {1};
	    }

         // Cross: occupancy X enq X deq
           x_occ_enq_deq : cross cp_occ, cp_enq, cp_deq;
         endgroup

         cg_fifo_occ_enq_deq cg_inst = new();

         // Nice instance names in the coverage database
         initial cg_inst.set_inst_name($sformatf("fifo%0d_occXenqXdeq", ID));
     end
   endgenerate


   
  // ------------------------ Completion & final checks -----------
  initial begin : finish_block
    @(negedge reset);

    // Wait for random phase to end
    wait (rand_cycles_left == 0);

    // Wait until DUT reports all FIFOs empty
    wait (v_o == '0);

    // Allow a few cycles for last read to be checked
    repeat (4) @(posedge clk);

    // Final checks: all queues empty and counts balanced
    for (int i = 0; i < N; i++) begin
      if (exp_q[i].size() != 0) begin
        $error("FIFO %0d not empty at end: occ=%0d", i, exp_q[i].size());
        $fatal(1);
      end
      if ((enq_cnt[i] - deq_cnt[i]) != 0) begin
        $error("FIFO %0d count mismatch: enq=%0d deq=%0d", i, enq_cnt[i], deq_cnt[i]);
        $fatal(1);
      end

       $display("%d: enq_cnt: %d, deq_cnt=%d NUM_CYCLE=%d",i,enq_cnt[i],deq_cnt[i],NUM_CYC);
    end

    $display("PASS: all FIFOs drained; counts match; data ordering verified.");
    $finish;
  end

  // ------------------------ Optional payload RAW assert --------
`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(posedge clk) if (!reset) begin
    if (v_i & ready_and_o & yumi_i) begin
      assert (waddr_o != raddr_o)
        else $error("%m: payload RAM same-address R+W in one cycle");
    end
  end
`endif

endmodule

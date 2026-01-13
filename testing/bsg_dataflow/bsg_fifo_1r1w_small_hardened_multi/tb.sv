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
  int unsigned occ_pre [FIFOS];
  int unsigned occ_post [FIFOS];
  int signed   occ_delta [FIFOS];
  logic [FIFOS-1:0] enq_evt, deq_evt, bypass_evt;
  logic [FIFOS-1:0] wptr_wrap_pre, rptr_wrap_pre;
  int unsigned wptr_pos_pre [FIFOS];
  int unsigned rptr_pos_pre [FIFOS];

  covergroup fifo_cg (int fifo_id) with function sample
    (int occ_pre, int occ_post, int delta, bit enq, bit deq, bit bypass,
     bit wptr_wrap, bit rptr_wrap, int wptr_pos, int rptr_pos);
    option.per_instance = 1;
    occ_pre_cp: coverpoint occ_pre { bins occ_bins[] = {[0:ELS]}; }
    occ_post_cp: coverpoint occ_post { bins occ_bins[] = {[0:ELS]}; }
    delta_cp: coverpoint delta
      { bins dec = {-1};
        bins hold = {0};
        bins inc = {1};
      }
    op_cp: coverpoint {enq, deq}
      { bins idle = {2'b00};
        bins enq_only = {2'b10};
        bins deq_only = {2'b01};
        bins enq_deq = {2'b11};
      }
    bypass_cp: coverpoint bypass { bins no = {1'b0}; bins yes = {1'b1}; }
    wptr_wrap_cp: coverpoint wptr_wrap { bins no = {1'b0}; bins yes = {1'b1}; }
    rptr_wrap_cp: coverpoint rptr_wrap { bins no = {1'b0}; bins yes = {1'b1}; }
    wptr_pos_cp: coverpoint wptr_pos { bins pos[] = {[0:ELS-1]}; }
    rptr_pos_cp: coverpoint rptr_pos { bins pos[] = {[0:ELS-1]}; }
    occ_delta_x: cross occ_pre_cp, delta_cp
      {
        ignore_bins underflow =
          binsof(occ_pre_cp) intersect {0} && binsof(delta_cp.dec);
        ignore_bins overflow =
          binsof(occ_pre_cp) intersect {ELS} && binsof(delta_cp.inc);
      }
    occ_op_x: cross occ_pre_cp, op_cp
      {
        ignore_bins deq_on_empty =
          binsof(occ_pre_cp) intersect {0} && binsof(op_cp.deq_only);
        ignore_bins deq_on_empty_enq =
          binsof(occ_pre_cp) intersect {0} && binsof(op_cp.enq_deq);
        ignore_bins enq_on_full =
          binsof(occ_pre_cp) intersect {ELS} && binsof(op_cp.enq_only);
        ignore_bins enq_on_full_deq =
          binsof(occ_pre_cp) intersect {ELS} && binsof(op_cp.enq_deq);
      }
    occ_rptr_x: cross occ_pre_cp, rptr_pos_cp;
    occ_wptr_x: cross occ_pre_cp, wptr_pos_cp;
  endgroup

  fifo_cg fifo_cov [FIFOS];

  localparam bit full_ctrl_cov_lp = (FIFOS == 2) && (ELS == 3);
  localparam bit wrap_cov_lp = (ELS > 1);

  if (full_ctrl_cov_lp) begin: full_ctrl_cov_gen
    covergroup full_ctrl_cg with function sample
      (int occ0, int occ1, int enq_sel, int deq_sel, bit bypass0, bit bypass1);
      option.per_instance = 1;
      occ0_cp: coverpoint occ0 { bins occ_bins[] = {[0:ELS]}; }
      occ1_cp: coverpoint occ1 { bins occ_bins[] = {[0:ELS]}; }
      enq_sel_cp: coverpoint enq_sel
        { bins idle = {0};
          bins fifo0 = {1};
          bins fifo1 = {2};
          ignore_bins invalid = {3};
        }
      deq_sel_cp: coverpoint deq_sel
        { bins idle = {0};
          bins fifo0 = {1};
          bins fifo1 = {2};
          ignore_bins invalid = {3};
        }
      bypass0_cp: coverpoint bypass0 { bins no = {1'b0}; bins yes = {1'b1}; }
      bypass1_cp: coverpoint bypass1 { bins no = {1'b0}; bins yes = {1'b1}; }
      full_ctrl_x: cross occ0_cp, occ1_cp, enq_sel_cp, deq_sel_cp, bypass0_cp, bypass1_cp
        {
          ignore_bins enq0_full =
            binsof(occ0_cp) intersect {ELS} && binsof(enq_sel_cp.fifo0);
          ignore_bins enq1_full =
            binsof(occ1_cp) intersect {ELS} && binsof(enq_sel_cp.fifo1);
          ignore_bins deq0_empty =
            binsof(occ0_cp) intersect {0} && binsof(deq_sel_cp.fifo0);
          ignore_bins deq1_empty =
            binsof(occ1_cp) intersect {0} && binsof(deq_sel_cp.fifo1);
          ignore_bins bypass0_without_enq0_idle =
            binsof(bypass0_cp.yes) && binsof(enq_sel_cp.idle);
          ignore_bins bypass0_without_enq0_fifo1 =
            binsof(bypass0_cp.yes) && binsof(enq_sel_cp.fifo1);
          ignore_bins bypass0_when_occ0_ge2 =
            binsof(occ0_cp) intersect {[2:ELS]} && binsof(enq_sel_cp.fifo0)
            && binsof(bypass0_cp.yes);
          ignore_bins bypass0_must_be_1_empty =
            binsof(occ0_cp) intersect {0} && binsof(enq_sel_cp.fifo0)
            && binsof(bypass0_cp.no);
          ignore_bins bypass0_must_be_1_deq0 =
            binsof(occ0_cp) intersect {1} && binsof(enq_sel_cp.fifo0)
            && binsof(deq_sel_cp.fifo0) && binsof(bypass0_cp.no);
          ignore_bins bypass0_not_with_deq_idle =
            binsof(occ0_cp) intersect {1} && binsof(enq_sel_cp.fifo0)
            && binsof(deq_sel_cp.idle) && binsof(bypass0_cp.yes);
          ignore_bins bypass0_not_with_deq1 =
            binsof(occ0_cp) intersect {1} && binsof(enq_sel_cp.fifo0)
            && binsof(deq_sel_cp.fifo1) && binsof(bypass0_cp.yes);
          ignore_bins bypass1_without_enq1_idle =
            binsof(bypass1_cp.yes) && binsof(enq_sel_cp.idle);
          ignore_bins bypass1_without_enq1_fifo0 =
            binsof(bypass1_cp.yes) && binsof(enq_sel_cp.fifo0);
          ignore_bins bypass1_when_occ1_ge2 =
            binsof(occ1_cp) intersect {[2:ELS]} && binsof(enq_sel_cp.fifo1)
            && binsof(bypass1_cp.yes);
          ignore_bins bypass1_must_be_1_empty =
            binsof(occ1_cp) intersect {0} && binsof(enq_sel_cp.fifo1)
            && binsof(bypass1_cp.no);
          ignore_bins bypass1_must_be_1_deq1 =
            binsof(occ1_cp) intersect {1} && binsof(enq_sel_cp.fifo1)
            && binsof(deq_sel_cp.fifo1) && binsof(bypass1_cp.no);
          ignore_bins bypass1_not_with_deq_idle =
            binsof(occ1_cp) intersect {1} && binsof(enq_sel_cp.fifo1)
            && binsof(deq_sel_cp.idle) && binsof(bypass1_cp.yes);
          ignore_bins bypass1_not_with_deq0 =
            binsof(occ1_cp) intersect {1} && binsof(enq_sel_cp.fifo1)
            && binsof(deq_sel_cp.fifo0) && binsof(bypass1_cp.yes);
        }
    endgroup

    covergroup full_ptr_cg with function sample
      (int wptr0, int rptr0, int wptr1, int rptr1, int enq_sel, int deq_sel);
      option.per_instance = 1;
      wptr0_cp: coverpoint wptr0 { bins pos[] = {[0:ELS-1]}; }
      rptr0_cp: coverpoint rptr0 { bins pos[] = {[0:ELS-1]}; }
      wptr1_cp: coverpoint wptr1 { bins pos[] = {[0:ELS-1]}; }
      rptr1_cp: coverpoint rptr1 { bins pos[] = {[0:ELS-1]}; }
      enq_sel_cp: coverpoint enq_sel
        { bins idle = {0};
          bins fifo0 = {1};
          bins fifo1 = {2};
          ignore_bins invalid = {3};
        }
      deq_sel_cp: coverpoint deq_sel
        { bins idle = {0};
          bins fifo0 = {1};
          bins fifo1 = {2};
          ignore_bins invalid = {3};
        }
      full_ptr_x: cross wptr0_cp, rptr0_cp, wptr1_cp, rptr1_cp, enq_sel_cp, deq_sel_cp
        {
          ignore_bins enq_deq0_eq_0 =
            binsof(enq_sel_cp.fifo0) && binsof(deq_sel_cp.fifo0)
            && binsof(wptr0_cp) intersect {0} && binsof(rptr0_cp) intersect {0};
          ignore_bins enq_deq0_eq_1 =
            binsof(enq_sel_cp.fifo0) && binsof(deq_sel_cp.fifo0)
            && binsof(wptr0_cp) intersect {1} && binsof(rptr0_cp) intersect {1};
          ignore_bins enq_deq0_eq_2 =
            binsof(enq_sel_cp.fifo0) && binsof(deq_sel_cp.fifo0)
            && binsof(wptr0_cp) intersect {2} && binsof(rptr0_cp) intersect {2};
          ignore_bins enq_deq1_eq_0 =
            binsof(enq_sel_cp.fifo1) && binsof(deq_sel_cp.fifo1)
            && binsof(wptr1_cp) intersect {0} && binsof(rptr1_cp) intersect {0};
          ignore_bins enq_deq1_eq_1 =
            binsof(enq_sel_cp.fifo1) && binsof(deq_sel_cp.fifo1)
            && binsof(wptr1_cp) intersect {1} && binsof(rptr1_cp) intersect {1};
          ignore_bins enq_deq1_eq_2 =
            binsof(enq_sel_cp.fifo1) && binsof(deq_sel_cp.fifo1)
            && binsof(wptr1_cp) intersect {2} && binsof(rptr1_cp) intersect {2};
        }
    endgroup

    full_ctrl_cg full_ctrl_cov;
    full_ptr_cg full_ptr_cov;

    initial begin
      full_ctrl_cov = new();
      full_ptr_cov = new();
    end

    always_ff @(negedge clk) begin
      if (!reset) begin
        int enq_sel;
        int deq_sel;
        unique case (enq_evt)
          2'b00: enq_sel = 0;
          2'b01: enq_sel = 1;
          2'b10: enq_sel = 2;
          default: enq_sel = 3;
        endcase
        unique case (deq_evt)
          2'b00: deq_sel = 0;
          2'b01: deq_sel = 1;
          2'b10: deq_sel = 2;
          default: deq_sel = 3;
        endcase
        full_ctrl_cov.sample(occ_pre[0], occ_pre[1], enq_sel, deq_sel,
                             bypass_evt[0], bypass_evt[1]);
        full_ptr_cov.sample(wptr_pos_pre[0], rptr_pos_pre[0],
                            wptr_pos_pre[1], rptr_pos_pre[1],
                            enq_sel, deq_sel);
      end
    end
  end

  covergroup global_cg with function sample
    (bit enq, bit deq, int enq_id, int deq_id, bit bypass);
    option.per_instance = 1;
    op_cp: coverpoint {enq, deq}
      { bins idle = {2'b00};
        bins enq_only = {2'b10};
        bins deq_only = {2'b01};
        bins enq_deq = {2'b11};
      }
    enq_id_cp: coverpoint enq_id iff (enq)
      { bins ids[] = {[0:FIFOS-1]}; }
    deq_id_cp: coverpoint deq_id iff (deq)
      { bins ids[] = {[0:FIFOS-1]}; }
    same_cp: coverpoint (enq_id == deq_id) iff (enq && deq)
      { bins same = {1'b1}; bins diff = {1'b0}; }
    bypass_cp: coverpoint bypass { bins no = {1'b0}; bins yes = {1'b1}; }
  endgroup

  global_cg global_cov;

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

  initial begin
    global_cov = new();
    for (int i = 0; i < FIFOS; i++)
      fifo_cov[i] = new(i);
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
      for (int i = 0; i < FIFOS; i++) begin
        occ_pre[i] = exp_q[i].size();
        wptr_wrap_pre[i] = ((enq_cnt[i] % ELS) == (ELS-1));
        rptr_wrap_pre[i] = ((deq_cnt[i] % ELS) == (ELS-1));
        wptr_pos_pre[i] = enq_cnt[i] % ELS;
        rptr_pos_pre[i] = deq_cnt[i] % ELS;
        enq_evt[i] = do_enq_now && ($unsigned(enq_id_i) == i);
        deq_evt[i] = yumi_i[i];
        bypass_evt[i] = enq_evt[i]
          && ((occ_pre[i] == 0) || ((occ_pre[i] == 1) && deq_evt[i]));
      end

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

      global_cov.sample(do_enq_now, do_deq_now, enq_id_i, deq_id_i, |bypass_evt);
      for (int i = 0; i < FIFOS; i++) begin
        occ_post[i] = exp_q[i].size();
        occ_delta[i] = $signed(occ_post[i]) - $signed(occ_pre[i]);
        fifo_cov[i].sample(occ_pre[i], occ_post[i], occ_delta[i],
                           enq_evt[i], deq_evt[i], bypass_evt[i],
                           wptr_wrap_pre[i], rptr_wrap_pre[i],
                           wptr_pos_pre[i], rptr_pos_pre[i]);
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
      if (fifo_cov[i].occ_pre_cp.get_coverage() < 100.0) begin
        $error("FIFO %0d occ_pre coverage incomplete (%0.2f%%)", i,
               fifo_cov[i].occ_pre_cp.get_coverage());
        $fatal(1);
      end
      if (fifo_cov[i].occ_post_cp.get_coverage() < 100.0) begin
        $error("FIFO %0d occ_post coverage incomplete (%0.2f%%)", i,
               fifo_cov[i].occ_post_cp.get_coverage());
        $fatal(1);
      end
      if (fifo_cov[i].occ_delta_x.get_coverage() < 100.0) begin
        $error("FIFO %0d occ_delta coverage incomplete (%0.2f%%)", i,
               fifo_cov[i].occ_delta_x.get_coverage());
        $fatal(1);
      end
      if (fifo_cov[i].occ_op_x.get_coverage() < 100.0) begin
        $error("FIFO %0d occ_op coverage incomplete (%0.2f%%)", i,
               fifo_cov[i].occ_op_x.get_coverage());
        $fatal(1);
      end
      if (wrap_cov_lp) begin
        if (fifo_cov[i].occ_rptr_x.get_coverage() < 100.0) begin
          $error("FIFO %0d occ_rptr coverage incomplete (%0.2f%%)", i,
                 fifo_cov[i].occ_rptr_x.get_coverage());
          $fatal(1);
        end
        if (fifo_cov[i].occ_wptr_x.get_coverage() < 100.0) begin
          $error("FIFO %0d occ_wptr coverage incomplete (%0.2f%%)", i,
                 fifo_cov[i].occ_wptr_x.get_coverage());
          $fatal(1);
        end
      end
      if (wrap_cov_lp) begin
        if (fifo_cov[i].wptr_wrap_cp.get_coverage() < 100.0) begin
          $error("FIFO %0d wptr_wrap coverage incomplete (%0.2f%%)", i,
                 fifo_cov[i].wptr_wrap_cp.get_coverage());
          $fatal(1);
        end
        if (fifo_cov[i].rptr_wrap_cp.get_coverage() < 100.0) begin
          $error("FIFO %0d rptr_wrap coverage incomplete (%0.2f%%)", i,
                 fifo_cov[i].rptr_wrap_cp.get_coverage());
          $fatal(1);
        end
      end
    end
    if (global_cov.op_cp.get_coverage() < 100.0) begin
      $error("Global op coverage incomplete (%0.2f%%)",
             global_cov.op_cp.get_coverage());
      $fatal(1);
    end
    if (global_cov.bypass_cp.get_coverage() < 100.0) begin
      $error("Global bypass coverage incomplete (%0.2f%%)",
             global_cov.bypass_cp.get_coverage());
      $fatal(1);
    end
    if (global_cov.enq_id_cp.get_coverage() < 100.0) begin
      $error("Global enq_id coverage incomplete (%0.2f%%)",
             global_cov.enq_id_cp.get_coverage());
      $fatal(1);
    end
    if (global_cov.deq_id_cp.get_coverage() < 100.0) begin
      $error("Global deq_id coverage incomplete (%0.2f%%)",
             global_cov.deq_id_cp.get_coverage());
      $fatal(1);
    end
    if ((FIFOS > 1) && (global_cov.same_cp.get_coverage() < 100.0)) begin
      $error("Global enq/deq same/diff coverage incomplete (%0.2f%%)",
             global_cov.same_cp.get_coverage());
      $fatal(1);
    end
    if (full_ctrl_cov_lp) begin
      if (full_ctrl_cov_gen.full_ctrl_cov.full_ctrl_x.get_coverage() < 100.0) begin
        $error("Full control cross coverage incomplete (%0.2f%%)",
               full_ctrl_cov_gen.full_ctrl_cov.full_ctrl_x.get_coverage());
        $fatal(1);
      end
      if (full_ctrl_cov_gen.full_ptr_cov.full_ptr_x.get_coverage() < 100.0) begin
        $error("Full pointer/control cross coverage incomplete (%0.2f%%)",
               full_ctrl_cov_gen.full_ptr_cov.full_ptr_x.get_coverage());
        $fatal(1);
      end
    end

    $display("PASS: all FIFOs drained; counts match; data ordering verified.");
    $finish;
  end

endmodule

// Check the arbiter through its public outputs using a cyclic priority search.
// Cover inputs_p=1..24 with ordinary, hold-on-single-request, and reset-on-
// single-request policies. For every pointer position and lone requester,
// check grant gating, a stalled request, and an accepted request, then probe
// the resulting priority with all requesters active. Include idle cycles,
// 1,024 deterministic random cycles per instance, and a mid-run reset.
// yumi_i is asserted only when grants are enabled and a request is present.
`include "bsg_defines.sv"

module round_robin_hold_checker
  #(parameter inputs_p = 4
    , parameter hold_on_sr_p = 1'b0
    , parameter reset_on_sr_p = 1'b0
    , localparam lg_inputs_lp = `BSG_SAFE_CLOG2(inputs_p)
    )
  (input clk_i
   , output bit done_o = 1'b0
   , output int errors_o = 0
   , output int cycles_o = 0
   );

  bit reset = 1'b1, grants_en = 1'b0, yumi = 1'b0;
  bit [inputs_p-1:0] reqs = '0;
  logic [inputs_p-1:0] grants, sel_one_hot;
  logic [lg_inputs_lp-1:0] tag;
  logic v;
  int last = 0;

  bsg_round_robin_arb #(.inputs_p(inputs_p)
                      ,.hold_on_sr_p(hold_on_sr_p)
                      ,.reset_on_sr_p(reset_on_sr_p)) dut
    (.clk_i(clk_i), .reset_i(reset), .grants_en_i(grants_en), .reqs_i(reqs)
     ,.grants_o(grants), .sel_one_hot_o(sel_one_hot), .v_o(v), .tag_o(tag)
     ,.yumi_i(yumi));

  task automatic step(input bit [inputs_p-1:0] requests
                      , input bit enable, accept, do_reset = 1'b0);
    bit [inputs_p-1:0] expected_sel;
    int winner, index;

    @(negedge clk_i);
    reqs = requests;
    grants_en = enable;
    yumi = accept;
    reset = do_reset;
    expected_sel = '0;
    winner = -1;
    for (int offset = 1; offset <= inputs_p; offset++) begin
      index = (last + offset) % inputs_p;
      if (requests[index] && winner == -1) begin
        winner = index;
        expected_sel[index] = 1'b1;
      end
    end

    #1;
    if (sel_one_hot !== expected_sel
        || grants !== (expected_sel & {inputs_p{enable}})
        || v !== (|requests)
        || ((|requests) && tag !== lg_inputs_lp'(winner))) begin
      errors_o++;
      if (errors_o <= 3)
        $display("[BSG_ERROR] %m: last=%0d reqs=%b enable=%b accept=%b sel=%b grants=%b v=%b tag=%0d expected_sel=%b expected_tag=%0d"
                 , last, requests, enable, accept, sel_one_hot, grants, v, tag
                 , expected_sel, winner);
    end

    @(posedge clk_i);
    #1;
    if (do_reset || inputs_p == 1)
      last = 0;
    else if (reset_on_sr_p && $onehot(requests))
      last = inputs_p - 2;
    else if (accept && !(hold_on_sr_p && $onehot(requests)
                        && winner == (last + 1) % inputs_p))
      last = winner;
    cycles_o++;
  endtask

  // With multiple requests, accepting the winner advances every policy.
  // Establish pointer positions using transactions rather than DUT internals.
  task automatic set_pointer(input int position);
    for (int i = 0; i < inputs_p; i++)
      if (last != position)
        step('1, 1'b1, 1'b1);
  endtask

  initial begin
    bit [inputs_p-1:0] requests;
    bit [31:0] random_state;
    random_state = 32'h239da530 + inputs_p;
    step('0, 1'b0, 1'b0, 1'b1);

    for (int position = 0; position < inputs_p; position++) begin
      set_pointer(position);
      step('0, 1'b1, 1'b0);
      step('1, 1'b1, 1'b0);
      for (int requester = 0; requester < inputs_p; requester++) begin
        requests = '0;
        requests[requester] = 1'b1;
        for (int control = 0; control < 3; control++) begin
          set_pointer(position);
          step(requests, control != 0, control == 2);
          step('1, 1'b1, 1'b0);
        end
      end
    end

    for (int cycle = 0; cycle < 1024; cycle++) begin
      random_state ^= random_state << 13;
      random_state ^= random_state >> 17;
      random_state ^= random_state << 5;
      requests = inputs_p'(random_state);
      step(requests, random_state[31]
           , random_state[31] && random_state[30] && (|requests), cycle == 511);
    end
    step('1, 1'b1, 1'b0);
    if (errors_o != 0)
      $display("[BSG_ERROR] inputs=%0d hold=%0d reset=%0d: %0d mismatches"
               , inputs_p, hold_on_sr_p, reset_on_sr_p, errors_o);
    done_o = 1'b1;
  end
endmodule

module test_bsg;
  localparam max_inputs_lp = 24;
  localparam cases_lp = 3 * max_inputs_lp;
  wire clk;
  wire [cases_lp-1:0] done;
  wire [31:0] errors [cases_lp], cycles [cases_lp];

  bsg_nonsynth_clock_gen #(.cycle_time_p(20)) clock_gen (.o(clk));

  for (genvar n = 1; n <= max_inputs_lp; n++) begin: widths
    for (genvar policy = 0; policy < 3; policy++) begin: policies
      localparam case_lp = 3 * (n - 1) + policy;
      round_robin_hold_checker #(.inputs_p(n), .hold_on_sr_p(policy == 1)
                                ,.reset_on_sr_p(policy == 2)) checker_inst
        (.clk_i(clk), .done_o(done[case_lp]), .errors_o(errors[case_lp])
         ,.cycles_o(cycles[case_lp]));
    end
  end

  initial begin
    int total_errors, total_cycles;
    wait (&done);
    total_errors = 0;
    total_cycles = 0;
    for (int i = 0; i < cases_lp; i++) begin
      total_errors += errors[i];
      total_cycles += cycles[i];
    end
    if (total_errors != 0)
      $fatal(1, "[BSG_ERROR] bsg_round_robin_hold_arb: %0d mismatches", total_errors);
    $display("[BSG_FINISH] bsg_round_robin_hold_arb: %0d cases, %0d cycles; inputs 1..24, ordinary/hold/reset policies passed"
             , cases_lp, total_cycles);
    $finish;
  end

  initial begin
    #10000000;
    $fatal(1, "[BSG_ERROR] bsg_round_robin_hold_arb timeout");
  end
endmodule

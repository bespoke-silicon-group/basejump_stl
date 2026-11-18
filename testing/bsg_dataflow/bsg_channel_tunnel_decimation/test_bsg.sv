`include "bsg_defines.sv"

// Two bsg_channel_tunnel instances wired back to back, with
// lg_credit_decimation_p always given explicitly.
//
// 1. Traffic. Both directions, two channels, at credit counts from 1 to 32,
//    including the smallest count each decimation allows. Every word is
//    checked whenever it is valid, and every stream must complete.
// 2. Sizing. With one channel sending every cycle and nothing stalled,
//    remote_credits_p = D + 2 must deliver a word every cycle and D + 1 must
//    not, where D = 2**lg_credit_decimation_p and 2 is the round trip of two
//    directly wired tunnels. This is the rule in the bsg_channel_tunnel header.

module test_bsg;

  localparam cases_lp = 10;
  localparam int credits_lp    [cases_lp] = '{1, 2, 2, 3, 5, 7, 8, 15, 16, 32};
  localparam int decimation_lp [cases_lp] = '{0, 0, 1, 1, 2, 2, 3,  3,  4,  4};

  localparam rate_cases_lp  = 4;     // D = 1, 2, 4, 8
  localparam rate_window_lp = 1000;  // cycles

  bit clk;
  bit reset = 1;
  logic [cases_lp-1:0] done;
  logic [rate_cases_lp-1:0] rate_done;
  int unsigned at_bound_lo    [rate_cases_lp];
  int unsigned below_bound_lo [rate_cases_lp];

  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  for (genvar i = 0; i < cases_lp; i++) begin: cases
    test_tunnel_loopback
      #(.remote_credits_p(credits_lp[i])
        ,.lg_credit_decimation_p(decimation_lp[i])
        ,.stall_interval_p(`STALL_INTERVAL_P)
        ) loopback
      (.clk_i(clk), .reset_i(reset), .done_o(done[i]));
  end

  for (genvar d = 0; d < rate_cases_lp; d++) begin: rate
    logic at_bound_done, below_bound_done;
    test_tunnel_rate
      #(.remote_credits_p((1 << d) + 2), .lg_credit_decimation_p(d), .window_p(rate_window_lp)) at_bound
      (.clk_i(clk), .reset_i(reset), .delivered_o(at_bound_lo[d]), .done_o(at_bound_done));
    test_tunnel_rate
      #(.remote_credits_p((1 << d) + 1), .lg_credit_decimation_p(d), .window_p(rate_window_lp)) below_bound
      (.clk_i(clk), .reset_i(reset), .delivered_o(below_bound_lo[d]), .done_o(below_bound_done));
    assign rate_done[d] = at_bound_done & below_bound_done;
  end

  initial begin
    repeat (4) @(posedge clk);
    #1 reset = 0;
    wait (&done && &rate_done);
    for (int d = 0; d < rate_cases_lp; d++) begin
      if (at_bound_lo[d] != rate_window_lp)
        $fatal(1, "[BSG_ERROR] D=%0d remote_credits_p=%0d delivered %0d words in %0d cycles",
               1 << d, (1 << d) + 2, at_bound_lo[d], rate_window_lp);
      if (below_bound_lo[d] >= rate_window_lp)
        $fatal(1, "[BSG_ERROR] D=%0d remote_credits_p=%0d was expected to throttle",
               1 << d, (1 << d) + 1);
    end
    repeat (4) @(posedge clk);
    #1;
    $display("[BSG_FINISH] %0d credit/decimation settings carried traffic; sizing rule held for D=1,2,4,8; stall interval %0d",
             cases_lp, `STALL_INTERVAL_P);
    $finish;
  end

  initial begin
    #2000000;
    $fatal(1, "[BSG_ERROR] timeout");
  end

endmodule

// Continuous traffic both ways on two channels. The shared link and each
// consumer move only on their own phase of the stall interval.
module test_tunnel_loopback
  #(parameter remote_credits_p = 8
    , parameter lg_credit_decimation_p = 3
    , parameter stall_interval_p = 1
    )
  (input clk_i, input reset_i, output done_o);

  localparam width_lp = 16;
  localparam num_in_lp = 2;
  localparam tagged_width_lp = $clog2(num_in_lp+1) + width_lp;
  localparam words_lp = 64;

  int unsigned cycle_r;
  logic [1:0][tagged_width_lp-1:0] multi_data;
  logic [1:0] multi_v, multi_yumi;
  logic [1:0][num_in_lp-1:0][width_lp-1:0] data_li, data_lo;
  logic [1:0][num_in_lp-1:0] v_li, yumi_lo, v_lo, yumi_li, stream_done;

  wire link_enable = (cycle_r % stall_interval_p == 0);

  always @(posedge clk_i)
    cycle_r <= reset_i ? 0 : cycle_r + 1;

  // multi_*[s] is the link driven by side s
  for (genvar s = 0; s < 2; s++) begin: side
    bsg_channel_tunnel
      #(.width_p(width_lp)
        ,.num_in_p(num_in_lp)
        ,.remote_credits_p(remote_credits_p)
        ,.lg_credit_decimation_p(lg_credit_decimation_p)
        ) tunnel
      (.clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.multi_data_i(multi_data[1-s])
       ,.multi_v_i(multi_v[1-s] & link_enable)
       ,.multi_yumi_o(multi_yumi[1-s])
       ,.multi_data_o(multi_data[s])
       ,.multi_v_o(multi_v[s])
       ,.multi_yumi_i(multi_yumi[s])
       ,.data_i(data_li[s])
       ,.v_i(v_li[s])
       ,.yumi_o(yumi_lo[s])
       ,.data_o(data_lo[s])
       ,.v_o(v_lo[s])
       ,.yumi_i(yumi_li[s])
       );

    for (genvar c = 0; c < num_in_lp; c++) begin: channel
      int unsigned sent_r, received_r;

      assign data_li[s][c] = {4'(s), 4'(c), sent_r[7:0]};
      assign v_li[s][c] = ~reset_i && (sent_r < words_lp);
      assign yumi_li[s][c] = v_lo[s][c] && ((cycle_r + c + 1) % stall_interval_p == 0);
      assign stream_done[s][c] = (received_r == words_lp);

      always @(posedge clk_i) begin
        if (reset_i) begin
          sent_r <= 0;
          received_r <= 0;
        end
        else begin
          if (yumi_lo[s][c])
            sent_r <= sent_r + 1;
          // what arrives at side s was sent by side 1-s
          if (v_lo[s][c]) begin
            if (received_r >= words_lp || data_lo[s][c] !== {4'(1-s), 4'(c), received_r[7:0]})
              $fatal(1, "[BSG_ERROR] credits=%0d decimation=%0d side=%0d channel=%0d word=%0d expected=%h received=%h",
                     remote_credits_p, lg_credit_decimation_p, s, c, received_r,
                     {4'(1-s), 4'(c), received_r[7:0]}, data_lo[s][c]);
            if (yumi_li[s][c])
              received_r <= received_r + 1;
          end
        end
      end
    end
  end

  assign done_o = &stream_done;

endmodule

// One channel, one direction, a word offered every cycle and taken at once.
// Counts the words delivered in window_p cycles after a warm-up.
module test_tunnel_rate
  #(parameter remote_credits_p = 3
    , parameter lg_credit_decimation_p = 0
    , parameter window_p = 1000
    )
  (input clk_i, input reset_i, output int unsigned delivered_o, output logic done_o);

  localparam width_lp = 16;
  localparam tagged_width_lp = 1 + width_lp;
  localparam warmup_lp = 200;

  int unsigned cycle_r;
  logic [1:0][tagged_width_lp-1:0] multi_data;
  logic [1:0] multi_v, multi_yumi;
  logic [1:0][0:0][width_lp-1:0] data_li, data_lo;
  logic [1:0][0:0] v_li, yumi_lo, v_lo, yumi_li;

  for (genvar s = 0; s < 2; s++) begin: side
    bsg_channel_tunnel
      #(.width_p(width_lp)
        ,.num_in_p(1)
        ,.remote_credits_p(remote_credits_p)
        ,.lg_credit_decimation_p(lg_credit_decimation_p)
        ) tunnel
      (.clk_i(clk_i)
       ,.reset_i(reset_i)
       ,.multi_data_i(multi_data[1-s])
       ,.multi_v_i(multi_v[1-s])
       ,.multi_yumi_o(multi_yumi[1-s])
       ,.multi_data_o(multi_data[s])
       ,.multi_v_o(multi_v[s])
       ,.multi_yumi_i(multi_yumi[s])
       ,.data_i(data_li[s])
       ,.v_i(v_li[s])
       ,.yumi_o(yumi_lo[s])
       ,.data_o(data_lo[s])
       ,.v_o(v_lo[s])
       ,.yumi_i(yumi_li[s])
       );
  end

  // side 0 sends; side 1 only returns credits
  assign v_li[0] = ~reset_i;
  assign data_li[0] = 16'h5a5a;
  assign v_li[1] = 1'b0;
  assign data_li[1] = '0;
  assign yumi_li[0] = v_lo[0];
  assign yumi_li[1] = v_lo[1];

  always @(posedge clk_i) begin
    if (reset_i) begin
      cycle_r <= 0;
      delivered_o <= 0;
    end
    else begin
      cycle_r <= cycle_r + 1;
      if (cycle_r >= warmup_lp && cycle_r < warmup_lp + window_p && yumi_li[1][0])
        delivered_o <= delivered_o + 1;
    end
  end

  assign done_o = (cycle_r > warmup_lp + window_p);

endmodule

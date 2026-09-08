`include "bsg_defines.sv"

// Test reset, hold, increment, clear, and simultaneous clear/increment.
// Maxima 0..8 cover singleton and power-of-two boundaries. Wide maxima check
// that sizing does not overflow max_val_p+1 or truncate the highest count bit.
// Check both macros explicitly: only BSG_SAFE_WIDTH maps maximum zero to one.
module counter_test
  #(parameter max_val_p = 0
    , parameter expected_width_p = 1
    , parameter init_val_p = (max_val_p == 0) ? 0 : max_val_p-1
    )
  (input clk_i
   , output bit done_o
   );

  bit reset, clear, up;
  logic [expected_width_p-1:0] count;

  bsg_counter_clear_up #(.max_val_p(max_val_p), .init_val_p(init_val_p)) dut
    (.clk_i(clk_i), .reset_i(reset), .clear_i(clear), .up_i(up), .count_o(count));

  task automatic step(input bit reset_v, clear_v, up_v,
                      input logic [expected_width_p-1:0] expected);
    @(negedge clk_i);
    reset = reset_v;
    clear = clear_v;
    up = up_v;
    @(posedge clk_i);
    #1;
    if (count !== expected)
      $fatal(1, "max=%h reset/clear/up=%b%b%b expected=%h actual=%h",
             max_val_p, reset_v, clear_v, up_v, expected, count);
    reset = 0;
    clear = 0;
    up = 0;
  endtask

  initial begin
    if (`BSG_SAFE_WIDTH(max_val_p) != expected_width_p)
      $fatal(1, "BSG_SAFE_WIDTH mismatch for max=%h", max_val_p);
    if (`BSG_WIDTH(max_val_p) != ((max_val_p == 0) ? 0 : expected_width_p))
      $fatal(1, "BSG_WIDTH semantics changed for max=%h", max_val_p);
    if ($bits(dut.count_o) != expected_width_p)
      $fatal(1, "max=%h expected width=%0d actual=%0d",
             max_val_p, expected_width_p, $bits(dut.count_o));
    step(1, 0, 0, expected_width_p'(init_val_p));
    step(0, 0, 0, expected_width_p'(init_val_p));
    if (max_val_p != 0) begin
      step(0, 0, 1, expected_width_p'(max_val_p));
      step(0, 0, 0, expected_width_p'(max_val_p));
    end
    step(0, 1, 0, '0);
    if (max_val_p != 0) begin
      step(0, 1, 1, expected_width_p'(1));
      step(0, 0, 0, expected_width_p'(1));
    end
    step(1, 1, 0, expected_width_p'(init_val_p));
    step(0, 1, 0, '0);
    done_o = 1;
  end
endmodule

module test_bsg;
  wire clk;
  wire [12:0] done;
  bsg_nonsynth_clock_gen #(.cycle_time_p(`CYCLE_TIME_P)) clock_gen (.o(clk));

  for (genvar i = 0; i <= 8; i++) begin: small_max
    localparam width_lp = (i < 2) ? 1 : (i < 4) ? 2 : (i < 8) ? 3 : 4;
    counter_test #(.max_val_p(i), .expected_width_p(width_lp)) t
      (.clk_i(clk), .done_o(done[i]));
  end
  counter_test #(.max_val_p(32'h7fffffff), .expected_width_p(31)) signed_boundary
    (.clk_i(clk), .done_o(done[9]));
  counter_test #(.max_val_p(32'h80000000), .expected_width_p(32)) high_bit
    (.clk_i(clk), .done_o(done[10]));
  counter_test #(.max_val_p(32'hffffffff), .expected_width_p(32)) full32
    (.clk_i(clk), .done_o(done[11]));
  counter_test #(.max_val_p(64'hffffffffffffffff), .expected_width_p(64)) full64
    (.clk_i(clk), .done_o(done[12]));

  initial begin
    wait (&done);
    $display("PASS: counter widths and behavior for 13 parameter cases");
    $finish;
  end
  initial begin
    #(`CYCLE_TIME_P*100);
    $fatal(1, "counter test timed out");
  end
endmodule

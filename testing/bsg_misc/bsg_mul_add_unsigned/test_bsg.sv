// Michael Bedford Taylor & OpenAI Codex (AI-generated).
`include "bsg_defines.sv"

// Check default port sizing against the original maximum-result calculation,
// using 256-bit arithmetic so the oracle cannot suffer the reported overflow.
// Widths cover one-bit/unequal operands, both sides of C=max(A,B), narrow and
// wide addends, and the 16/32/64-bit boundaries. Stream zero, maximum, high-bit,
// and random operands through each pipeline depth, checking latency and values.
// Explicit narrow/wide outputs also check truncation, extension, and positional
// parameter compatibility. Use the same test for generic and FPGA RTL.
module mul_add_test
  #(parameter width_a_p = 1
    , parameter width_b_p = 1
    , parameter width_c_p = width_a_p + width_b_p
    , parameter pipeline_p = `PIPELINE_P
    )
  (input clk_i
   , output bit done_o
   );

  localparam reference_width_lp = 256;
  localparam [reference_width_lp-1:0] max_result_lp =
      ((256'd1 << width_a_p) - 1) * ((256'd1 << width_b_p) - 1)
      + ((256'd1 << width_c_p) - 1);
  localparam expected_width_lp = $clog2(max_result_lp + 1);
  localparam narrow_width_lp = expected_width_lp - 1;
  localparam wide_width_lp = expected_width_lp + 1;
  localparam samples_lp = 40;
  localparam cycles_lp = samples_lp + ((pipeline_p > 0) ? pipeline_p-1 : 0);

  logic [width_a_p-1:0] a;
  logic [width_b_p-1:0] b;
  logic [width_c_p-1:0] c;
  wire [expected_width_lp-1:0] result;
  wire [narrow_width_lp-1:0] narrow_result;
  wire [wide_width_lp-1:0] wide_result;
  logic [reference_width_lp-1:0] expected [cycles_lp];

  bsg_mul_add_unsigned #(.width_a_p(width_a_p), .width_b_p(width_b_p)
                        ,.width_c_p(width_c_p), .pipeline_p(pipeline_p)) dut
    (.clk_i(clk_i), .a_i(a), .b_i(b), .c_i(c), .o(result));

  bsg_mul_add_unsigned #(width_a_p, width_b_p, width_c_p, narrow_width_lp, pipeline_p) narrow
    (.clk_i(clk_i), .a_i(a), .b_i(b), .c_i(c), .o(narrow_result));

  bsg_mul_add_unsigned #(width_a_p, width_b_p, width_c_p, wide_width_lp, pipeline_p) wide
    (.clk_i(clk_i), .a_i(a), .b_i(b), .c_i(c), .o(wide_result));

  task automatic check(input logic [reference_width_lp-1:0] expected_v);
    if (reference_width_lp'(result) !== expected_v)
      $fatal(1, "%m: A/B/C=%0d/%0d/%0d pipeline=%0d expected=%h actual=%h",
             width_a_p, width_b_p, width_c_p, pipeline_p, expected_v, result);
    if (narrow_result !== narrow_width_lp'(expected_v))
      $fatal(1, "%m: explicit narrow output mismatch");
    if (wide_result !== wide_width_lp'(expected_v))
      $fatal(1, "%m: explicit wide output mismatch");
  endtask

  initial begin
    if ((width_a_p + width_b_p >= reference_width_lp)
        || (width_c_p >= reference_width_lp))
      $fatal(1, "%m: test oracle is too narrow");
    if ($bits(dut.o) != expected_width_lp)
      $fatal(1, "%m: A/B/C=%0d/%0d/%0d expected width=%0d actual=%0d",
             width_a_p, width_b_p, width_c_p, expected_width_lp, $bits(dut.o));
    a = '0;
    b = '0;
    c = '0;
    for (int cycle = 0; cycle < cycles_lp; cycle++) begin
      @(negedge clk_i);
      case (cycle)
        0: begin a = '0; b = '0; c = '0; end
        1: begin a = '1; b = '1; c = '1; end
        2: begin a = 1; b = 1; c = '0; end
        3: begin a = '0; b = '1; c = '1; end
        4: begin a = '1; b = 1; c = 1; end
        5: begin a = '1; b = '1; c = '0; end
        6: begin
          a = '0; a[width_a_p-1] = 1'b1;
          b = '0; b[width_b_p-1] = 1'b1;
          c = '0;
        end
        7: begin
          a = '0; b = '0;
          c = '0; c[width_c_p-1] = 1'b1;
        end
        default: begin
          // Randomize every bit, including those above the 32-bit boundary.
          for (int i = 0; i < width_a_p; i++) a[i] = 1'($urandom);
          for (int i = 0; i < width_b_p; i++) b[i] = 1'($urandom);
          for (int i = 0; i < width_c_p; i++) c[i] = 1'($urandom);
        end
      endcase
      expected[cycle] = reference_width_lp'(a) * reference_width_lp'(b)
                        + reference_width_lp'(c);
      if (pipeline_p == 0) begin
        #1;
        check(expected[cycle]);
      end
      else begin
        @(posedge clk_i);
        #1;
        if (cycle >= pipeline_p-1)
          check(expected[cycle-pipeline_p+1]);
      end
    end
    done_o = 1;
  end
endmodule

module test_bsg;
  wire clk;
  wire [19:0] done;
  bsg_nonsynth_clock_gen #(.cycle_time_p(10)) clock_gen (.o(clk));

  mul_add_test #( 1,  1,   1) t00 (.clk_i(clk), .done_o(done[ 0]));
  mul_add_test #( 1,  1,   2) t01 (.clk_i(clk), .done_o(done[ 1]));
  mul_add_test #( 1,  8,   1) t02 (.clk_i(clk), .done_o(done[ 2]));
  mul_add_test #( 8,  1,   1) t03 (.clk_i(clk), .done_o(done[ 3]));
  mul_add_test #( 4,  4,   1) t04 (.clk_i(clk), .done_o(done[ 4]));
  mul_add_test #( 4,  4,   4) t05 (.clk_i(clk), .done_o(done[ 5]));
  mul_add_test #( 4,  4,   5) t06 (.clk_i(clk), .done_o(done[ 6]));
  mul_add_test #( 2,  8,   8) t07 (.clk_i(clk), .done_o(done[ 7]));
  mul_add_test #( 2,  8,   9) t08 (.clk_i(clk), .done_o(done[ 8]));
  mul_add_test #( 8,  8,  16) t09 (.clk_i(clk), .done_o(done[ 9]));
  mul_add_test #(15, 16,  31) t10 (.clk_i(clk), .done_o(done[10]));
  mul_add_test #(16, 16,  32) t11 (.clk_i(clk), .done_o(done[11]));
  mul_add_test #(31, 32,  63) t12 (.clk_i(clk), .done_o(done[12]));
  mul_add_test #(32, 32,  64) t13 (.clk_i(clk), .done_o(done[13]));
  mul_add_test #(64, 64, 128) t14 (.clk_i(clk), .done_o(done[14]));
  mul_add_test #(64, 64,   1) t15 (.clk_i(clk), .done_o(done[15]));
  mul_add_test #(16, 16,  64) t16 (.clk_i(clk), .done_o(done[16]));
  mul_add_test #( 1, 64,  64) t17 (.clk_i(clk), .done_o(done[17]));
  mul_add_test #(64,  1,  65) t18 (.clk_i(clk), .done_o(done[18]));
  mul_add_test #(64,  1,   1) t19 (.clk_i(clk), .done_o(done[19]));

  initial begin
    wait (&done);
    $display("PASS: mul_add_unsigned 20 width cases, pipeline=%0d", `PIPELINE_P);
    $finish;
  end
  initial begin
    #10000;
    $fatal(1, "mul_add_unsigned test timed out");
  end
endmodule

// Check maximal length for the automatic 32/60/64-bit masks with GF(2)
// polynomial arithmetic, avoiding billions of simulation cycles. For each
// width n, test x^(2^n-1) = 1 and x^((2^n-1)/q) != 1 for every distinct
// prime factor q of 2^n-1. Together these establish the full period.
// Also check 2,000 cycles of the RTL with reset, stalls, and a mid-run reset.
// Cover the default seed, a second 32-bit seed, and an explicit mask override
// preserving the old 32-bit sequence. Zero seeds are outside the period claim.
module lfsr_checker
  #(parameter width_p = 32
    , parameter [width_p-1:0] expected_mask_p = '0
    , parameter [width_p-1:0] init_val_p = 1
    , parameter [width_p-1:0] xor_mask_p = '0
    )
  (input clk_i
   , input reset_i
   , input yumi_i
   );

  logic [width_p-1:0] data, expected;

  bsg_lfsr #(.width_p(width_p), .init_val_p(init_val_p), .xor_mask_p(xor_mask_p)) dut
    (.clk(clk_i), .reset_i(reset_i), .yumi_i(yumi_i), .o(data));

  // Drive inputs on the falling edge and compare after the DUT's NBA update.
  always @(posedge clk_i) begin
    if (reset_i)
      expected = init_val_p;
    else if (yumi_i)
      expected = (expected >> 1) ^ (expected[0] ? expected_mask_p : '0);
    #1;
    if (data !== expected)
      $fatal(1, "[BSG_ERROR] %m: expected=%h received=%h", expected, data);
  end
endmodule

module test_bsg;
  wire clk;
  bit reset = 1'b1;
  bit yumi = 1'b0;

  bsg_nonsynth_clock_gen #(.cycle_time_p(20)) clock_gen (.o(clk));

  lfsr_checker #(.width_p(32), .expected_mask_p(32'ha3000000)) default32
    (.clk_i(clk), .reset_i(reset), .yumi_i(yumi));
  lfsr_checker #(.width_p(60), .expected_mask_p(60'hc00000000000000)) default60
    (.clk_i(clk), .reset_i(reset), .yumi_i(yumi));
  lfsr_checker #(.width_p(64), .expected_mask_p(64'hd800000000000000)) default64
    (.clk_i(clk), .reset_i(reset), .yumi_i(yumi));

  // The old mask has a particularly short 511-step cycle from this seed.
  lfsr_checker #(.width_p(32), .expected_mask_p(32'ha3000000)
                ,.init_val_p(32'h00865e5b)) alternate_seed
    (.clk_i(clk), .reset_i(reset), .yumi_i(yumi));
  lfsr_checker #(.width_p(32), .expected_mask_p(32'ha6000000)
                ,.xor_mask_p(32'ha6000000)) explicit_mask
    (.clk_i(clk), .reset_i(reset), .yumi_i(yumi));

  // Polynomials are bit vectors; multiplication and reduction use XOR.
  function automatic bit [127:0] mulmod
    (input bit [127:0] a_in, b, p, input int n);
    bit [127:0] result, a;
    result = '0;
    a = a_in;
    for (int i = 0; i < n; i++) begin
      if (b[i]) result ^= a;
      a <<= 1;
      if (a[n]) a ^= p;
    end
    return result;
  endfunction

  function automatic bit [127:0] xpow
    (input bit [63:0] exponent, input bit [127:0] p, input int n);
    bit [127:0] result, base;
    result = 128'd1;
    base = 128'd2;
    for (int i = 0; i < 64; i++) begin
      if (exponent[i]) result = mulmod(result, base, p, n);
      base = mulmod(base, base, p, n);
    end
    return result;
  endfunction

  // q=0 checks the full order; other q values are its distinct prime factors.
  task automatic check_order(input bit [63:0] mask, input int n, input bit [63:0] q);
    bit [127:0] polynomial, result;
    bit [63:0] order;
    polynomial = ({64'b0, mask} << 1) | 128'd1;
    order = (64'hffffffffffffffff >> (64-n));
    result = xpow((q == 0) ? order : order/q, polynomial, n);
    if ((q == 0) ? (result != 128'd1) : (result == 128'd1))
      $fatal(1, "[BSG_ERROR] width=%0d mask=%h is not maximal-length (q=%0d)", n, mask, q);
  endtask

  initial begin
    #1;
    check_order({32'b0, default32.dut.xor_mask}, 32, 0);
    check_order({32'b0, default32.dut.xor_mask}, 32, 3);
    check_order({32'b0, default32.dut.xor_mask}, 32, 5);
    check_order({32'b0, default32.dut.xor_mask}, 32, 17);
    check_order({32'b0, default32.dut.xor_mask}, 32, 257);
    check_order({32'b0, default32.dut.xor_mask}, 32, 65537);

    check_order({4'b0, default60.dut.xor_mask}, 60, 0);
    check_order({4'b0, default60.dut.xor_mask}, 60, 3);
    check_order({4'b0, default60.dut.xor_mask}, 60, 5);
    check_order({4'b0, default60.dut.xor_mask}, 60, 7);
    check_order({4'b0, default60.dut.xor_mask}, 60, 11);
    check_order({4'b0, default60.dut.xor_mask}, 60, 13);
    check_order({4'b0, default60.dut.xor_mask}, 60, 31);
    check_order({4'b0, default60.dut.xor_mask}, 60, 41);
    check_order({4'b0, default60.dut.xor_mask}, 60, 61);
    check_order({4'b0, default60.dut.xor_mask}, 60, 151);
    check_order({4'b0, default60.dut.xor_mask}, 60, 331);
    check_order({4'b0, default60.dut.xor_mask}, 60, 1321);

    check_order(default64.dut.xor_mask, 64, 0);
    check_order(default64.dut.xor_mask, 64, 3);
    check_order(default64.dut.xor_mask, 64, 5);
    check_order(default64.dut.xor_mask, 64, 17);
    check_order(default64.dut.xor_mask, 64, 257);
    check_order(default64.dut.xor_mask, 64, 641);
    check_order(default64.dut.xor_mask, 64, 65537);
    check_order(default64.dut.xor_mask, 64, 6700417);

    for (int cycle = 0; cycle < 2000; cycle++) begin
      @(negedge clk);
      reset = (cycle < 2) || (cycle == 997);
      yumi = (cycle % 5 != 0);
      @(posedge clk);
      #2;
    end
    $display("[BSG_FINISH] bsg_lfsr: maximal 32/60/64-bit masks; reset, stalls, seeds, and override passed");
    $finish;
  end

  initial begin
    #100000;
    $fatal(1, "[BSG_ERROR] bsg_lfsr timeout");
  end
endmodule

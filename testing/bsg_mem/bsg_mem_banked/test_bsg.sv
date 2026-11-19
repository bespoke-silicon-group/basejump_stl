`ifndef LATCH_P
`define LATCH_P 0
`endif

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  The bit-mask and byte-mask versions of bsg_mem_1rw_sync_banked, and
  bsg_mem_1r1w_sync_banked, are each checked against a reference memory
  without banking. Every entry is written first, then random reads and writes,
  with random write masks, run for cycles_p cycles. Every read is compared with
  the reference, and with latch_last_read_p, so is the output on every cycle
  after the first read.

  bsg_mem_1rw_sync_banked itself is not tested yet: it passes harden_p to
  bsg_mem_1rw_sync, which has no such parameter, so it does not build.

2. PARAMETERIZATION

  The geometries below cover width banks only; depth banks whose count is a
  power of two, where the low address bits pick the bank; depth banks whose
  count is not, where the high address bits pick the bank; and the smallest
  depth banks allowed, with two entries each. Widths are multiples of 8 so the
  byte-mask wrapper can use every geometry. The Makefile scans LATCH_P.

***************************************************************************/

module test_bsg
#(
  parameter latch_last_read_p = `LATCH_P,
  parameter cycles_p          = 10000,
  parameter cycle_time_p      = 20,
  parameter reset_cycles_lo_p = 1,
  parameter reset_cycles_hi_p = 5
);

  // els_p, width_p, num_width_bank_p, num_depth_bank_p
  localparam num_geoms_lp = 10;
  localparam int geoms_lp [num_geoms_lp][4] = '{
     '{  24, 32, 4, 1}  // width banks only
    ,'{  64, 32, 2, 4}  // low address bits pick the bank
    ,'{  24, 32, 2, 2}  // low address bits, banks of 12
    ,'{   8, 16, 1, 4}  // low address bits, banks of 2
    ,'{ 256, 64, 4, 8}  // low address bits, width and depth banks
    ,'{  96, 32, 1, 3}  // high address bits pick the bank
    ,'{  96, 64, 2, 6}  // high address bits, width and depth banks
    ,'{  40, 32, 2, 5}  // high address bits, banks of 8
    ,'{   6, 16, 1, 3}  // high address bits, banks of 2
    ,'{1536, 32, 1, 3}  // high address bits, banks of 512
  };

  // 0: 1rw bit mask, 1: 1rw byte mask, 2: 1r1w
  localparam num_kinds_lp = 3;
  localparam num_checks_lp = num_kinds_lp * num_geoms_lp;

  bit clk, reset;

  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk)
                          );

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk)
                           , .async_reset_o(reset)
                          );

  wire [num_checks_lp-1:0] done_lo;
  wire [31:0] checks_lo [num_checks_lp];
  wire [31:0] errors_lo [num_checks_lp];

  for (genvar k = 0; k < num_kinds_lp; k++) begin: kind
    for (genvar g = 0; g < num_geoms_lp; g++) begin: geom
      check_banked #(  .kind_p           (k)
                     , .els_p            (geoms_lp[g][0])
                     , .width_p          (geoms_lp[g][1])
                     , .num_width_bank_p (geoms_lp[g][2])
                     , .num_depth_bank_p (geoms_lp[g][3])
                     , .latch_last_read_p(latch_last_read_p)
                     , .cycles_p         (cycles_p)
                    )  check
                    (  .clk_i   (clk)
                     , .reset_i (reset)
                     , .done_o  (done_lo[k*num_geoms_lp+g])
                     , .checks_o(checks_lo[k*num_geoms_lp+g])
                     , .errors_o(errors_lo[k*num_geoms_lp+g])
                    );
    end
  end

  initial
  begin
    int checks, errors;
    $display("\n\n\n");
    $display("===========================================================");
    $display("testing the banked bsg_mem wrappers with ...");
    $display("LATCH_LAST_READ_P: %0d\n", latch_last_read_p);

    wait (&done_lo);
    checks = 0;
    errors = 0;
    for (int i = 0; i < num_checks_lp; i++) begin
      checks += checks_lo[i];
      errors += errors_lo[i];
    end
    if (errors == 0)
      $display("PASSED: %0d memories, %0d reads checked", num_checks_lp, checks);
    else
      $error("FAILED: %0d of %0d reads were wrong", errors, checks);
    $display("=======================================================\n");
    $finish;
  end

endmodule


// Drives one banked memory with random traffic and checks it against a
// reference memory without banking.
module check_banked
#(
  parameter kind_p = 0,
  parameter els_p = 64,
  parameter width_p = 32,
  parameter num_width_bank_p = 1,
  parameter num_depth_bank_p = 1,
  parameter latch_last_read_p = 0,
  parameter cycles_p = 10000,
  parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p),
  parameter mask_width_lp = width_p/8
)
(
  input clk_i,
  input reset_i,
  output logic done_o,
  output [31:0] checks_o,
  output [31:0] errors_o
);

  logic v_li = 1'b0, w_li = 1'b0, r_v_li = 1'b0;
  logic [addr_width_lp-1:0] addr_li = '0, r_addr_li = '0;
  logic [width_p-1:0] data_li = '0, w_mask_li = '0, data_lo;
  logic [mask_width_lp-1:0] write_mask_li = '0;

  if (kind_p == 0) begin: bit_mask
    bsg_mem_1rw_sync_mask_write_bit_banked #(  .width_p(width_p)
                                             , .els_p(els_p)
                                             , .latch_last_read_p(latch_last_read_p)
                                             , .num_width_bank_p(num_width_bank_p)
                                             , .num_depth_bank_p(num_depth_bank_p)
                                            )  DUT
                                            (  .clk_i(clk_i)
                                             , .reset_i(reset_i)
                                             , .v_i(v_li)
                                             , .w_i(w_li)
                                             , .addr_i(addr_li)
                                             , .data_i(data_li)
                                             , .w_mask_i(w_mask_li)
                                             , .data_o(data_lo)
                                            );
  end
  else if (kind_p == 1) begin: byte_mask
    bsg_mem_1rw_sync_mask_write_byte_banked #(  .data_width_p(width_p)
                                              , .els_p(els_p)
                                              , .latch_last_read_p(latch_last_read_p)
                                              , .num_width_bank_p(num_width_bank_p)
                                              , .num_depth_bank_p(num_depth_bank_p)
                                             )  DUT
                                             (  .clk_i(clk_i)
                                              , .reset_i(reset_i)
                                              , .v_i(v_li)
                                              , .w_i(w_li)
                                              , .addr_i(addr_li)
                                              , .data_i(data_li)
                                              , .write_mask_i(write_mask_li)
                                              , .data_o(data_lo)
                                             );
  end
  else begin: two_port
    bsg_mem_1r1w_sync_banked #(  .width_p(width_p)
                               , .els_p(els_p)
                               , .latch_last_read_p(latch_last_read_p)
                               , .num_width_bank_p(num_width_bank_p)
                               , .num_depth_bank_p(num_depth_bank_p)
                              )  DUT
                              (  .clk_i(clk_i)
                               , .reset_i(reset_i)
                               , .w_v_i(v_li & w_li)
                               , .w_addr_i(addr_li)
                               , .w_data_i(data_li)
                               , .r_v_i(r_v_li)
                               , .r_addr_i(r_addr_li)
                               , .r_data_o(data_lo)
                              );
  end

  // Reference memory
  logic [width_p-1:0] mem_r [els_p];
  logic [width_p-1:0] write_bits, expected_r;
  logic read_r = 1'b0, any_read_r = 1'b0;

  wire write = v_li & w_li;
  wire read = (kind_p == 2) ? r_v_li : (v_li & ~w_li);
  wire [addr_width_lp-1:0] read_addr = (kind_p == 2) ? r_addr_li : addr_li;

  always_comb
    for (int b = 0; b < width_p; b++)
      write_bits[b] = (kind_p == 0) ? w_mask_li[b]
                    : (kind_p == 1) ? write_mask_li[b/8]
                    : 1'b1;

  always @(posedge clk_i) begin
    read_r <= read;
    if (read) begin
      expected_r <= mem_r[read_addr];
      any_read_r <= 1'b1;
    end
    if (write)
      mem_r[addr_li] <= (mem_r[addr_li] & ~write_bits) | (data_li & write_bits);
  end

  int checks = 0, errors = 0;
  assign checks_o = checks;
  assign errors_o = errors;

  always @(negedge clk_i)
    if (read_r || (latch_last_read_p && any_read_r)) begin
      checks++;
      if (data_lo !== expected_r) begin
        if (errors < 3)
          $display("%m: read %h, expected %h", data_lo, expected_r);
        errors++;
      end
    end

  initial
  begin
    done_o = 1'b0;
    wait (reset_i);
    wait (!reset_i);

    // Write every entry, so that no read sees an unwritten one
    for (int a = 0; a < els_p; a++) begin
      @(negedge clk_i);
      {v_li, w_li} = 2'b11;
      addr_li = addr_width_lp'(a);
      data_li = width_p'({$urandom, $urandom});
      w_mask_li = '1;
      write_mask_li = '1;
    end

    for (int c = 0; c < cycles_p; c++) begin
      @(negedge clk_i);
      v_li = ($urandom_range(3) != 0);
      w_li = $urandom_range(1);
      addr_li = addr_width_lp'($urandom_range(els_p-1));
      data_li = width_p'({$urandom, $urandom});
      w_mask_li = width_p'({$urandom, $urandom});
      write_mask_li = mask_width_lp'($urandom);
      // The 1r1w port pair reads and writes the same entry only with read_write_same_addr_p
      r_v_li = (kind_p == 2) && ($urandom_range(3) != 0);
      r_addr_li = addr_width_lp'($urandom_range(els_p-1));
      if (v_li && w_li && r_v_li && r_addr_li == addr_li)
        r_addr_li = addr_width_lp'((r_addr_li + 1) % els_p);
    end

    @(negedge clk_i);
    {v_li, r_v_li} = '0;
    @(negedge clk_i);
    done_o = 1'b1;
  end

endmodule

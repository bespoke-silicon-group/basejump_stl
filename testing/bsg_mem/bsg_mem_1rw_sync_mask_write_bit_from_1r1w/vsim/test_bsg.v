`define WIDTH_P  3
`define ELS_P    4
`define SEED_P   10000
`define CYCLES_P 100000

// Test rationale:
// A randomly chosen "hazard" determines if the address repeats in the next cycle.
// A copy of the DUT RAM is maintained, and kept up to date.
// Following read requests to the DUT, the test verifies if the read data matches the local copy.

module test_bsg;
  localparam addr_width_p = `BSG_SAFE_CLOG2(`ELS_P);
 
  initial assert(`ELS_P < 128) else $warning("Data structures size is too large!");
  initial assert(`ELS_P < 256) else $error("Not safe! (Change me!)");
  initial $display("Running tests with WIDTH_P = %x, ELS_P = %x for %x cycles", `WIDTH_P, `ELS_P, `CYCLES_P); 

  wire clk, reset;

  bsg_nonsynth_clock_gen #(.cycle_time_p(5)) 
    clock_gen (.o(clk));

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    , .reset_cycles_lo_p(1)
    , .reset_cycles_hi_p(6)
    ) reset_gen (
    .clk_i(clk)
    , .async_reset_o(reset)
  );

  wire [`WIDTH_P*2+addr_width_p+1:0] random;

  bsg_nonsynth_random_gen 
    #(  .width_p($bits(random))
      , .seed_p (`SEED_P)
    ) random_gen
    ( .clk_i  (clk)
      , .reset_i(reset)
      , .yumi_i (1'b1)
      , .data_o (random)
    );

  int   counter_r;
  logic test_input_v_r, test_input_w_r;
  wire  test_input_v = counter_r > 40 ? random[0] : 1'b0;
  wire  test_input_w = random[1]; 
  wire  hazard       = random[2];
  logic [addr_width_p-1:0] test_input_addr_r;
  wire  [addr_width_p-1:0] test_input_addr = hazard ? test_input_addr_r : random[2+:addr_width_p]%`ELS_P;
  wire  [`WIDTH_P-1:0]     test_input_data;
  wire  [`WIDTH_P-1:0]     test_input_mask;
  wire  [`WIDTH_P-1:0]     data_o;

  assign {test_input_data, test_input_mask} = random[addr_width_p+:(`WIDTH_P*2)];

  logic [`WIDTH_P-1:0] ram [0:`ELS_P-1];
  //For cleaner testing iteration, uncomment this and initialize DUT RAM as well
  //generate
  //  integer ram_index;
  //  initial
  //    for (ram_index = 0; ram_index < `ELS_P; ram_index = ram_index + 1)
  //      ram[ram_index] = {(`WIDTH_P){1'b0}};
  //endgenerate

  bsg_mem_1rw_sync_mask_write_bit_from_1r1w
  #(.width_p(`WIDTH_P)
    , .els_p(`ELS_P)
    , .verbose_p(1)
  ) inst
  ( .clk_i(clk)
    , .reset_i(reset)
    , .v_i(test_input_v)
    , .addr_i(test_input_addr)
    , .w_i(test_input_w)
    , .data_i(test_input_data)
    , .w_mask_i(test_input_mask)
    , .data_o(data_o)
  );

  initial begin
    test_input_v_r = 0;
    counter_r = 0;
    $monitor("%06h |", counter_r
      , " %s | %s | addr:%06h | data:%06h | mask:%6h | "
      , test_input_v ? "v" : "", test_input_w ? "w" : "r"
      , test_input_addr, test_input_data, test_input_mask
      , "data_o: %b | expected: %b | %s"
      , data_o, ram[test_input_addr_r]
      , (test_input_v_r && !test_input_w_r) ? "Check" : "");
  end
  
  always @(posedge clk) begin
    if(counter_r > 30) begin
      test_input_addr_r <= test_input_addr;
      test_input_v_r    <= test_input_v;
      test_input_w_r    <= test_input_w;
      if(test_input_v && test_input_w)
        ram[test_input_addr] <= ram[test_input_addr] 
             & ~test_input_mask | test_input_data & test_input_mask;
     
    end
    counter_r <= counter_r + 1;
    if(test_input_v_r && !test_input_w_r) 
      assert(ram[test_input_addr_r] === data_o) 
        else $error ("Read data does not match harness' copy!");
    if(counter_r == `CYCLES_P) begin
      $display("Ending tests");
      $finish;
    end
    if(test_input_v & test_input_w)
      $display("Essentially writing %b to %06h"
        , ram[test_input_addr] & ~test_input_mask | test_input_data & test_input_mask
        , test_input_addr);
  end
endmodule

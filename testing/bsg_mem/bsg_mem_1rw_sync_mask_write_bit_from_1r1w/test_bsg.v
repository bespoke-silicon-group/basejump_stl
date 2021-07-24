`timescale 1ns / 1ps

`define width_p 6

module testbench();
  localparam width_p = 6;
  localparam els_p = 64;
  localparam addr_width_p = `BSG_SAFE_CLOG2(els_p);
  
  initial assert(els_p > 128) else $warning("Data structures size is too large!");
  initial assert(els_p > 256) else $error("Not safe! (Change me!)");
  
  wire clk, reset;

  bsg_nonsynth_clock_gen #(.cycle_time_p(5000)) 
    clock_gen (.o(clk));

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    , .reset_cycles_lo_p(1)
    , .reset_cycles_hi_p(6)
    ) reset_gen (
    .clk_i(clk)
    , .async_reset_o(reset)
  );

  bsg_nonsynth_random_gen 
    #(  .width_p(32)
      , .seed_p (10000)
    ) random_gen
    ( .clk_i  (clk)
      , .reset_i(reset)
      , .yumi_i (1'b1)
      , .data_o (random)
    );

  logic test_input_v_r, test_input_w_r;
  wire test_input_v = counter_r > 20? random[0] : 1'b0;
  wire test_input_w = random[1]; 
  wire hazard = random[2];
  wire [31:0] random;
  wire [addr_width_p-1:0] test_input_addr = hazard ? test_input_addr_r : random[8:3];
  logic [addr_width_p-1:0] test_input_addr_r;
  integer counter_r;
  wire [width_p-1:0] test_input_data = random[14:9];
  wire [width_p-1:0] test_input_mask = random[20:15];
  wire [width_p-1:0] data_o;

  logic [width_p-1:0] mem[0:els_p-1];
  generate
    integer ram_index;
    initial
      for (ram_index = 0; ram_index < els_p; ram_index = ram_index + 1)
        mem[ram_index] = {(width_p){1'b0}};
  endgenerate

  bsg_mem_1rw_sync_mask_write_bit_from_1r1w #(
    width_p,  
    els_p 
  )
  inst (
    clk,
    !reset,
    test_input_v,
    test_input_addr,
    test_input_w,
    test_input_data,
    test_input_mask,
    data_o
  );

  initial begin
    test_input_v_r = 0;
    test_input_w_r = 0;
    test_input_addr_r = 0;
    counter_r = 0;
  end
  
  always @(posedge clk) begin
      if(counter_r > 20) begin
        test_input_addr_r <= test_input_addr;
        test_input_v_r    <= test_input_v;
        test_input_w_r    <= test_input_w;
        if(test_input_v && test_input_w)
          mem[test_input_addr] <= mem[test_input_addr] & ~test_input_mask | test_input_data & test_input_mask;
       
      end
      counter_r <= counter_r + 1;
      assert((test_input_v_r && !test_input_w_r) ? (mem[test_input_addr_r] == data_o) : 1'b1) else $error ("Read data does not match harness' copy!");
  end
  
  initial
  begin
    $monitor(  "count:%06h | ", counter_r
             , " %s | %s | test_input_addr:%06h | test_input_data:%06h | test_input_mask:%6b"
             ,  test_input_v ? "v" : "", test_input_w ? "w" : "r", test_input_addr, test_input_data, test_input_mask
             , "| data_o:%06h | expected:%06h | %s"
             , data_o, mem[test_input_addr_r], (test_input_v_r && !test_input_w_r) ? "Verify now;" : "Hold on..." 
            );
    end
endmodule

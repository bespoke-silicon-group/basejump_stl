// Testbench to test a 1r1w memory built from 1rw memories

`define WIDTH_p 4
`define ELS_P 4
`define SEED_P 100
`define CLK_PERIOD 20

module testbench;

  localparam els_lp = `ELS_P;
  localparam width_lp = `WIDTH_P;
  localparam addr_width_lp = `BSG_SAFE_CLOG2(els_lp);
  localparam cycle_time_lp = `CLK_PERIOD;
  localparam seed_lp = `SEED_P;

  logic clk, reset;

  bsg_nonsynth_clock_gen
    #(.cycle_time_p(cycle_time_lp))
   clock_gen
    (.o(clk)
    );

  bsg_nonsynth_reset_gen
    #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(0)
     ,.reset_cycles_hi_p(10)
     )
   reset_gen
    (.clk_i(clk)
    ,.async_reset_o(reset)
    );

  initial begin
    $display("\nTesting parameters: ");
    $display("Memory Width: %d", width_lp);
    $display("Memory Depth: %d\n", els_lp);
    $display("========== Test begin ==========\n");
  end

  logic w_v_li, r_v_li;
  logic [addr_width_lp-1:0] w_addr_n, w_addr_r, r_addr_n, r_addr_r, r_addr_rr;
  logic [width_lp-1:0] w_data_li, w_data_r, w_data_rr, r_data_lo;
  logic finish_n, finish_r;

  bsg_mem_1r1w_sync_from_1rw_sync
    #(.width_p(width_lp)
     ,.els_p(els_lp)
     ,.read_write_same_addr_p(0)
     ,.disable_collision_warning_p(0)
     )
   DUT
    (.clk_i(clk)
    ,.reset_i(reset)
    
    ,.w_v_i(w_v_li)
    ,.w_addr_i(w_addr_r)
    ,.w_data_i(w_data_li)
    
    ,.r_v_i(r_v_li)
    ,.r_addr_i(r_addr_r)
    ,.r_data_o(r_data_lo)
    );

  // Delay reads from writes by 1 cycle
  bsg_dff
    #(.width_p(1))
   r_v_reg
    (.clk_i(clk)
    ,.data_i(w_v_li)
    ,.data_o(r_v_li)
    );

  // Generate write data randomly
  bsg_nonsynth_random_gen
    #(.width_p(width_lp)
     ,.seed_p(seed_lp)
     )
   w_data_gen
    (.clk_i(clk)
    ,.reset_i(reset)
    ,.yumi_i(1'b1)
    ,.data_o(w_data_li)
    );
  
  // Reads are synchronous and will appear on the next clock edge
  // so delay the read valids for comparison
  logic r_v_r;
  bsg_dff
    #(.width_p(1))
   r_v_r_reg
    (.clk_i(clk)
    ,.data_i(r_v_li)
    ,.data_o(r_v_r)
    );

  logic [addr_width_lp:0] count;
  bsg_cycle_counter
    #(.width_p(addr_width_lp+1)
     ,.init_val_p(0)
     )
   cycle_counter
    (.clk_i(clk)
    ,.reset_i(reset)
    
    ,.ctr_r_o(count)
    );

  always_comb begin
    w_v_li = 1'b0;
    w_addr_n = w_addr_r;
    r_addr_n = w_addr_r;
    finish_n = 1'b0;

    if (!reset) begin
      if (count < els_lp) begin
        w_v_li = 1'b1;
        w_addr_n = w_addr_r + 1'b1;
      end

      if (count == els_lp)
        finish_n = 1'b1;
    end
  end 

  always_ff @(posedge clk) begin
    if (reset) begin
      w_addr_r <= '0;
      w_data_r <= '0;
      w_data_rr <= '0;
      finish_r <= 1'b0;
    end
    else begin
      w_addr_r <= w_addr_n;
      w_data_r <= w_data_li;
      w_data_rr <= w_data_r;
      r_addr_r <= r_addr_n;
      r_addr_rr <= r_addr_r;
      finish_r <= finish_n;

      if (finish_r) begin
        $display("\n========== Test complete ==========\n");
        $finish;
      end
    end
  end

  always_ff @(negedge clk) begin
    if (!reset) begin
      // Assertions
      if (r_v_r === 1'b1)
        assert((r_data_lo == w_data_rr))
          else $error("%0t ps Read output (%x) not the same as written data (%x) for address (%x)", $time, r_data_lo, w_data_rr, r_addr_rr);

    end
    
    // Monitors
    // Note: Does not display writes to address 0. So, as long as the
    // assertion does not fire, you are good to go
    // if (w_v_li | r_v_r)
    //   $display("@%0t ps\nWrites: valid: %x addr: %x data: %x\nReads: valid: %x addr: %x data: %x",
    //     $time, w_v_li, w_addr_r, w_data_li, r_v_r, r_addr_rr, r_data_lo);
  end
  
endmodule

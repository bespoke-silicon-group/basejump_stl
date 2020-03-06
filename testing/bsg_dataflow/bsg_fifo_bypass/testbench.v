
module testbench;

  localparam width_lp = 4;
  localparam els_lp = 2;

  logic clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) clock_gen (
    .o(clk)
  );

  logic reset;
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  logic [width_lp-1:0] test_data_li;
  logic test_v_li, test_ready_lo;
  logic [width_lp-1:0] test_data_lo;
  logic test_v_lo, test_yumi_li;

  logic [width_lp-1:0] fifo_data_li;
  logic fifo_v_li, fifo_ready_lo;
  logic [width_lp-1:0] fifo_data_lo;
  logic fifo_v_lo, fifo_yumi_li;
  bsg_fifo_bypass
   #(.width_p(width_lp))
   DUT
    (.data_i(test_data_li)
     ,.v_i(test_v_li)
     ,.ready_o(test_ready_lo)

     ,.data_o(test_data_lo)
     ,.v_o(test_v_lo)
     ,.yumi_i(test_yumi_li)

     ,.fifo_data_o(fifo_data_li)
     ,.fifo_v_o(fifo_v_li)
     ,.fifo_ready_i(fifo_ready_lo)

     ,.fifo_data_i(fifo_data_lo)
     ,.fifo_v_i(fifo_v_lo)
     ,.fifo_yumi_o(fifo_yumi_li)
     );

  bsg_fifo_1r1w_small
   #(.width_p(width_lp)
     ,.els_p(els_lp)
     )
   fifo
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(fifo_data_li)
     ,.v_i(fifo_v_li)
     ,.ready_o(fifo_ready_lo)

     ,.data_o(fifo_data_lo)
     ,.v_o(fifo_v_lo)
     ,.yumi_i(fifo_yumi_li)
     );

  initial
    begin
      test_data_li = '0;
      test_v_li    = '0;
      test_yumi_li = '0;

      @(negedge reset);
      
      @(posedge clk);
      $display("Testing bypass");
      test_data_li = 4'h3;
      test_v_li = 1'b1;
      #1
      test_yumi_li = test_v_lo;
      @(negedge clk);
      $display("Checking that data is bypassed");
      assert (test_data_lo == test_data_li);
      assert (test_v_lo == 1'b1);
      @(posedge clk);
      test_v_li = 1'b0;
      test_yumi_li = 1'b0;
      $display("Checking bypassed data did not enqueue in fifo");
      @(negedge clk);
      assert (fifo_v_lo == 1'b0);

      @(posedge clk);
      $display("Testing enqueue");
      test_data_li = 4'hf;
      test_v_li = 1'b1;
      #1
      test_yumi_li = 1'b0;
      @(negedge clk);
      $display("Checking that data is bypassed");
      assert (test_data_lo == test_data_li);
      assert (test_v_lo == 1'b1);
      @(posedge clk);
      test_v_li = 1'b0;
      $display("Checking that data was enqueued on fifo");
      @(negedge clk);
      assert (fifo_v_lo == 1'b1);
      assert (fifo_data_lo == test_data_li);

      @(posedge clk);
      $display("Testing dequeue during enqueue");
      test_data_li = 4'h0;
      test_v_li = 1'b1;
      #1
      test_yumi_li = 1'b1;
      @(negedge clk);
      $display("Checking that data is coming from fifo, not bypass");
      assert (test_data_lo == fifo_data_lo);
      assert (test_v_lo == 1'b1);
      @(posedge clk);
      test_v_li = 1'b0;
      test_yumi_li = 1'b0;
      $display("Checking that data is coming from next in fifo");
      @(negedge clk);
      assert (test_data_lo == test_data_li);
      assert (test_v_lo == 1'b1);

      @(posedge clk);
      $display("Testing filling fifo");
      test_data_li = 4'hb;
      test_v_li = 1'b1;
      @(negedge clk);
      assert (test_data_lo == fifo_data_lo);
      assert (test_v_lo == 1'b1);
      @(posedge clk);
      test_v_li = 1'b0;
      test_yumi_li = 1'b0;
      $display("Checking that bypass reflects fullness");
      @(negedge clk);
      assert (test_ready_lo == 1'b0);
      assert (fifo_ready_lo == 1'b0);

      @(posedge clk);
      $display("Testing emptying fifo");
      test_data_li = 4'h6;
      test_yumi_li = 1'b1;
      @(negedge clk);
      @(posedge clk);
      @(posedge clk);
      $display("Checking that fifo is empty");
      @(negedge clk);
      assert (fifo_v_lo == 1'b0);
      assert (test_v_lo == 1'b0);
      

      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      $finish();
    end

endmodule


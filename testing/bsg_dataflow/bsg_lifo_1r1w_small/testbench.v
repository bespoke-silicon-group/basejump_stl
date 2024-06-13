
module testbench;

  localparam width_lp = 4;
  localparam els_lp = 4;
  localparam allow_rollover_lp = 1;

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

  logic [width_lp-1:0] lifo_data_li;
  logic lifo_v_li, lifo_ready_lo;
  logic [width_lp-1:0] lifo_data_lo;
  logic lifo_v_lo, lifo_yumi_li;

  bsg_lifo_1r1w_small
   #(.width_p(width_lp)
     ,.els_p(els_lp)
     ,.allow_rollover_p(allow_rollover_lp)
     )
   DUT
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(lifo_data_li)
     ,.v_i(lifo_v_li)
     ,.ready_o(lifo_ready_lo)

     ,.data_o(lifo_data_lo)
     ,.v_o(lifo_v_lo)
     ,.yumi_i(lifo_yumi_li)
     );

  if (allow_rollover_lp == 0)
    initial
      begin
        lifo_data_li = '0;
        lifo_v_li    = '0;

        lifo_yumi_li = '0;

        @(negedge reset);

        #1
        assert (~lifo_v_lo);
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd1;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd2;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd3;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd4;
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b0;
        #1
        assert (~lifo_ready_lo);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1;
        assert (lifo_data_lo == 4'd4);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd3);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd2);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd1);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b0;
        #1
        assert (~lifo_v_lo);
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'hc;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_yumi_li = 1'b1;
        lifo_data_li = 4'hf;
        #1
        assert (lifo_data_lo == 4'hf);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b0;
        #1
        assert (lifo_data_lo == 4'hc);
        
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $finish();
      end
  else
    initial
      begin
        lifo_data_li = '0;
        lifo_v_li    = '0;

        lifo_yumi_li = '0;

        @(negedge reset);

        #1
        assert (~lifo_v_lo);
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd1;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd2;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd3;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd4;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd5;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd6;
        @(negedge clk);
        lifo_v_li = 1'b1;
        lifo_data_li = 4'd7;

        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b0;
        #1;
        assert (lifo_ready_lo);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1;
        assert (lifo_data_lo == 4'd7);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd6);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd5);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b1;
        #1
        assert (lifo_ready_lo);
        assert (lifo_data_lo == 4'd4);
        @(negedge clk);
        lifo_v_li = 1'b0;
        lifo_yumi_li = 1'b0;
        #1
        assert (~lifo_v_lo);

        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        $finish();
      end

endmodule


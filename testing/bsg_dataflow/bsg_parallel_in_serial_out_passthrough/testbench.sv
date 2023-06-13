
module testbench;

  localparam wide_width_lp = 16;
  localparam narrow_width_lp = 4;
  localparam els_lp = wide_width_lp / narrow_width_lp;

  logic clk;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(1000))
   clock_gen
    (.o(clk));

  logic reset;
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(4)
     ,.reset_cycles_hi_p(4)
     )
   reset_gen
    (.clk_i(clk)
     ,.async_reset_o(reset)
     );

  logic [wide_width_lp-1:0] in_data_li;
  logic in_v_li, in_ready_lo;
  logic [narrow_width_lp-1:0] in_data_lo;
  logic in_v_lo, in_yumi_li;

  logic [narrow_width_lp-1:0] out_data_li;
  logic out_v_li, out_ready_lo;
  logic [wide_width_lp-1:0] out_data_lo;
  logic out_v_lo, out_ready_li;

  bsg_parallel_in_serial_out_passthrough
   #(.width_p(narrow_width_lp), .els_p(els_lp))
   DUT
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(in_data_li)
     ,.v_i(in_v_li)
     ,.ready_and_o(in_ready_lo)

     ,.data_o(in_data_lo)
     ,.v_o(in_v_lo)
     ,.ready_and_i(in_yumi_li)
     );

  assign out_data_li = in_data_lo;
  assign out_v_li = in_v_lo;
  assign in_yumi_li = out_ready_lo & out_v_li;

  bsg_serial_in_parallel_out_full
   #(.width_p(narrow_width_lp), .els_p(els_lp))
   reverse
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(out_data_li)
     ,.v_i(out_v_li)
     ,.ready_o(out_ready_lo)

     ,.data_o(out_data_lo)
     ,.v_o(out_v_lo)
     ,.yumi_i(out_ready_li & out_v_lo)
     );

  // Input block
  initial
    begin
      in_data_li = '0;
      in_v_li    = '0;

      @(posedge clk);
      @(negedge reset);
      @(posedge clk);

      for (integer i = 0; i < 100; i++)
        begin
          in_v_li = 1'b1;

          @(negedge clk);
          in_data_li = in_data_li + (in_ready_lo & in_v_li);
          if (in_ready_lo & in_v_li)
            $display("Sending %d", in_data_li);
        end
    end

  // Checking block
  logic [wide_width_lp-1:0] match_data_li;
  initial
    begin
      out_ready_li  = '0;
      match_data_li = '0;

      @(posedge clk);
      @(negedge reset);
      @(posedge clk);

      for (integer i = 1; i < 101; i++)
        begin
          out_ready_li = 1'b1;

          match_data_li = match_data_li + (out_ready_li & out_v_lo);
          @(negedge clk);
          assert(~(out_ready_li & out_v_lo) || match_data_li == out_data_lo);
          if (out_ready_li & out_v_lo)
            $display("Receiving %d", match_data_li);
        end

      $finish();
    end

endmodule


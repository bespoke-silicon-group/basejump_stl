
`include "bsg_defines.v"

module testbench;

  localparam width_p = 8;

  wire clk_4x, reset_4x;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(10))
   clock_gen_4x
    (.o(clk_4x));

  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(1)
     ,.reset_cycles_hi_p(5)
     )
   reset_gen_4x
    (.clk_i(clk_4x)
     ,.async_reset_o(reset_4x)
     );

  wire clk_1x, reset_1x;
  bsg_counter_clock_downsample
   #(.width_p(2))
   downsample
    (.clk_i(clk_4x)
     ,.reset_i(reset_4x)
     ,.val_i(2'd3)
     ,.clk_r_o(clk_1x)
     );

  bsg_nonsynth_reset_gen
   #(.num_clocks_p(1)
     ,.reset_cycles_lo_p(1)
     ,.reset_cycles_hi_p(5)
     )
   reset_gen_1x
    (.clk_i(clk_1x)
     ,.async_reset_o(reset_1x)
     );

  logic [width_p-1:0] in_data_li;
  logic in_v_li, in_ready_lo;
  logic [width_p-1:0] in_data_lo;
  logic in_v_lo, in_ready_li;
  bsg_two_fifo
   #(.width_p(width_p))
   input_fifo
    (.clk_i(clk_1x)
     ,.reset_i(reset_1x)

     ,.data_i(in_data_li)
     ,.v_i(in_v_li)
     ,.ready_o(in_ready_lo)
  
     ,.data_o(in_data_lo)
     ,.v_o(in_v_lo)
     ,.yumi_i(in_ready_li & in_v_lo)
     );
  
  logic mid_v_li, mid_ready_lo;
  bsg_fifo_periodic
   #(.a_period_p(1), .b_period_p(4))
   input_divide
    (.a_clk_i(clk_1x)
     ,.a_reset_i(reset_1x)
     ,.a_v_i(in_v_lo)
     ,.a_ready_and_o(in_ready_li)

     ,.b_clk_i(clk_4x)
     ,.b_reset_i(reset_1x)
     ,.b_v_o(mid_v_li)
     ,.b_ready_and_i(mid_ready_lo)
     );

  logic mid_v_lo, mid_ready_li;
  logic [width_p-1:0] out_data_li;
  bsg_two_fifo
   #(.width_p(width_p))
   middle_fifo
    (.clk_i(clk_4x)
     ,.reset_i(reset_1x)

     ,.data_i(in_data_lo)
     ,.v_i(mid_v_li)
     ,.ready_o(mid_ready_lo)

     ,.data_o(out_data_li)
     ,.v_o(mid_v_lo)
     ,.yumi_i(mid_ready_li & mid_v_lo)
     );

  logic out_v_li, out_ready_lo;
  bsg_fifo_periodic
   #(.a_period_p(4), .b_period_p(1))
   output_divide
    (.a_clk_i(clk_4x)
     ,.a_reset_i(reset_1x)
     ,.a_v_i(mid_v_lo)
     ,.a_ready_and_o(mid_ready_li)

     ,.b_clk_i(clk_1x)
     ,.b_reset_i(reset_1x)
     ,.b_v_o(out_v_li)
     ,.b_ready_and_i(out_ready_lo)
     );

  logic [width_p-1:0] out_data_lo;
  logic out_v_lo, out_yumi_li;
  bsg_two_fifo
   #(.width_p(width_p))
   output_fifo
    (.clk_i(clk_1x)
     ,.reset_i(reset_1x)

     ,.data_i(out_data_li)
     ,.v_i(out_v_li)
     ,.ready_o(out_ready_lo)

     ,.data_o(out_data_lo)
     ,.v_o(out_v_lo)
     ,.yumi_i(out_yumi_li)
     );
 
  // Input block
  initial
    begin
      in_data_li = '0;
      in_v_li    = '0;

      @(posedge clk_1x);
      @(negedge reset_1x);
      @(posedge clk_1x);

      for (integer i = 0; i < 100; i++)
        begin
          in_v_li = in_ready_lo;
          in_data_li = in_data_li + in_v_li;

          $display("Sending %d", in_data_li);
          @(negedge clk_1x);
        end
    end

  // Checking block
  logic [width_p-1:0] match_data_li;
  initial
    begin
      out_yumi_li   = '0;
      match_data_li = '0;

      @(posedge clk_1x);
      @(negedge reset_1x);
      @(posedge clk_1x);

      for (integer i = 1; i < 101; i++)
        begin
          out_yumi_li = out_v_lo;
          match_data_li = match_data_li + out_yumi_li;

          $display("Receiving %d", match_data_li);
          assert(~out_yumi_li || match_data_li == out_data_lo);
          @(negedge clk_1x);
        end

      $finish();
    end


endmodule


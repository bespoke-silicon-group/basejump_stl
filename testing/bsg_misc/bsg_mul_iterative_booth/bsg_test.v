`timescale 1ps/1ps
module bsg_test;

  localparam width_p = 32;
  logic clk_li;
  logic reset_li;
  logic yumi_li;
  logic ready_lo;

  logic [width_p-1:0] opA_li;
  logic [width_p-1:0] opB_li;
  wire [2*width_p-1:0] opA_cal = {{width_p{opA_li[width_p-1]}},opA_li};
  wire [2*width_p-1:0] opB_cal = {{width_p{opB_li[width_p-1]}},opB_li};
  logic signed_li;
  logic v_li;

  logic [2*width_p-1:0] result_lo;
  wire [2*width_p-1:0] actual_result = signed_li ? opA_cal * opB_cal : opA_li * opB_li;
  logic v_lo;

  bsg_mul_iterative_booth #(
    .width_p(width_p)
    ,.iter_step_p(width_p)
  ) mul(
    .clk_i(clk_li)
    ,.reset_i(reset_li)
    ,.ready_o(ready_lo)
    ,.opA_i(opA_li)
    ,.opB_i(opB_li)
    ,.signed_i(signed_li)
    ,.v_i(v_li)
    ,.result_o(result_lo)
    ,.v_o(v_lo)
    ,.yumi_i(yumi_li)
  );

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(50)
  ) clk_gen (
    .o(clk_li)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(5)
  ) rst_gen (
    .clk_i(clk_li)
    ,.async_reset_o(reset_li)
  );
  integer i;
  always_ff @(posedge clk_li) begin
    if(reset_li) begin
      yumi_li <= 1'b1;
      opA_li <= $random;
      opB_li <= $random;
      signed_li <= 1'b0;
      v_li <= 1'b1;
      i = 0;
    end
    else if(v_lo) begin
      $display("self:%x, system:%x, difference: %x",result_lo, actual_result, result_lo - actual_result);
      $display("===================================");
      if(result_lo - actual_result != 0) begin
        $display("Error!");
        $display("opA:%dD %xH,opB:%dD %xH",opA_li,opA_li,opB_li,opB_li);
        $finish;
      end
      opA_li <= $random;
      opB_li <= $random;
      i = i + 1;

      if(i == 100) begin
        if(signed_li == 1) begin
          $display("All passed!");
          $finish;
        end
        else begin
          signed_li = 1;
          i = 0;
        end
      end
    end
  end
endmodule


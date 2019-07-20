`define WIDTH_P 8
module test_bsg;

localparam once = 0;

logic clk_li;
logic rst_li;
logic reset_when_done_li;
logic op_v_li;

logic ready_lo;
logic [`WIDTH_P-1:0] opA_li;
wire [`WIDTH_P-1:0] opA_li_ext = {`WIDTH_P{opA_li[`WIDTH_P-1]}};
logic [`WIDTH_P-1:0] opB_li;
wire [`WIDTH_P-1:0] opB_li_ext = {`WIDTH_P{opB_li[`WIDTH_P-1]}};

logic opA_is_signed_li;
logic opB_is_signed_li;

logic [`WIDTH_P*2-1:0] result_lo;
logic result_v_lo;

wire [`WIDTH_P*2-1:0] right_result = {opA_li_ext,opA_li} * {opB_li_ext,opB_li};

bsg_mul_iterative #(
  .width_p(`WIDTH_P)
  ,.iter_step_p(4)
  ,.debug_p(once)
)mul(
  .clk_i(clk_li)
  ,.reset_i(rst_li)
  ,.yumi_i(reset_when_done_li)
  // shakehand signal
  ,.v_i(op_v_li)
  ,.ready_o(ready_lo)
  // operands
  ,.opA_i(opA_li)
  ,.opA_is_signed_i(opA_is_signed_li)
  ,.opB_i(opB_li)
  ,.opB_is_signed_i(opB_is_signed_li)
  // result
  ,.result_o(result_lo)
  ,.v_o(result_v_lo)
);

bsg_nonsynth_clock_gen #(
  .cycle_time_p(66000)
) 
clk_gen(
  .o(clk_li)
);

bsg_nonsynth_reset_gen #(
  .num_clocks_p(1)
  ,.reset_cycles_lo_p(1)
  ,.reset_cycles_hi_p(5)
)
rst_gen(
  .clk_i(clk_li)
  ,.async_reset_o(rst_li)
);

always_ff @(posedge clk_li) begin
  if(rst_li) begin
    reset_when_done_li <= 1'b1;
    op_v_li <= 1'b1;
    opA_li <= '0;
    opB_li <= '0;
    opA_is_signed_li <= 1'b1;
    opB_is_signed_li <= 1'b1;
  end
  else if(result_v_lo) begin
    $display("opA:%x,opB:%x",{opA_li_ext,opA_li},{opB_li_ext,opB_li});
    $display("Theory:%x, From Multiplier:%x",right_result,result_lo);
    $display("Difference:%x",result_lo - right_result);
    assert (result_lo == right_result) else begin
      $error("Error!");
      $finish;
    end
    if(once) $finish;
    opA_li++;
    if(opA_li == '0) begin
      opB_li++;
      if(opB_li == '0) begin
        $display("No error!");
        $finish;
      end
    end
  end
end

endmodule



module bsg_fifo_1r1w_periodic
 #(parameter `BSG_INV_PARAM(a_period_p)
   , parameter `BSG_INV_PARAM(b_period_p)
   , parameter num_hs_p = 1
   )
  (input                         a_clk_i
   , input                       a_reset_i
   , input [num_hs_p-1:0]        a_v_i
   , output logic                a_yumi_o

   , input                       b_clk_i
   , input                       b_reset_i
   , output logic [num_hs_p-1:0] b_v_o
   , input [num_hs_p-1:0]        b_ready_then_i
   );

  localparam fast2slow_lp  = (a_period_p > b_period_p);
  localparam ratio_lp      = fast2slow_lp ? a_period_p : b_period_p;

  logic [ratio_lp-1:0] cnt_r;
  wire fast_clk   = fast2slow_lp ? a_clk_i   : b_clk_i;
  wire fast_reset = fast2slow_lp ? a_reset_i : b_reset_i;
  bsg_counter_clear_up_one_hot
   #(.max_val_p(ratio_lp-1))
   counter
    (.clk_i(fast_clk)
     ,.reset_i(fast_reset)

     ,.clear_i(1'b0)
     ,.up_i(1'b1)
     ,.count_r_o(cnt_r)
     );
  wire [num_hs_p-1:0] accept_input = {num_hs_p{cnt_r[ratio_lp-1]}} & b_ready_then_i & a_v_i;
  assign b_v_o      = accept_input;
  assign a_yumi_o   = accept_input;

  if ((a_period_p != 1) && (b_period_p != 1))
    $error("Only 1:N or N:1 division ratios are currently supported");

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_periodic)


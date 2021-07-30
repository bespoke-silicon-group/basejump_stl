module test_bsg
#(parameter send_v_and_ready_p=0,
  parameter send_v_then_yumi_p=0,
  parameter send_ready_then_v_p=0,
  parameter send_retry_then_v_p=0,
  parameter send_v_and_retry_p=0,
  parameter recv_v_and_ready_p=0,
  parameter recv_v_then_yumi_p=0,
  parameter recv_ready_then_v_p=0,
  parameter recv_v_and_retry_p=0,
  parameter recv_v_then_retry_p=0,
  parameter width_p=0,
  parameter sim_clk_period=10,
  parameter reset_cycles_lo_p=-1,
  parameter reset_cycles_hi_p=-1
  );

  wire clk_lo;
  logic reset;

  `ifdef VERILATOR
    bsg_nonsynth_dpi_clock_gen
  `else
    bsg_nonsynth_clock_gen
  `endif
   #(.cycle_time_p(sim_clk_period))
   clock_gen
    (.o(clk_lo));

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk_lo) 
                           , .async_reset_o(reset)
                          );

  initial begin
    $display("[BSG_PASS] Empty testbench");
    $finish();
  end

  wire [width_p-1:0] v_i;
  wire [width_p-1:0] fc_o;
  wire [width_p-1:0] v_o;
  wire [width_p-1:0] fc_i;

  bsg_flow_convert #(
    .width_p(width_p),
    .send_v_and_ready_p(send_v_and_ready_p),
    .send_v_then_yumi_p(send_v_then_yumi_p),
    .send_ready_then_v_p(send_ready_then_v_p),
    .send_retry_then_v_p(send_retry_then_v_p),
    .send_v_and_retry_p(send_v_and_retry_p),
    .recv_v_and_ready_p(recv_v_and_ready_p),
    .recv_v_then_yumi_p(recv_v_then_yumi_p),
    .recv_ready_then_v_p(recv_ready_then_v_p),
    .recv_v_and_retry_p(recv_v_and_retry_p),
    .recv_v_then_retry_p(recv_v_then_retry_p))
    DUT (
    .v_i(v_i),
    .fc_o(fc_o),
    .v_o(v_o),
    .fc_i(fc_i)
  );

endmodule

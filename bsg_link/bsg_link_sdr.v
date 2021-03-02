
module bsg_link_sdr

 #(parameter width_p                         = "inv"
  ,parameter lg_fifo_depth_p                 = "inv"
  ,parameter lg_credit_to_token_decimation_p = "inv"
  )

  (  input core_clk_i
   , input core_uplink_reset_i
   , input core_downstream_reset_i
   , input async_downlink_reset_i
   , input async_token_reset_i

   , input                 core_v_i
   , input  [width_p-1:0]  core_data_i
   , output                core_ready_o

   , output                core_v_o
   , output [width_p-1:0]  core_data_o
   , input                 core_yumi_i

   , output                link_clk_o
   , output [width_p-1:0]  link_data_o
   , output                link_v_o
   , input                 link_token_i

   , input                 link_clk_i
   , input  [width_p-1:0]  link_data_i
   , input                 link_v_i
   , output                link_token_o
   );

  bsg_link_sdr_upstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) uplink
  (// Core side
   .io_clk_i           (core_clk_i)
  ,.io_link_reset_i    (core_uplink_reset_i)
  ,.async_token_reset_i(async_token_reset_i)
  ,.io_data_i          (core_data_i)
  ,.io_v_i             (core_v_i)
  ,.io_ready_and_o     (core_ready_o)
  // IO side
  ,.io_clk_o           (link_clk_o)
  ,.io_data_o          (link_data_o)
  ,.io_v_o             (link_v_o)
  ,.token_clk_i        (link_token_i)
  );

  bsg_link_sdr_downstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) downlink
  (// Core side
   .core_clk_i           (core_clk_i)
  ,.core_link_reset_i    (core_downstream_reset_i)
  ,.core_data_o          (core_data_o)
  ,.core_v_o             (core_v_o)
  ,.core_yumi_i          (core_yumi_i)
  // IO side
  ,.async_io_link_reset_i(async_downlink_reset_i)
  ,.io_clk_i             (link_clk_i)
  ,.io_data_i            (link_data_i)
  ,.io_v_i               (link_v_i)
  ,.core_token_r_o       (link_token_o)
  );

endmodule

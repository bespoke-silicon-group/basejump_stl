
//
// Paul Gao 03/2019
//
//

module bsg_link_sdr_downstream

 #(parameter width_p = "inv"
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_ddr_upstream setting
  ,parameter lg_fifo_depth_p = 3
  // Token credit decimation
  // MUST MATCH paired bsg_link_ddr_upstream setting
  ,parameter lg_credit_to_token_decimation_p = 1
  )

  (// Core side
   input                core_clk_i
  ,input                core_reset_i
  ,output               core_v_o
  ,output [width_p-1:0] core_data_o
  ,input                core_yumi_i
  // IO side
  ,input                io_reset_i
  ,input                io_clk_i
  ,input                io_v_i
  ,input  [width_p-1:0] io_data_i
  ,output               core_token_r_o
  );

  logic io_v_lo;
  logic [width_p-1:0] io_data_lo;

  // valid and data signals are received together
  bsg_link_isdr_phy
 #(.width_p(width_p+1)
  ) isdr_phy
  (.clk_i  (io_clk_i)
  ,.data_i ({io_v_i, io_data_i})
  ,.data_o ({io_v_lo, io_data_lo})
  );

  bsg_link_source_sync_downstream
 #(.channel_width_p(width_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) downstream
  (.core_clk_i       (core_clk_i)
  ,.core_link_reset_i(core_reset_i)
  ,.io_link_reset_i  (io_reset_i)
  // source synchronous input channel
  ,.io_clk_i         (io_clk_i)
  ,.io_data_i        (io_data_lo)
  ,.io_valid_i       (io_v_lo)
  ,.core_token_r_o   (core_token_r_o)
  // going into core
  ,.core_data_o      (core_data_o)
  ,.core_valid_o     (core_v_o)
  ,.core_yumi_i      (core_yumi_i)
  );

endmodule
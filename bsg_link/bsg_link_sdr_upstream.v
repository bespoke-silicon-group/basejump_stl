
//
// Paul Gao 02/2021
//
//

module bsg_link_sdr_upstream

 #(parameter width_p = "inv"
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_sdr_downstream setting
  ,parameter lg_fifo_depth_p = 3
  // Token credit decimation
  // MUST MATCH paired bsg_link_sdr_downstream setting
  ,parameter lg_credit_to_token_decimation_p = 1
  )

  (// Core side
   input                io_clk_i
  ,input                io_link_reset_i
  ,input                async_token_reset_i
  ,input                io_v_i
  ,input  [width_p-1:0] io_data_i
  ,output               io_ready_and_o
  // IO side
  ,output               io_clk_o
  ,output               io_v_o
  ,output [width_p-1:0] io_data_o
  ,input                token_clk_i
  );

  logic osdr_v_li;
  logic [width_p-1:0] osdr_data_li;

  bsg_link_source_sync_upstream_sync
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) sso
  (.io_clk_i           (io_clk_i)
  ,.io_link_reset_i    (io_link_reset_i)
  ,.async_token_reset_i(async_token_reset_i)
  ,.io_v_i             (io_v_i)
  ,.io_data_i          (io_data_i)
  ,.io_ready_and_o     (io_ready_and_o)
  ,.io_v_o             (osdr_v_li)
  ,.io_data_o          (osdr_data_li)
  ,.token_clk_i        (token_clk_i)
  );

  // valid and data signals are sent together
  bsg_link_osdr_phy
 #(.width_p(width_p+1)
  ) osdr_phy
  (.clk_i  (io_clk_i)
  ,.reset_i(io_link_reset_i)
  ,.data_i ({osdr_v_li, osdr_data_li})
  ,.clk_o  (io_clk_o)
  ,.data_o ({io_v_o, io_data_o})
  );

endmodule

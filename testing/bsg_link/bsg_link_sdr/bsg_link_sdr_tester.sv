
//
// Paul Gao 01/2021
//
//

`timescale 1ps/1ps

module bsg_link_sdr_tester

 #(parameter width_p                         = 64
  ,parameter lg_fifo_depth_p                 = 3
  ,parameter lg_credit_to_token_decimation_p = 0
  )

  ();

  logic upnode_clk, upnode_reset, upnode_en;
  logic uplink_clk, uplink_reset, downlink_reset, async_token_reset;
  logic downstream_clk, downstream_reset;
  logic downnode_clk, downnode_reset, downnode_error;
  logic [31:0] upnode_sent, downnode_received;

  logic uplink_v_li, uplink_ready_lo;
  logic [width_p-1:0] uplink_data_li;

  logic downstream_v_lo, downstream_ready_li;
  logic [width_p-1:0] downstream_data_lo;

  logic link_clk, link_v, link_tkn;
  logic [width_p-1:0] link_data;

  bsg_link_sdr_test_node
 #(.num_channels_p      (8)
  ,.channel_width_p     (width_p/8)
  ,.is_downstream_node_p(0)
  ) upnode
  (// Node side
   .node_clk_i  (upnode_clk)
  ,.node_reset_i(upnode_reset)
  ,.node_en_i   (upnode_en)
  ,.error_o     ()
  ,.sent_o      (upnode_sent)
  ,.received_o  ()
  // Link side
  ,.clk_i       (uplink_clk)
  ,.reset_i     (uplink_reset)
  ,.v_i         (1'b0)
  ,.data_i      ('0)
  ,.ready_o     ()
  ,.v_o         (uplink_v_li)
  ,.data_o      (uplink_data_li)
  ,.yumi_i      (uplink_v_li & uplink_ready_lo)
  );

  bsg_link_sdr_upstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) uplink
  (// Core side
   .io_clk_i           (uplink_clk)
  ,.io_link_reset_i    (uplink_reset)
  ,.async_token_reset_i(async_token_reset)
  ,.io_data_i          (uplink_data_li)
  ,.io_v_i             (uplink_v_li)
  ,.io_ready_and_o     (uplink_ready_lo)
  // IO side
  ,.io_clk_o           (link_clk)
  ,.io_data_o          (link_data)
  ,.io_v_o             (link_v)
  ,.token_clk_i        (link_tkn)
  );

  bsg_link_sdr_downstream
 #(.width_p                        (width_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) downlink
  (// Core side
   .core_clk_i        (downstream_clk)
  ,.core_link_reset_i (downstream_reset)
  ,.core_data_o       (downstream_data_lo)
  ,.core_v_o          (downstream_v_lo)
  ,.core_yumi_i       (downstream_v_lo & downstream_ready_li)
  // IO side
  ,.async_io_link_reset_i(downlink_reset)
  ,.io_clk_i          (link_clk)
  ,.io_data_i         (link_data)
  ,.io_v_i            (link_v)
  ,.core_token_r_o    (link_tkn)
  );

  bsg_link_sdr_test_node
 #(.num_channels_p      (8)
  ,.channel_width_p     (width_p/8)
  ,.is_downstream_node_p(1)
  ) downnode
  (// Node side
   .node_clk_i  (downnode_clk)
  ,.node_reset_i(downnode_reset)
  ,.node_en_i   ()
  ,.error_o     (downnode_error)
  ,.sent_o      ()
  ,.received_o  (downnode_received)
  // Link side
  ,.clk_i       (downstream_clk)
  ,.reset_i     (downstream_reset)
  ,.v_i         (downstream_v_lo)
  ,.data_i      (downstream_data_lo)
  ,.ready_o     (downstream_ready_li)
  ,.v_o         ()
  ,.data_o      ()
  ,.yumi_i      (1'b0)
  );

  // Simulation of Clock
  always #4 upnode_clk     = ~upnode_clk;
  always #4 uplink_clk     = ~uplink_clk;
  always #4 downstream_clk = ~downstream_clk;
  always #4 downnode_clk   = ~downnode_clk;

  initial 
  begin

    $display("Start Simulation\n");

    // Init
    upnode_clk     = 1;
    uplink_clk     = 1;
    downstream_clk = 1;
    downnode_clk   = 1;

    uplink_reset      = 1;
    async_token_reset = 0;
    upnode_reset      = 1;
    downnode_reset    = 1;
    downstream_reset  = 1;

    upnode_en = 0;

    #1000;

    // async token reset
    async_token_reset = 1;
    async_token_reset = 1;

    #1000;

    async_token_reset = 0;
    async_token_reset = 0;

    #1000;

    // upstream io reset
    @(posedge uplink_clk); #1;
    uplink_reset = 0;

    #100;

    // reset signals propagate to downstream after io_clk is generated
    @(posedge uplink_clk); #1;
    downlink_reset = 1;

    #1000;

    // downstream IO reset
    @(posedge uplink_clk); #1;
    downlink_reset = 0;

    #1000;

    // core link reset
    @(posedge downstream_clk); #1;
    downstream_reset = 0;

    #1000

    // node reset
    @(posedge upnode_clk); #1;
    upnode_reset = 0;
    @(posedge downnode_clk); #1;
    downnode_reset = 0;

    #1000

    // node enable
    @(posedge upnode_clk); #1;
    upnode_en = 1;

    #50000

    // node disable
    @(posedge upnode_clk); #1;
    upnode_en = 0;

    #5000

    assert(downnode_error == 0)
    else 
      begin
        $error("\nFAIL... Error in test node");
        $finish;
      end

    assert(upnode_sent == downnode_received)
    else 
      begin
        $error("\nFAIL... Test node sent %d packets but received only %d\n", upnode_sent, downnode_received);
        $finish;
      end

    $display("\nPASS!\n");
    $display("Test node sent and received %d packets\n", upnode_sent);
    $finish;

  end

endmodule

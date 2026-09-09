
//
// Paul Gao 01/2021
//
//

`timescale 1ps/1ps

module bsg_link_ddr_tester

 #(parameter width_p                         = 64
  ,parameter channel_width_p                 = 16
  ,parameter num_channels_p                  = 1
  ,parameter lg_fifo_depth_p                 = 6
  ,parameter lg_credit_to_token_decimation_p = 3
  ,parameter use_extra_data_bit_p            = 0
  ,parameter use_encode_p                    = 1
  ,localparam wire_dly_lp                    = 13
  )

  ();

  logic upnode_clk, upnode_reset, upnode_en;
  logic upstream_clk, upstream_reset;
  logic uplink_clk, uplink_reset, downlink_reset, async_token_reset;
  logic downstream_clk, downstream_reset;
  logic downnode_clk, downnode_reset, downnode_error;
  logic [31:0] upnode_sent, downnode_received;

  logic upstream_v_li, upstream_ready_lo;
  logic [width_p-1:0] upstream_data_li;

  logic downstream_v_lo, downstream_ready_li;
  logic [width_p-1:0] downstream_data_lo;

  logic [num_channels_p-1:0] link_clk, link_v, link_tkn;
  logic [num_channels_p-1:0][channel_width_p-1:0] link_data;

  bsg_link_ddr_test_node
 #(.num_channels_p      (width_p/channel_width_p)
  ,.channel_width_p     (channel_width_p)
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
  ,.clk_i       (upstream_clk)
  ,.reset_i     (upstream_reset)
  ,.v_i         (1'b0)
  ,.data_i      ('0)
  ,.ready_o     ()
  ,.v_o         (upstream_v_li)
  ,.data_o      (upstream_data_li)
  ,.yumi_i      (upstream_v_li & upstream_ready_lo)
  );

  bsg_link_ddr_upstream 
 #(.width_p                        (width_p)
  ,.channel_width_p                (channel_width_p)
  ,.num_channels_p                 (num_channels_p)
  ,.lg_fifo_depth_p                (lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ,.use_extra_data_bit_p           (use_extra_data_bit_p)
  ,.use_encode_p                   (use_encode_p)
  ) uplink
  (// Core side
   .core_clk_i         (upstream_clk)
  ,.core_link_reset_i  (upstream_reset)
  ,.core_data_i        (upstream_data_li)
  ,.core_valid_i       (upstream_v_li)
  ,.core_ready_o       (upstream_ready_lo)
  // IO side
  ,.io_clk_i           (uplink_clk)
  ,.io_link_reset_i    (uplink_reset)
  ,.async_token_reset_i(async_token_reset)
  ,.io_clk_r_o         (link_clk)
  ,.io_data_r_o        (link_data)
  ,.io_valid_r_o       (link_v)
  ,.token_clk_i        (link_tkn)
  );

  if (use_encode_p == 0)
  begin: no_encode

    logic [num_channels_p-1:0] downlink_reset_sync;

    for (genvar i = 0; i < num_channels_p; i++)
    begin: down_reset
      bsg_sync_sync #(.width_p(1)) bss
      (.oclk_i     (link_clk           [i])
      ,.iclk_data_i(downlink_reset        )
      ,.oclk_data_o(downlink_reset_sync[i])
      );
    end

    bsg_link_ddr_downstream 
   #(.width_p                        (width_p)
    ,.channel_width_p                (channel_width_p)
    ,.num_channels_p                 (num_channels_p)
    ,.lg_fifo_depth_p                (lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ,.use_extra_data_bit_p           (use_extra_data_bit_p)
    ,.use_encode_p                   (use_encode_p)
    ) downlink
    (// Core side
     .core_clk_i        (downstream_clk)
    ,.core_link_reset_i (downstream_reset)
    ,.core_data_o       (downstream_data_lo)
    ,.core_valid_o      (downstream_v_lo)
    ,.core_yumi_i       (downstream_v_lo & downstream_ready_li)
    // IO side
    ,.io_link_reset_i   (downlink_reset_sync)
    ,.io_clk_i          (link_clk)
    ,.io_data_i         (link_data)
    ,.io_valid_i        (link_v)
    ,.core_token_r_o    (link_tkn)
    );

  end
  else
  begin: encode

    logic [num_channels_p-1:0][1:0] downlink_reset_sync, downlink_clk;
    logic [num_channels_p-1:0] downlink_v, downlink_tkn;
    logic [num_channels_p-1:0][channel_width_p-1:0] downlink_data;

    for (genvar i = 0; i < num_channels_p; i++)
      begin: dly
        assign link_tkn[i] = downlink_tkn[i];
        assign downlink_v[i] = link_v[i];
        assign downlink_clk[i][1] = link_clk[i];
        assign downlink_data[i][channel_width_p-1:channel_width_p/2] = link_data[i][channel_width_p-1:channel_width_p/2];
        bsg_nonsynth_delay_line #(.width_p(1),.delay_p(wire_dly_lp)) clk_dly
        (.i(link_clk[i]),.o(downlink_clk[i][0]));
        bsg_nonsynth_delay_line #(.width_p(channel_width_p/2),.delay_p(wire_dly_lp)) data_dly
        (.i(link_data[i][channel_width_p/2-1:0]),.o(downlink_data[i][channel_width_p/2-1:0]));
      end

    for (genvar i = 0; i < num_channels_p; i++)
    begin: down_reset
      for (genvar j = 0; j < 2; j++)
        begin: dual
          bsg_sync_sync #(.width_p(1)) bss
          (.oclk_i     (downlink_clk       [i][j])
          ,.iclk_data_i(downlink_reset           )
          ,.oclk_data_o(downlink_reset_sync[i][j])
          );
        end
    end

    bsg_link_ddr_downstream_encode
   #(.width_p                        (width_p)
    ,.channel_width_p                (channel_width_p)
    ,.num_channels_p                 (num_channels_p)
    ,.lg_fifo_depth_p                (lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ,.use_extra_data_bit_p           (use_extra_data_bit_p)
    ) downlink
    (// Core side
     .core_clk_i        (downstream_clk)
    ,.core_link_reset_i (downstream_reset)
    ,.core_data_o       (downstream_data_lo)
    ,.core_valid_o      (downstream_v_lo)
    ,.core_yumi_i       (downstream_v_lo & downstream_ready_li)
    // IO side
    ,.io_link_reset_i   (downlink_reset_sync)
    ,.io_clk_i          (downlink_clk)
    ,.io_data_i         (downlink_data)
    ,.io_valid_i        (downlink_v)
    ,.core_token_r_o    (downlink_tkn)
    );

  end

  bsg_link_ddr_test_node
 #(.num_channels_p      (width_p/channel_width_p)
  ,.channel_width_p     (channel_width_p)
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
  always #4 upstream_clk   = ~upstream_clk;
  always #4 uplink_clk     = ~uplink_clk;
  always #4 downstream_clk = ~downstream_clk;
  always #4 downnode_clk   = ~downnode_clk;

  initial 
  begin

    $display("Start Simulation\n");

    // Init
    upnode_clk     = 1;
    upstream_clk   = 1;
    uplink_clk     = 1;
    downstream_clk = 1;
    downnode_clk   = 1;

    uplink_reset      = 1;
    async_token_reset = 0;
    upnode_reset      = 1;
    downnode_reset    = 1;
    upstream_reset    = 1;
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
    @(posedge upstream_clk); #1;
    upstream_reset = 0;
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


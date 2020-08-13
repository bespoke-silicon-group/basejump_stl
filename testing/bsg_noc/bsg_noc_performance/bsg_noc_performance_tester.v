
//
// Paul Gao 08/2020
//
//

`include "bsg_noc_links.vh"
`timescale 1ps/1ps

module bsg_noc_performance_tester

 #(
  /*********************** Fundamental params ***********************/
  
  // How many streams of traffic are merged in channel tunnel
  // In this testbench the number of traffics is 2 (req and resp traffic)
   parameter ct_num_in_p = 2
  
  // Tag bits are for channel_tunnel_wormhole to mux and demux packets
  // If we are merging m traffics in channel tunnel, then tag bits shoule 
  // be $clog2(m+1), where the "+1" is for credit returning packet.
  ,parameter tag_width_p = $clog2(ct_num_in_p+1)
  
  // bsg_link data width
  // MUST be multiple of (2*channel_width_p*num_channels_p) 
  ,parameter link_width_p = 32
  
  
  /*********************** Wormhole network params ***********************/
  
  // Wormhole flit width is narrower than link data width
  ,parameter flit_width_p = link_width_p - tag_width_p

  
  /*********************** Channel Tunnel params ***********************/
  
  // Number of available credits. There is a receive buffer (size equal to num of credits) 
  // on receiver side, when data dequeue from buffer, it returns credit to sender. 
  // If sender runs out of credit, it stalls.
  //
  // There is a round-trip delay between sender and receiver for credit returning
  // Must have large enough amount of credit to prevent stalling
  //
  ,parameter ct_remote_credits_p = 64
  
  // How often does channel tunnel return credits
  // If parameter is set to m, then channel tunnel will return credit to sender
  // after receiving 2^m wormhole flits.
  //
  // Generally we don't want to send credit too often (wasteful of IO bandwidth)
  // Receiving a quarter of packets before return credit is reasonable
  //
  ,parameter ct_credit_decimation_p    = ct_remote_credits_p/4
  
  // Smaller decimation means returning credit more frequently
  // Need to get smallest reasonable lg_decimation to prevent stalling
  ,parameter ct_lg_credit_decimation_p = $clog2(ct_credit_decimation_p/2+1)
  
  // Whether to use single 1rw memory as input buffer
  // Pseudo large fifo saves 1.7x hardware, but read / write bandwidth is halved
  // In this application we use pseudo fifo, because channel tunnel is not bottle-neck
  //
  // Proof of correctness:
  // Assume we run IO at frequency f_io, physical IO channel width is w_ch, number
  // of physical IO channels is num_ch, channel tunnel data width is w_ct, channel tunnel
  // run at frequency f_ct. In order to use pseudo large fifo without sacrificing 
  // performance, we should have:
  //
  //    f_ct >= f_io * (w_ch * num_ch / w_ct)
  //
  // For this application, it becomes f_ct >= 0.5*f_io, which is true most of the time.
  //
  ,parameter ct_use_pseudo_large_fifo_p = 1
  
  
  /*********************** DRR link params ***********************/
  
  // Physical IO link configuration
  ,parameter channel_width_p = 8
  
  // How many physical IO link channels do we have for each bsg_link
  ,parameter num_channels_p = 1
  
  // DDR Link buffer size
  // 6 should be good for 500MHz, increase if channel stalls waiting for token
  ,parameter lg_fifo_depth_p = 6
  
  // This is for token credit return on IO channel
  // Do not change
  ,parameter lg_credit_to_token_decimation_p = 3
  
  
  /*********************** Testbench Params ***********************/
  ,parameter top_utilization_p = 40
  ,parameter top_traffic_len_p = 1
  ,parameter top_is_fast_to_slow_p = 1
  
  ,parameter io_clk_p = 4
  ,parameter router_base_clk_p = 4
  ,parameter fast_clk_p = router_base_clk_p
  ,parameter slow_clk_p = router_base_clk_p*2
  
  ,parameter master_clk_p = top_is_fast_to_slow_p? fast_clk_p : slow_clk_p
  ,parameter client_clk_p = top_is_fast_to_slow_p? slow_clk_p : fast_clk_p
  ,parameter utilization_ratio_p = (link_width_p*ct_num_in_p)/(2*channel_width_p*num_channels_p)*(1+top_is_fast_to_slow_p)*io_clk_p/router_base_clk_p
  )
  
  ();
  
  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  
  // Router clock and reset
  logic router_clk_0, router_clk_1;
  logic router_reset_0, router_reset_1;
  logic router_en_0;
  
  // Link upstream and downstream core reset
  logic core_upstream_downstream_reset_0, core_upstream_downstream_reset_1;
  
  // Link upstream io clock and reset
  logic io_upstream_clk;
  logic io_upstream_reset;
  logic io_upstream_clk_0, io_upstream_clk_1;
  logic io_upstream_clk90_0, io_upstream_clk90_1;
  logic io_upstream_reset_0, io_upstream_reset_1;
  
  // Link upstream token async reset
  logic token_reset_0, token_reset_1;
  
  // Link downstream io reset
  logic [num_channels_p-1:0] io_downstream_reset_0, io_downstream_reset_1;
  
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] out_node_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] out_node_link_lo;
  
  logic [ct_num_in_p-1:0] out_ct_fifo_valid_lo, out_ct_fifo_yumi_li;
  logic [ct_num_in_p-1:0] out_ct_fifo_valid_li, out_ct_fifo_yumi_lo;
  logic [ct_num_in_p-1:0][flit_width_p-1:0] out_ct_fifo_data_lo, out_ct_fifo_data_li;
  
  logic out_ct_valid_lo, out_ct_ready_li; 
  logic out_ct_valid_li, out_ct_yumi_lo;
  logic [link_width_p-1:0] out_ct_data_lo, out_ct_data_li;
  
  logic [num_channels_p-1:0] edge_clk_0, edge_valid_0, edge_token_0;
  logic [num_channels_p-1:0][channel_width_p-1:0] edge_data_0;
  
  logic [num_channels_p-1:0] edge_clk_1, edge_valid_1, edge_token_1;
  logic [num_channels_p-1:0][channel_width_p-1:0] edge_data_1;
  
  logic in_ct_valid_lo, in_ct_ready_li;
  logic in_ct_valid_li, in_ct_yumi_lo;
  logic [link_width_p-1:0] in_ct_data_li, in_ct_data_lo;
  
  logic [ct_num_in_p-1:0] in_ct_fifo_valid_lo, in_ct_fifo_yumi_li;
  logic [ct_num_in_p-1:0] in_ct_fifo_valid_li, in_ct_fifo_yumi_lo;
  logic [ct_num_in_p-1:0][flit_width_p-1:0] in_ct_fifo_data_lo, in_ct_fifo_data_li;
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] in_node_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] in_node_link_lo;
  
  logic [ct_num_in_p-1:0] link_done_1;
  
  
  genvar i;

  for (i = 0; i < ct_num_in_p; i++)
  begin: master_node
    bsg_noc_performance_test_node_master
   #(.link_width_p(flit_width_p)
    ,.node_id_p(i)
    ,.utilization_p(top_utilization_p)
    ,.utilization_ratio_p(utilization_ratio_p)
    ,.len_p(top_traffic_len_p)
    ) out_node
    (.link_clk_i  (router_clk_0)
    ,.link_reset_i(router_reset_0)
    ,.link_en_i   (router_en_0)
   
    ,.link_i      (out_node_link_li[i])
    ,.link_o      (out_node_link_lo[i])
    );
  end
  
  for (i = 0; i < ct_num_in_p; i++) 
  begin: r0
    
    // Must add a fifo here, convert yumi_o to ready_o
    bsg_two_fifo
   #(.width_p(flit_width_p))
    out_ct_fifo
    (.clk_i  (router_clk_0  )
    ,.reset_i(router_reset_0)
    ,.ready_o(out_node_link_li[i].ready_and_rev)
    ,.data_i (out_node_link_lo[i].data         )
    ,.v_i    (out_node_link_lo[i].v            )
    ,.v_o    (out_ct_fifo_valid_lo[i])
    ,.data_o (out_ct_fifo_data_lo[i] )
    ,.yumi_i (out_ct_fifo_yumi_li[i] )
    );
    
    assign out_node_link_li   [i].v    = out_ct_fifo_valid_li[i];
    assign out_node_link_li   [i].data = out_ct_fifo_data_li [i];
    assign out_ct_fifo_yumi_lo[i]      = out_node_link_li    [i].v 
                                       & out_node_link_lo    [i].ready_and_rev;
  end

  bsg_channel_tunnel 
 #(.width_p                (flit_width_p)
  ,.num_in_p               (ct_num_in_p)
  ,.remote_credits_p       (ct_remote_credits_p)
  ,.use_pseudo_large_fifo_p(ct_use_pseudo_large_fifo_p)
  ,.lg_credit_decimation_p (ct_lg_credit_decimation_p)
  )
  out_ct
  (.clk_i  (router_clk_0)
  ,.reset_i(router_reset_0)

  // incoming multiplexed data
  ,.multi_data_i(out_ct_data_li)
  ,.multi_v_i   (out_ct_valid_li)
  ,.multi_yumi_o(out_ct_yumi_lo)

  // outgoing multiplexed data
  ,.multi_data_o(out_ct_data_lo)
  ,.multi_v_o   (out_ct_valid_lo)
  ,.multi_yumi_i(out_ct_ready_li & out_ct_valid_lo)

  // incoming demultiplexed data
  ,.data_i(out_ct_fifo_data_lo)
  ,.v_i   (out_ct_fifo_valid_lo)
  ,.yumi_o(out_ct_fifo_yumi_li)

  // outgoing demultiplexed data
  ,.data_o(out_ct_fifo_data_li)
  ,.v_o   (out_ct_fifo_valid_li)
  ,.yumi_i(out_ct_fifo_yumi_lo)
  );

  if (top_is_fast_to_slow_p)
  begin: f2s
  
    assign io_upstream_clk_0 = io_upstream_clk;
    always @(posedge io_upstream_clk) if (io_upstream_reset) io_upstream_clk_1 <= 1'b0; else io_upstream_clk_1 <= ~io_upstream_clk_1;
    always @(negedge io_upstream_clk) if (io_upstream_reset) io_upstream_clk90_1 <= 1'b0; else io_upstream_clk90_1 <= ~io_upstream_clk90_1;
  
  bsg_link_ddr_upstream
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_upstream_0
  (.core_clk_i         (router_clk_0)
  ,.io_clk_i           (io_upstream_clk_0)
  ,.core_link_reset_i  (core_upstream_downstream_reset_0)
  ,.io_link_reset_i    (io_upstream_reset_0)
  ,.async_token_reset_i(token_reset_0)
  
  ,.core_data_i (out_ct_data_lo)
  ,.core_valid_i(out_ct_valid_lo)
  ,.core_ready_o(out_ct_ready_li)

  ,.io_clk_r_o  (edge_clk_0)
  ,.io_data_r_o (edge_data_0)
  ,.io_valid_r_o(edge_valid_0)
  ,.token_clk_i (edge_token_0)
  );
  
  bsg_link_ddr_upstream_hard
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_upstream_1
  (.core_clk_i         (router_clk_1)
  ,.io_clk_i           (io_upstream_clk_1)
  ,.io_clk90_i         (io_upstream_clk90_1)
  ,.core_link_reset_i  (core_upstream_downstream_reset_1)
  ,.io_link_reset_i    (io_upstream_reset_1)
  ,.async_token_reset_i(token_reset_1)
  
  ,.core_data_i (in_ct_data_lo)
  ,.core_valid_i(in_ct_valid_lo)
  ,.core_ready_o(in_ct_ready_li)

  ,.io_clk_r_o  (edge_clk_1)
  ,.io_data_r_o (edge_data_1)
  ,.io_valid_r_o(edge_valid_1)
  ,.token_clk_i (edge_token_1)
  );
  
  end
  else
  begin: s2f
  
    assign io_upstream_clk_1 = io_upstream_clk;
    always @(posedge io_upstream_clk) if (io_upstream_reset) io_upstream_clk_0 <= 1'b0; else io_upstream_clk_0 <= ~io_upstream_clk_0;
    always @(negedge io_upstream_clk) if (io_upstream_reset) io_upstream_clk90_0 <= 1'b0; else io_upstream_clk90_0 <= ~io_upstream_clk90_0;
    
  bsg_link_ddr_upstream_hard
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_upstream_0
  (.core_clk_i         (router_clk_0)
  ,.io_clk_i           (io_upstream_clk_0)
  ,.io_clk90_i         (io_upstream_clk90_0)
  ,.core_link_reset_i  (core_upstream_downstream_reset_0)
  ,.io_link_reset_i    (io_upstream_reset_0)
  ,.async_token_reset_i(token_reset_0)
  
  ,.core_data_i (out_ct_data_lo)
  ,.core_valid_i(out_ct_valid_lo)
  ,.core_ready_o(out_ct_ready_li)

  ,.io_clk_r_o  (edge_clk_0)
  ,.io_data_r_o (edge_data_0)
  ,.io_valid_r_o(edge_valid_0)
  ,.token_clk_i (edge_token_0)
  );
  
  bsg_link_ddr_upstream
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_upstream_1
  (.core_clk_i         (router_clk_1)
  ,.io_clk_i           (io_upstream_clk_1)
  ,.core_link_reset_i  (core_upstream_downstream_reset_1)
  ,.io_link_reset_i    (io_upstream_reset_1)
  ,.async_token_reset_i(token_reset_1)
  
  ,.core_data_i (in_ct_data_lo)
  ,.core_valid_i(in_ct_valid_lo)
  ,.core_ready_o(in_ct_ready_li)

  ,.io_clk_r_o  (edge_clk_1)
  ,.io_data_r_o (edge_data_1)
  ,.io_valid_r_o(edge_valid_1)
  ,.token_clk_i (edge_token_1)
  );
  
  end
  
  bsg_link_ddr_downstream
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_downstream_0
  (.core_clk_i       (router_clk_0)
  ,.core_link_reset_i(core_upstream_downstream_reset_0)
  ,.io_link_reset_i  (io_downstream_reset_0)
  
  ,.core_data_o   (out_ct_data_li)
  ,.core_valid_o  (out_ct_valid_li)
  ,.core_yumi_i   (out_ct_yumi_lo)

  ,.io_clk_i      (edge_clk_1)
  ,.io_data_i     (edge_data_1)
  ,.io_valid_i    (edge_valid_1)
  ,.core_token_r_o(edge_token_1)
  );
  
  bsg_link_ddr_downstream
 #(.width_p        (link_width_p)
  ,.channel_width_p(channel_width_p)
  ,.num_channels_p (num_channels_p)
  ,.lg_fifo_depth_p(lg_fifo_depth_p)
  ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
  ) link_downstream_1
  (.core_clk_i       (router_clk_1)
  ,.core_link_reset_i(core_upstream_downstream_reset_1)
  ,.io_link_reset_i  (io_downstream_reset_1)
  
  ,.core_data_o   (in_ct_data_li)
  ,.core_valid_o  (in_ct_valid_li)
  ,.core_yumi_i   (in_ct_yumi_lo)
  
  ,.io_clk_i      (edge_clk_0)
  ,.io_data_i     (edge_data_0)
  ,.io_valid_i    (edge_valid_0)
  ,.core_token_r_o(edge_token_0)
  );
  

  bsg_channel_tunnel 
 #(.width_p                (flit_width_p)
  ,.num_in_p               (ct_num_in_p)
  ,.remote_credits_p       (ct_remote_credits_p)
  ,.use_pseudo_large_fifo_p(ct_use_pseudo_large_fifo_p)
  ,.lg_credit_decimation_p (ct_lg_credit_decimation_p)
  )
  in_ct
  (.clk_i  (router_clk_1)
  ,.reset_i(router_reset_1)

  // incoming multiplexed data
  ,.multi_data_i(in_ct_data_li)
  ,.multi_v_i   (in_ct_valid_li)
  ,.multi_yumi_o(in_ct_yumi_lo)

  // outgoing multiplexed data
  ,.multi_data_o(in_ct_data_lo)
  ,.multi_v_o   (in_ct_valid_lo)
  ,.multi_yumi_i(in_ct_ready_li & in_ct_valid_lo)

  // incoming demultiplexed data
  ,.data_i(in_ct_fifo_data_lo)
  ,.v_i   (in_ct_fifo_valid_lo)
  ,.yumi_o(in_ct_fifo_yumi_li)

  // outgoing demultiplexed data
  ,.data_o(in_ct_fifo_data_li)
  ,.v_o   (in_ct_fifo_valid_li)
  ,.yumi_i(in_ct_fifo_yumi_lo)
  );
  
  for (i = 0; i < ct_num_in_p; i++) 
  begin: r1
    
    // Must add a fifo here, convert yumi_o to ready_o
    bsg_two_fifo
   #(.width_p(flit_width_p))
    in_ct_fifo
    (.clk_i  (router_clk_1  )
    ,.reset_i(router_reset_1)
    ,.ready_o(in_node_link_li[i].ready_and_rev)
    ,.data_i (in_node_link_lo[i].data         )
    ,.v_i    (in_node_link_lo[i].v            )
    ,.v_o    (in_ct_fifo_valid_lo[i])
    ,.data_o (in_ct_fifo_data_lo[i] )
    ,.yumi_i (in_ct_fifo_yumi_li[i] )
    );
    
    assign in_node_link_li   [i].v    = in_ct_fifo_valid_li[i];
    assign in_node_link_li   [i].data = in_ct_fifo_data_li [i];
    assign in_ct_fifo_yumi_lo[i]      = in_node_link_li    [i].v 
                                      & in_node_link_lo    [i].ready_and_rev;
  end

  for (i = 0; i < ct_num_in_p; i++)
  begin: client_node
    bsg_noc_performance_test_node_client
   #(.link_width_p(flit_width_p)
    ,.node_id_p   (i)
    ,.clk_period_p(slow_clk_p<<1)
    ) in_node
    (.link_clk_i  (router_clk_1)
    ,.link_reset_i(router_reset_1)
    ,.link_done_o (link_done_1[i])
   
    ,.link_i      (in_node_link_li[i])
    ,.link_o      (in_node_link_lo[i])
    );
  end
  

  // Simulation of Clock
  always #(master_clk_p) router_clk_0 = ~router_clk_0;
  always #(client_clk_p) router_clk_1 = ~router_clk_1;
  always #(io_clk_p    ) io_upstream_clk = ~io_upstream_clk;
  
  always_ff @(posedge router_clk_1)
  begin
    if (~router_reset_1 && (& link_done_1))
      begin
        $display("\nTest Finished\n");
        $finish;
      end
  end
  
  integer j;
  
  initial
  begin

    $display("Start Simulation\n");
  
    // Init
    router_clk_0        = 0;
    router_clk_1        = 0;
    io_upstream_clk     = 0;
    
    io_upstream_reset   = 1;
    io_upstream_reset_0 = 1;
    io_upstream_reset_1 = 1;
    token_reset_0 = 0;
    token_reset_1 = 0;
    
    core_upstream_downstream_reset_0 = 1;
    core_upstream_downstream_reset_1 = 1;
    router_reset_0 = 1;
    router_reset_1 = 1;
    router_en_0 = 0;
    
    #1000;
    
    @(posedge io_upstream_clk);
    io_upstream_reset = 0;
    
    #1000;
    
    // token async reset
    token_reset_0 = 1;
    token_reset_1 = 1;
    
    #1000;
    
    token_reset_0 = 0;
    token_reset_1 = 0;
    
    #1000;
    
    // upstream io reset
    @(posedge io_upstream_clk_0); #1;
    io_upstream_reset_0 = 0;
    @(posedge io_upstream_clk_1); #1;
    io_upstream_reset_1 = 0;
    
    #1000;
    
    // Reset signals propagate to downstream after io_clk is generated
    for (j = 0; j < num_channels_p; j++)
      begin
        @(posedge edge_clk_1[j]); #1;
        io_downstream_reset_0[j] = 1;
        @(posedge edge_clk_0[j]); #1;
        io_downstream_reset_1[j] = 1;
      end
      
    #1000;
    
    // downstream IO reset
    // edge clock 0 to downstream 1, edge clock 1 to downstream 0
    for (j = 0; j < num_channels_p; j++)
      begin
        @(posedge edge_clk_1[j]); #1;
        io_downstream_reset_0[j] = 0;
        @(posedge edge_clk_0[j]); #1;
        io_downstream_reset_1[j] = 0;
      end
    
    #1000;
    
    // core link reset
    @(posedge router_clk_0); #1;
    core_upstream_downstream_reset_0 = 0;
    @(posedge router_clk_1); #1;
    core_upstream_downstream_reset_1 = 0;
    
    #1000;
    
    // chip reset
    @(posedge router_clk_0); #1;
    router_reset_0 = 0;
    @(posedge router_clk_1); #1;
    router_reset_1 = 0;
    
    #1000;
    
    // node enable
    @(posedge router_clk_0); #1;
    router_en_0 = 1;
    
  end

endmodule

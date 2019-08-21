
//
// Paul Gao 06/2019
//
// This is a tester for wormhole network and bsg_link.
// Two manycore loopback nodes send out packets, then receive the looped back packets.
// Correctness are checked automatically.
//
//

`timescale 1ps/1ps

module bsg_wormhole_network_tester

  import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (local node)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south
  
  // wormhole routing matrix
  import bsg_wormhole_router_pkg::StrictX;

 #(
 
  /*********************** Loopback test node params ***********************/

  // Loopback test node configuration
   parameter node_num_channels_p = 3
  
  
  /*********************** Fundamental params ***********************/
  
  // How many streams of traffic are merged in channel tunnel
  // In this testbench the number of traffics is 2 (req and resp traffic)
  ,parameter ct_num_in_p = 2
  
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
  
  // We do 1D routing here
  ,parameter dims_p = 1
  
  // This is the wormhole router coordinate marker
  //
  // Example of 1D routing: marker_p = '{b, a}
  // x_cord = marker_p[b-1:a], cord_width = b-a.
  //
  // Example of 2D routing: marker_p = '{c, b, a}
  // x_cord = marker_p[b-1:a], x_cord_width = b-a.
  // y_cord = marker_p[c-1:b], y_cord_width = c-b.
  //                             cord_width = c-a.
  //
  // Coordinate passed into each module is represented by cord_width'(cord).
  // Child module use dims_p and cord_marker_pos_p to extract hidden information.
  //
  ,parameter int cord_markers_pos_p[dims_p:0] = '{4, 0}
  
  // Routing matrix that chooses which routing directions are enabled
  // Must use StrictX for 1D routing
  // StrictX directions: P->W, P->E, P->P, W->E, W->P, E->W, E->P
  //
  ,parameter dirs_p = dims_p*2+1
  ,parameter bit [1:0][dirs_p-1:0][dirs_p-1:0] routing_matrix_p = StrictX
  
  // How many bits are used to represent wormhole packet length
  // Length is represented by number of payload flits in each packet
  // len_width should be determined by max possiblt packet length
  //
  // In this testbench, max possible number of payload flit is 2 (manycore req)
  // Max possible total flits is (max_payload_flit+1)
  // Then len_width = `BSG_SAFE_CLOG2(max_payload_flit+1)
  //
  ,parameter len_width_p = `BSG_SAFE_CLOG2(2+1)
  
  
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
  
  )
  
  ();
  
  // This localparam should be defined in each module that handles wormhole
  localparam cord_width_lp = cord_markers_pos_p[dims_p];
  
  // Loopback test specific parameters
  localparam out_node_cord = 2;
  localparam in_node_cord  = 3;
  
  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  
  // Loopback node control
  logic en_0, en_1;
  logic error_0, error_1;
  logic [31:0] sent_0, sent_1;
  logic [31:0] received_0, received_1;
  
  // Router clock and reset
  logic router_clk_0, router_clk_1;
  logic router_reset_0, router_reset_1;
  
  // Link upstream and downstream core reset
  logic core_upstream_downstream_reset_0, core_upstream_downstream_reset_1;
  
  // Link upstream io clock and reset
  logic io_upstream_clk_0, io_upstream_clk_1;
  logic io_upstream_reset_0, io_upstream_reset_1;
  
  // Link upstream token async reset
  logic token_reset_0, token_reset_1;
  
  // Link downstream io reset
  logic [num_channels_p-1:0] io_downstream_reset_0, io_downstream_reset_1;
  
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] out_node_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] out_node_link_lo;
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0][dirs_p-1:0] out_router_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0][dirs_p-1:0] out_router_link_lo;
  
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
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0][dirs_p-1:0] in_router_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0][dirs_p-1:0] in_router_link_lo;
  
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] in_node_link_li;
  bsg_ready_and_link_sif_s [ct_num_in_p-1:0] in_node_link_lo;
  
  
  genvar i;


  bsg_wormhole_router_test_node_master
 #(.flit_width_p(flit_width_p)
  ,.dims_p(dims_p)
  ,.cord_markers_pos_p(cord_markers_pos_p)
  ,.len_width_p(len_width_p)
  ,.num_channels_p(node_num_channels_p)
  ,.channel_width_p(channel_width_p)
  ) out_node
  (.clk_i           (router_clk_0)
  ,.reset_i         (router_reset_0)
  ,.en_i            ({en_1, en_0})
  
  ,.error_o         ({error_1, error_0})
  ,.sent_o          ({sent_1, sent_0})
  ,.received_o      ({received_1, received_0})

  ,.dest_cord_i     (cord_width_lp'(in_node_cord))
  
  ,.link_i          (out_node_link_li)
  ,.link_o          (out_node_link_lo)
  );
  
  
  for (i = 0; i < ct_num_in_p; i++) 
  begin: r0
  
    bsg_wormhole_router
   #(.flit_width_p      (flit_width_p)
    ,.dims_p            (dims_p)
    ,.cord_markers_pos_p(cord_markers_pos_p)
    ,.routing_matrix_p  (routing_matrix_p)
    ,.len_width_p       (len_width_p)
    )
    router_0
    (.clk_i    (router_clk_0)
	,.reset_i  (router_reset_0)
	,.my_cord_i(cord_width_lp'(out_node_cord))
	,.link_i   (out_router_link_li[i])
	,.link_o   (out_router_link_lo[i])
	);

    assign out_node_link_li[i] = out_router_link_lo[i][P];
    assign out_router_link_li[i][P] = out_node_link_lo[i];
    
    // Stub
    assign out_router_link_li[i][W].v             = 1'b0;
    assign out_router_link_li[i][W].ready_and_rev = 1'b1;
    
    // Must add a fifo here, convert yumi_o to ready_o
    bsg_two_fifo
   #(.width_p(flit_width_p))
    out_ct_fifo
    (.clk_i  (router_clk_0  )
    ,.reset_i(router_reset_0)
    ,.ready_o(out_router_link_li[i][E].ready_and_rev)
    ,.data_i (out_router_link_lo[i][E].data         )
    ,.v_i    (out_router_link_lo[i][E].v            )
    ,.v_o    (out_ct_fifo_valid_lo[i])
    ,.data_o (out_ct_fifo_data_lo[i] )
    ,.yumi_i (out_ct_fifo_yumi_li[i] )
    );
    
    assign out_router_link_li [i][E].v    = out_ct_fifo_valid_li[i];
    assign out_router_link_li [i][E].data = out_ct_fifo_data_li [i];
    assign out_ct_fifo_yumi_lo[i]         = out_router_link_li  [i][E].v 
                                          & out_router_link_lo  [i][E].ready_and_rev;
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
  
    bsg_wormhole_router
   #(.flit_width_p      (flit_width_p)
    ,.dims_p            (dims_p)
    ,.cord_markers_pos_p(cord_markers_pos_p)
    ,.routing_matrix_p  (routing_matrix_p)
    ,.len_width_p       (len_width_p)
    ) 
    router_1
    (.clk_i    (router_clk_1)
	,.reset_i  (router_reset_1)
	,.my_cord_i(cord_width_lp'(in_node_cord))
	,.link_i   (in_router_link_li[i])
	,.link_o   (in_router_link_lo[i])
	);
    
    assign in_node_link_li[i] = in_router_link_lo[i][P];
    assign in_router_link_li[i][P] = in_node_link_lo[i];
    
    // Stub
    assign in_router_link_li[i][E].v             = 1'b0;
    assign in_router_link_li[i][E].ready_and_rev = 1'b1;
    
    // Must add a fifo here, convert yumi_o to ready_o
    bsg_two_fifo
   #(.width_p(flit_width_p))
    in_ct_fifo
    (.clk_i  (router_clk_1  )
    ,.reset_i(router_reset_1)
    ,.ready_o(in_router_link_li[i][W].ready_and_rev)
    ,.data_i (in_router_link_lo[i][W].data         )
    ,.v_i    (in_router_link_lo[i][W].v            )
    ,.v_o    (in_ct_fifo_valid_lo[i])
    ,.data_o (in_ct_fifo_data_lo[i] )
    ,.yumi_i (in_ct_fifo_yumi_li[i] )
    );
    
    assign in_router_link_li [i][W].v    = in_ct_fifo_valid_li[i];
    assign in_router_link_li [i][W].data = in_ct_fifo_data_li [i];
    assign in_ct_fifo_yumi_lo[i]         = in_router_link_li  [i][W].v 
                                         & in_router_link_lo  [i][W].ready_and_rev;
  end

  bsg_wormhole_router_test_node_client
 #(.flit_width_p(flit_width_p)
  ,.dims_p(dims_p)
  ,.cord_markers_pos_p(cord_markers_pos_p)
  ,.len_width_p(len_width_p)
  ) in_node
  (.clk_i           (router_clk_1)
  ,.reset_i         (router_reset_1)

  ,.dest_cord_i     (cord_width_lp'(out_node_cord))
  
  ,.link_i          (in_node_link_li)
  ,.link_o          (in_node_link_lo)
  );
  

  // Simulation of Clock
  always #3 router_clk_0 = ~router_clk_0;
  always #3 router_clk_1 = ~router_clk_1;
  always #2 io_upstream_clk_0 = ~io_upstream_clk_0;
  always #3 io_upstream_clk_1 = ~io_upstream_clk_1;
  
  integer j;
  
  initial
  begin

    $display("Start Simulation\n");
  
    // Init
    router_clk_0 = 1;
    router_clk_1 = 1;
    io_upstream_clk_0     = 1;
    io_upstream_clk_1     = 1;
    
    io_upstream_reset_0 = 1;
    io_upstream_reset_1 = 1;
    token_reset_0 = 0;
    token_reset_1 = 0;
    
    core_upstream_downstream_reset_0 = 1;
    core_upstream_downstream_reset_1 = 1;
    router_reset_0 = 1;
    router_reset_1 = 1;
    
    en_0 = 0;
    en_1 = 0;
    
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
    
    #100;
    
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
    
    #1000
    
    // chip reset
    @(posedge router_clk_0); #1;
    router_reset_0 = 0;
    @(posedge router_clk_1); #1;
    router_reset_1 = 0;
    
    #1000
    
    // mc enable
    @(posedge router_clk_0); #1;
    en_0 = 1;
    en_1 = 1;
    
    #50000
    
    // mc disable
    @(posedge router_clk_0); #1;
    en_0 = 0;
    en_1 = 0;
    
    #5000
    
    
    assert(error_0 == 0)
    else 
      begin
        $error("\nFAIL... Error in loopback node 0\n");
        $finish;
      end
    
    assert(error_1 == 0)
    else 
      begin
        $error("\nFAIL... Error in loopback node 1\n");
        $finish;
      end
    
    assert(sent_0 == received_0)
    else 
      begin
        $error("\nFAIL... Loopback node 0 sent %d packets but received only %d\n", sent_0, received_0);
        $finish;
      end
    
    assert(sent_1 == received_1)
    else 
      begin
        $error("\nFAIL... Loopback node 1 sent %d packets but received only %d\n", sent_1, received_1);
        $finish;
      end
    
    $display("\nPASS!\n");
    $display("Loopback node 0 sent and received %d packets\n", sent_0);
    $display("Loopback node 1 sent and received %d packets\n", sent_1);
    $finish;
    
  end

endmodule

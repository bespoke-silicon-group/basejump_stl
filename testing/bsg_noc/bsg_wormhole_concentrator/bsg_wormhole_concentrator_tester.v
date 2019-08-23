
//
// Paul Gao 06/2019
//
//

`timescale 1ps/1ps
`include "bsg_noc_links.vh"

module bsg_wormhole_concentrator_tester
  
  import bsg_noc_pkg::*;
  import bsg_wormhole_router_pkg::*;

 #(
  // Change this one to test 1d / 2d routing
   parameter dims_p = 2
  // By default it routes dimension 0 first, set to 1 to route dimension n first
  ,parameter reverse_order_p = 0
   
  // Determine length of fwd and rev packets
  ,parameter node_num_channels_p = 8
  ,parameter channel_width_p = 8
  
  ,parameter x_marker_p = 4
  ,parameter y_marker_p = 8
  ,parameter x_width_p = x_marker_p
  ,parameter y_width_p = y_marker_p - x_marker_p
  ,parameter int cord_markers_pos_full_p[2:0] = '{y_marker_p, x_marker_p, 0}
  
  // Wormhole parameters
  ,parameter flit_width_p = 32
  // Payload flit number
  ,parameter len_width_p  = 4
  // number of traffice to be concentrated
  ,parameter num_in_p     = 3
  // concentration id width, depends on num_in_p
  ,parameter cid_width_p  = `BSG_SAFE_CLOG2(num_in_p)
  
  ,parameter dirs_p = dims_p*2+1
  ,parameter int cord_markers_pos_p[dims_p:0] = cord_markers_pos_full_p[dims_p:0]
  ,parameter bit [1:0][dirs_p-1:0][dirs_p-1:0] routing_matrix_p = 
                                (dims_p == 1)? StrictX
                                             : StrictXY|XY_Allow_S|XY_Allow_N
  
  ,parameter cord_width_p = cord_markers_pos_p[dims_p]
  )
  
  ();

  `declare_bsg_ready_and_link_sif_s(flit_width_p,bsg_ready_and_link_sif_s);
  
  // Clocks and control signals
  logic node_clk;
  logic node_reset;
  logic clk;
  logic reset;
  
  logic [num_in_p-1:0] node_en;
  logic [num_in_p-1:0] error;
  logic [num_in_p-1:0][31:0] sent, received;
  
  logic [num_in_p-1:0][cid_width_p-1:0] dest_cid;
  
  bsg_ready_and_link_sif_s [num_in_p-1:0] master_node_link_li;
  bsg_ready_and_link_sif_s [num_in_p-1:0] master_node_link_lo;
  
  bsg_ready_and_link_sif_s master_concentrated_link_li;
  bsg_ready_and_link_sif_s master_concentrated_link_lo;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] master_router_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] master_router_link_lo;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] client_router_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] client_router_link_lo;
  
  bsg_ready_and_link_sif_s client_concentrated_link_li;
  bsg_ready_and_link_sif_s client_concentrated_link_lo;
  
  bsg_ready_and_link_sif_s [num_in_p-1:0] client_node_link_li;
  bsg_ready_and_link_sif_s [num_in_p-1:0] client_node_link_lo;
  
  logic [cord_width_p-1:0] master_cord, client_cord;
  assign master_cord = (cord_width_p)'(6);
  assign client_cord = (cord_width_p)'(7);
  
  genvar i;

  for (i = 0; i < num_in_p; i++) 
  begin: master
    bsg_wormhole_concentrator_test_node
   #(.flit_width_p(flit_width_p)
    ,.cord_width_p(cord_markers_pos_p[dims_p])
    ,.len_width_p(len_width_p)
    ,.cid_width_p(cid_width_p)
    
    ,.num_channels_p(node_num_channels_p)
    ,.channel_width_p(channel_width_p)
    ,.is_client_node_p(0)
    ) node
    (.node_clk_i  (node_clk)
    ,.node_reset_i(node_reset)
    ,.node_en_i   (node_en[i])
    
    ,.error_o   (error[i])
    ,.sent_o    (sent[i])
    ,.received_o(received[i])
     
    ,.clk_i   (clk)
    ,.reset_i (reset)
    
    ,.my_cord_i(master_cord)
    ,.dest_cord_i(client_cord)
    
    ,.my_cid_i((cid_width_p)'(i))
    ,.dest_cid_i(dest_cid[i])
    
    ,.link_i(master_node_link_li[i])
    ,.link_o(master_node_link_lo[i])
    );
  end
  
  bsg_wormhole_concentrator
  #(.flit_width_p(flit_width_p)
   ,.num_in_p(num_in_p)
   ,.cord_width_p(cord_markers_pos_p[dims_p])
   ,.len_width_p(len_width_p)
   ,.cid_width_p(cid_width_p)
   ) master_concentrator
  (.clk_i(clk)
  ,.reset_i(reset)

  // unconcentrated side
  ,.links_i(master_node_link_lo)
  ,.links_o(master_node_link_li)

  // concentrated side
  ,.concentrated_link_i(master_concentrated_link_li)
  ,.concentrated_link_o(master_concentrated_link_lo)
  );

   bsg_wormhole_router
     #(.flit_width_p(flit_width_p)
       ,.dims_p(dims_p)
       ,.cord_markers_pos_p(cord_markers_pos_p)
       ,.routing_matrix_p(routing_matrix_p)
       ,.reverse_order_p(reverse_order_p)
       ,.len_width_p(len_width_p)
       ) wr_master
       (.clk_i(clk)
	,.reset_i(reset)
	,.my_cord_i(master_cord)
	,.link_i(master_router_link_li)
	,.link_o(master_router_link_lo)
	);
    
   always_comb
    begin
        master_router_link_li = '0;
        client_router_link_li = '0;
        
        master_concentrated_link_li = master_router_link_lo[P];
        master_router_link_li[P] = master_concentrated_link_lo;
        
        master_router_link_li[E] = client_router_link_lo[W];
        client_router_link_li[W] = master_router_link_lo[E];
        
        client_concentrated_link_li = client_router_link_lo[P];
        client_router_link_li[P] = client_concentrated_link_lo;
    end

   bsg_wormhole_router
     #(.flit_width_p(flit_width_p)
       ,.dims_p(dims_p)
       ,.cord_markers_pos_p(cord_markers_pos_p)
       ,.routing_matrix_p(routing_matrix_p)
       ,.reverse_order_p(reverse_order_p)
       ,.len_width_p(len_width_p)
       ) wr_client
       (.clk_i(clk)
	,.reset_i(reset)
	,.my_cord_i(client_cord)
	,.link_i(client_router_link_li)
	,.link_o(client_router_link_lo)
	);
    
  bsg_wormhole_concentrator
  #(.flit_width_p(flit_width_p)
   ,.num_in_p(num_in_p)
   ,.cord_width_p(cord_markers_pos_p[dims_p])
   ,.len_width_p(len_width_p)
   ,.cid_width_p(cid_width_p)
   ) client_concentrator
  (.clk_i(clk)
  ,.reset_i(reset)

  // unconcentrated side
  ,.links_i(client_node_link_lo)
  ,.links_o(client_node_link_li)

  // concentrated side
  ,.concentrated_link_i(client_concentrated_link_li)
  ,.concentrated_link_o(client_concentrated_link_lo)
  );
  
  for (i = 0; i < num_in_p; i++) 
  begin: client
    bsg_wormhole_concentrator_test_node
   #(.flit_width_p(flit_width_p)
    ,.cord_width_p(cord_markers_pos_p[dims_p])
    ,.len_width_p(len_width_p)
    ,.cid_width_p(cid_width_p)
    
    ,.num_channels_p(node_num_channels_p)
    ,.channel_width_p(channel_width_p)
    ,.is_client_node_p(1)
    ) node
    (.node_clk_i  (node_clk)
    ,.node_reset_i(node_reset)
    ,.node_en_i   (1'b0)
    
    ,.error_o   ()
    ,.sent_o    ()
    ,.received_o()
     
    ,.clk_i   (clk)
    ,.reset_i (reset)
    
    ,.my_cord_i(client_cord)
    ,.dest_cord_i(master_cord)
    
    ,.my_cid_i((cid_width_p)'(i))
    ,.dest_cid_i('0)
    
    ,.link_i(client_node_link_li[i])
    ,.link_o(client_node_link_lo[i])
    );
  end

  integer j, k, m, n, idx;
   
  // Simulation of Clock
  always #3 clk = ~clk;
  always #4 node_clk = ~node_clk;
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    clk = 1;
    node_clk = 1;
    reset = 1;
    node_reset = 1;
    node_en = '0;
    
    for (j = 0; j < num_in_p; j++)
      begin
        dest_cid[j] = j;
      end
    
    #500;
    
    // chip reset
    @(posedge clk); #1;
    reset = 0;
    $display("chip reset LOW"); 
    #500;
    
    // node reset
    @(posedge node_clk); #1;
    node_reset = 0;
     $display("node reset LOW");
    #500;
    
    
     $display("single direction test");     
    
    for (k = 0; k < num_in_p; k++)
      begin
        
        for (j = 0; j < num_in_p; j++)
          begin
            dest_cid[j] = (j+k)%num_in_p;
            #500;
            
            // node enable
            @(posedge node_clk); #1;
            node_en[j] = 1'b1;
            $display("node en HI");
            
            #10000;
            
            // node disable
            @(posedge node_clk); #1;
            node_en[j] = 1'b0;
            $display("node en LO");
            #2000;
          end
        
      end
    

     $display("multi directions test");     
    
    for (k = 0; k < num_in_p; k++)
      begin
        
        for (j = 0; j < num_in_p; j++)
          begin
            dest_cid[j] = (j+k)%num_in_p;
          end
        
        #500;
        
        // node enable
        @(posedge node_clk); #1;
        node_en = '1;
	    $display("node en HI");
        
        #10000;
        
        // node disable
        @(posedge node_clk); #1;
        node_en = '0;
	    $display("node en LO");        
        #2000;
        
      end

    
     $display("congestion test");    
    
    for (k = 0; k < num_in_p; k++)
      begin
        
        for (j = 0; j < num_in_p; j++)
          begin
            dest_cid[j] = k;
          end
        
        #500;
        
        // node enable
        @(posedge node_clk); #1;
        node_en = '1;
	    $display("node en HI");
        
        #10000;
        
        // node disable
        @(posedge node_clk); #1;
        node_en = '0;
	    $display("node en LO");        
        #5000;
        
      end
       
    
    for (j = 0; j < num_in_p; j++)
      begin
        assert(error[j] == 0)
        else 
          begin
            $error("\nFAIL... Error in loopback node %d\n", j);
            $finish;
          end
        
        assert(sent[j] == received[j])
        else 
          begin
            $error("\nFAIL... Loopback node %d sent %d packets but received only %d\n", j, sent[j], received[j]);
            $finish;
          end
      end
    
    $display("\nPASS!\n");
    
    for (j = 0; j < num_in_p; j++)
      begin
        $display("Loopback node %d sent and received %d packets\n", j, sent[j]);
      end
    
    $finish;
    
  end

endmodule

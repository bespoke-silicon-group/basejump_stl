
//
// Paul Gao 06/2019
//
//

`timescale 1ps/1ps
`include "bsg_noc_links.vh"

module bsg_wormhole_router_tester

  import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (local node)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south
       
  import bsg_wormhole_router_pkg::StrictXY
       , bsg_wormhole_router_pkg::StrictYX
       , bsg_wormhole_router_pkg::StrictX
       , bsg_wormhole_router_pkg::X_AllowLoopBack
       , bsg_wormhole_router_pkg::XY_Allow_S
       , bsg_wormhole_router_pkg::XY_Allow_N
       , bsg_wormhole_router_pkg::YX_Allow_W
       , bsg_wormhole_router_pkg::YX_Allow_E;

 #(
  // Change this one to test 1d / 2d routing
   parameter dims_p = 2
  // By default it routes dimension 0 first, set to 1 to route dimension n first
  ,parameter reverse_order_p = 0
   
  // Determine length of fwd and rev packets
  ,parameter mc_node_fwd_num_channels_p = 15
  ,parameter mc_node_rev_num_channels_p = 7
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
  logic mc_clk;
  logic mc_reset;
  logic clk;
  logic reset;
  
  logic [dirs_p-1:0] mc_en;
  logic [dirs_p-1:0] mc_error;
  logic [dirs_p-1:0][31:0] sent, received;
  
  logic [dirs_p-1:0][cord_width_p-1:0] my_cord, dest_cord;
  logic [dirs_p-1:0][y_marker_p-1:0] my_cord_full, dest_cord_full;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] fwd_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] fwd_link_lo;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] rev_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] rev_link_lo;
  
  genvar i;

  for (i = 0; i < dirs_p; i++) 
  begin : test_node_dir
    bsg_wormhole_router_test_node
   #(.flit_width_p(flit_width_p)
    ,.dims_p(dims_p)
    ,.cord_markers_pos_p(cord_markers_pos_p)
    ,.reverse_order_p(reverse_order_p)
    ,.len_width_p(len_width_p)
    ,.node_idx(i)
    
    ,.fwd_num_channels_p(mc_node_fwd_num_channels_p)
    ,.rev_num_channels_p(mc_node_rev_num_channels_p)
    ,.channel_width_p(channel_width_p)
    ) node_0
    (.mc_clk_i  (mc_clk)
    ,.mc_reset_i(mc_reset)
    ,.mc_en_i   (mc_en[i])
    
    ,.error_o   (mc_error[i])
    ,.sent_o    (sent[i])
    ,.received_o(received[i])
     
    ,.clk_i   (clk)
    ,.reset_i (reset)
    
    ,.my_cord_i(my_cord[i])
    ,.dest_cord_i(dest_cord[i])
    
    ,.link_i({fwd_link_lo[i], rev_link_lo[i]})
    ,.link_o({fwd_link_li[i], rev_link_li[i]})
    );
  end

   bsg_wormhole_router
     #(.flit_width_p(flit_width_p)
       ,.dims_p(dims_p)
       ,.cord_markers_pos_p(cord_markers_pos_p)
       ,.routing_matrix_p(routing_matrix_p)
       ,.reverse_order_p(reverse_order_p)
       ,.len_width_p(len_width_p)
       ) wr_fwd
       (.clk_i(clk)
	,.reset_i(reset)
	,.my_cord_i(my_cord[P])
	,.link_i(fwd_link_li)
	,.link_o(fwd_link_lo)
	);

   bsg_wormhole_router
     #(.flit_width_p(flit_width_p)
       ,.dims_p(dims_p)
       ,.cord_markers_pos_p(cord_markers_pos_p)
       ,.routing_matrix_p(routing_matrix_p)
       ,.reverse_order_p(reverse_order_p)
       ,.len_width_p(len_width_p)
       ) wr_rev
       (.clk_i(clk)
	,.reset_i(reset)
	,.my_cord_i(my_cord[P])
	,.link_i(rev_link_li)
	,.link_o(rev_link_lo)
	);

  integer j, k, m, n, idx;

  always_comb
  begin
    for (m = 0; m < dirs_p; m++)
      begin
        case(m)
        P: begin
            my_cord_full[m][x_marker_p-1:0]          = 2;
            my_cord_full[m][y_marker_p-1:x_marker_p] = 2;
           end
        W: begin
            my_cord_full[m][x_marker_p-1:0]          = 1;
            my_cord_full[m][y_marker_p-1:x_marker_p] = 2;
           end
        E: begin
            my_cord_full[m][x_marker_p-1:0]          = 3;
            my_cord_full[m][y_marker_p-1:x_marker_p] = 2;
           end
        N: begin
            my_cord_full[m][x_marker_p-1:0]          = 2;
            my_cord_full[m][y_marker_p-1:x_marker_p] = 1;
           end
        S: begin
            my_cord_full[m][x_marker_p-1:0]          = 2;
            my_cord_full[m][y_marker_p-1:x_marker_p] = 3;
           end
        endcase
      end
  end
  
  always_comb
  begin
    for (n = 0; n < dirs_p; n++)
      begin
        my_cord  [n] = my_cord_full  [n][cord_width_p-1:0];
        dest_cord[n] = dest_cord_full[n][cord_width_p-1:0];
      end
  end
  
  wire [x_width_p-1:0] x_full_base = my_cord_full[P][x_marker_p-1:0]          - 1;
  wire [y_width_p-1:0] y_full_base = my_cord_full[P][y_marker_p-1:x_marker_p] - 1;
  
   
  // Simulation of Clock
  always #3 clk    = ~clk;
  always #4 mc_clk = ~mc_clk;
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    clk = 1;
    mc_clk = 1;
    reset = 1;
    mc_reset = 1;
    
    mc_en = '0;
    
    #500;
    
    // chip reset
    @(posedge clk); #1;
    reset = 0;

     $display("chip reset LOW");
     
    
    #500;
    
    // mc reset
    @(posedge mc_clk); #1;
    mc_reset = 0;
     $display("mc reset LOW");
    #500;
    

     $display("directions test");     
    /********************* Directions Test **************************/
    
    for (k = 0; k < dirs_p; k++)
      begin
        
        for (j = 0; j < dirs_p; j++)
          begin
            dest_cord_full[j] = my_cord_full[(j+k)%dirs_p];
          end
        
        // Only P has loopback path
        if (k == P)
            for (j = 1; j < dirs_p; j++)
              begin
                dest_cord_full[j] = my_cord_full[(j+k+1)%dirs_p];
              end
        
        #500;
        
        // mc enable
        @(posedge mc_clk); #1;
        mc_en = '1;
	 $display("mc en HI");
        
        #10000;
        
        // mc disable
        @(posedge mc_clk); #1;
        mc_en = '0;
	 $display("mc en LO");        
        #2000;
        
      end
      
      
     $display("advanced directions test");     
    /********************* Advanced Directions Test **************************/
    
    for (k = 0; k < (3**(dims_p)-dirs_p); k++)
      begin
        
        for (j = 0; j < dirs_p; j++)
          begin
            idx = (k+j)%4;
            dest_cord_full[j][x_marker_p-1:0]          = x_full_base + (idx/2)*2;
            dest_cord_full[j][y_marker_p-1:x_marker_p] = y_full_base + (idx%2)*2;
            if ((j==W & (idx/2)==0) | (j==E & (idx/2)==1)
              | (j==N & (idx%2)==0) | (j==S & (idx%2)==1))
                dest_cord_full[j] = my_cord_full[P];
            //$display("k=%d, j=%d, idx=%d, x=%d, y=%d", k, j, idx, dest_cord_full[j][x_marker_p-1:0], dest_cord_full[j][y_marker_p-1:x_marker_p]);
          end
        
        #500;
        
        // mc enable
        @(posedge mc_clk); #1;
        mc_en = '1;
	 $display("mc en HI");
        
        #10000;
        
        // mc disable
        @(posedge mc_clk); #1;
        mc_en = '0;
	 $display("mc en LO");
        #2000;
        
      end
      
    
     $display("congestion test");         
    /********************* Congestions Test **************************/
    
    
    for (k = 0; k < dirs_p; k++)
      begin
   
        for (j = 0; j < dirs_p; j++)
          begin
            if (j == k)
              begin
                dest_cord_full[j] = my_cord_full[P];
              end
            else
              begin
                dest_cord_full[j] = my_cord_full[k];
              end
          end
        
        #500;
        
        // mc enable
        @(posedge mc_clk); #1;
        mc_en = '1;
     $display("mc en HI");
        
        #10000;
        
        // mc disable
        @(posedge mc_clk); #1;
        mc_en = '0;
     $display("mc en LO");        
        #2000;
        
      end
    
     $display("loopback");         
    
    for (j = 0; j < dirs_p; j++)
      begin
        assert(mc_error[j] == 0)
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
    
    for (j = 0; j < dirs_p; j++)
      begin
        $display("Loopback node %d sent and received %d packets\n", j, sent[j]);
      end
    
    $finish;
    
  end

endmodule

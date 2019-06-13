
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

 #(
  
  // Loopback test node configuration
  
   // Change this one to test 1d / 2d routing
   parameter dirs_p = 3
  ,parameter routing_2d_p = (dirs_p > 3)? 1 : 0
   
  ,parameter mc_node_fwd_num_channels_p = 15
  ,parameter mc_node_rev_num_channels_p = 7

  ,parameter width_p = 32
  ,parameter x_cord_width_p = 4
  ,parameter y_cord_width_p = 4
  ,parameter len_width_p = 4
  ,parameter reserved_width_p = 0
  ,parameter channel_width_p = 8
  )
  
  ();

  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  
  // Clocks and control signals
  logic mc_clk;
  logic mc_reset;
  logic clk;
  logic reset;
  
  logic [dirs_p-1:0] mc_en;
  logic [dirs_p-1:0] mc_error;
  logic [dirs_p-1:0][31:0] sent, received;
  
  logic [dirs_p-1:0][x_cord_width_p-1:0] my_x, dest_x;
  logic [dirs_p-1:0][y_cord_width_p-1:0] my_y, dest_y;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] fwd_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] fwd_link_lo;
  
  bsg_ready_and_link_sif_s [dirs_p-1:0] rev_link_li;
  bsg_ready_and_link_sif_s [dirs_p-1:0] rev_link_lo;
  
  genvar i;

  for (i = 0; i < dirs_p; i++) 
  begin
    bsg_wormhole_router_test_node
   #(.wormhole_width_p(width_p)
    ,.wormhole_x_cord_width_p(x_cord_width_p)
    ,.wormhole_y_cord_width_p(y_cord_width_p)
    ,.wormhole_len_width_p(len_width_p)
    
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
    
    ,.my_x_i(my_x[i])
    ,.my_y_i(my_y[i])

    ,.dest_x_i(dest_x[i])
    ,.dest_y_i(dest_y[i])
    
    ,.link_i({fwd_link_lo[i], rev_link_lo[i]})
    ,.link_o({fwd_link_li[i], rev_link_li[i]})
    );
  end

    bsg_wormhole_router
   #(.width_p(width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.len_width_p(len_width_p)
    ,.reserved_width_p(reserved_width_p)
    ,.enable_2d_routing_p(routing_2d_p)
    ,.stub_in_p(dirs_p'(0))
    ,.stub_out_p(dirs_p'(0))
    ) fwd_router
    (.clk_i  (clk)
    ,.reset_i(reset)
    // Configuration
    ,.my_x_i((x_cord_width_p)'(2))
    ,.my_y_i((y_cord_width_p)'(2))
    // Traffics
    ,.link_i(fwd_link_li)
    ,.link_o(fwd_link_lo)
    );
    
    bsg_wormhole_router
   #(.width_p(width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.len_width_p(len_width_p)
    ,.reserved_width_p(reserved_width_p)
    ,.enable_2d_routing_p(routing_2d_p)
    ,.stub_in_p(dirs_p'(0))
    ,.stub_out_p(dirs_p'(0))
    ) rev_router
    (.clk_i  (clk)
    ,.reset_i(reset)
    // Configuration
    ,.my_x_i((x_cord_width_p)'(2))
    ,.my_y_i((y_cord_width_p)'(2))
    // Traffics
    ,.link_i(rev_link_li)
    ,.link_o(rev_link_lo)
    );

  // Simulation of Clock
  always #3 clk    = ~clk;
  always #4 mc_clk = ~mc_clk;
  
  integer j, k;
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    clk = 1;
    mc_clk = 1;
    reset = 1;
    mc_reset = 1;
    
    mc_en = '0;
    
    for (j = 0; j < dirs_p; j++)
        case (j)
        P: begin
            my_x[j] = 2;
            my_y[j] = 2;
           end
        W: begin
            my_x[j] = 1;
            my_y[j] = 2;
           end
        E: begin
            my_x[j] = 3;
            my_y[j] = 2;
           end
        N: begin
            my_x[j] = 2;
            my_y[j] = 1;
           end
        S: begin
            my_x[j] = 2;
            my_y[j] = 3;
           end
        default: begin
           end
        endcase
    
    #500;
    
    // chip reset
    @(posedge clk); #1;
    reset = 0;
    
    #500;
    
    // mc reset
    @(posedge mc_clk); #1;
    mc_reset = 0;
    
    #500;
    
    
    /********************* Directions Test **************************/
    
    for (k = 0; k < dirs_p; k++)
      begin
        
        for (j = 0; j < dirs_p; j++)
          begin
            dest_x[j] = my_x[(j+k)%dirs_p];
            dest_y[j] = my_y[(j+k)%dirs_p];
          end
        
        // Only P has loopback path
        if (k == P)
            for (j = 1; j < dirs_p; j++)
              begin
                dest_x[j] = my_x[(j+k+1)%dirs_p];
                dest_y[j] = my_y[(j+k+1)%dirs_p];
              end
        
        #500;
        
        // mc enable
        @(posedge mc_clk); #1;
        mc_en = '1;
        
        #10000;
        
        // mc disable
        @(posedge mc_clk); #1;
        mc_en = '0;
        
        #2000;
        
      end
    
    
    /********************* Congestions Test **************************/
    
    
    for (k = 0; k < dirs_p; k++)
      begin
   
        for (j = 0; j < dirs_p; j++)
          begin
            if (j == k)
              begin
                dest_x[j] = my_x[P];
                dest_y[j] = my_y[P];
              end
            else
              begin
                dest_x[j] = my_x[k];
                dest_y[j] = my_y[k];
              end
          end
        
        #500;
        
        // mc enable
        @(posedge mc_clk); #1;
        mc_en = '1;
        
        #10000;
        
        // mc disable
        @(posedge mc_clk); #1;
        mc_en = '0;
        
        #2000;
        
      end
    
    
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
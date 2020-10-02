
//
// Paul Gao 08/2020
//
//

`timescale 1ps/1ps
`include "bsg_noc_links.vh"

module bsg_parallel_in_serial_out_tester

 #(
  // Variable parameters
   parameter top_master_clk_period_p     = 5
  ,parameter top_piso_clk_period_p       = 5
  ,parameter top_client_clk_period_p     = 5
  ,parameter top_els_p                   = 4
  ,parameter top_hi_to_lo_p              = 0
  ,parameter top_use_minimal_buffering_p = 0
  // Static parameters
  ,parameter width_p                 = 64
  ,parameter channel_width_p         = 8
  ,localparam word_width_lp          = width_p/top_els_p
  )
  
  ();
  
  `declare_bsg_ready_and_link_sif_s(width_p, master_link_s);
  `declare_bsg_ready_and_link_sif_s(word_width_lp, client_link_s);
  
  logic master_clk, master_reset;
  logic piso_clk, piso_reset;
  logic client_clk, client_reset;
  
  logic master_en, client_error;
  logic [31:0] master_sent, client_received;
  
  master_link_s master_link_li;
  master_link_s master_link_lo;
  
  client_link_s client_link_li;
  client_link_s client_link_lo;
  
  
  bsg_parallel_in_serial_out_test_node
 #(.num_channels_p(width_p/channel_width_p)
  ,.channel_width_p(channel_width_p)
  ,.hi_to_lo_p(top_hi_to_lo_p)
  ,.link_width_p(width_p)
  ,.is_client_node_p(0)
  ) master_node
  (.node_clk_i  (master_clk)
  ,.node_reset_i(master_reset)
  ,.node_en_i   (master_en)
  
  ,.error_o   ()
  ,.sent_o    (master_sent)
  ,.received_o()
   
  ,.clk_i   (piso_clk)
  ,.reset_i (piso_reset)
  
  ,.link_i(master_link_li)
  ,.link_o(master_link_lo)
  );
  
  bsg_parallel_in_serial_out 
 #(.width_p                (word_width_lp)
  ,.els_p                  (top_els_p)
  ,.hi_to_lo_p             (top_hi_to_lo_p)
  ,.use_minimal_buffering_p(top_use_minimal_buffering_p)
  ) piso
  (.clk_i  (piso_clk)
  ,.reset_i(piso_reset)

  ,.valid_i(master_link_lo.v)
  ,.data_i (master_link_lo.data)
  ,.ready_and_o(master_link_li.ready_and_rev)

  ,.valid_o(client_link_li.v)
  ,.data_o (client_link_li.data)
  ,.yumi_i (client_link_li.v & client_link_lo.ready_and_rev)
  );
  
  bsg_parallel_in_serial_out_test_node
 #(.num_channels_p(width_p/channel_width_p)
  ,.channel_width_p(channel_width_p)
  ,.hi_to_lo_p(top_hi_to_lo_p)
  ,.link_width_p(word_width_lp)
  ,.is_client_node_p(1)
  ) client_node
  (.node_clk_i  (client_clk)
  ,.node_reset_i(client_reset)
  ,.node_en_i   (1'b0)
  
  ,.error_o   (client_error)
  ,.sent_o    ()
  ,.received_o(client_received)
   
  ,.clk_i   (piso_clk)
  ,.reset_i (piso_reset)
  
  ,.link_i(client_link_li)
  ,.link_o(client_link_lo)
  );
  
  
  // Simulation of Clock
  always #(top_master_clk_period_p) master_clk = ~master_clk;
  always #(top_piso_clk_period_p  ) piso_clk   = ~piso_clk;
  always #(top_client_clk_period_p) client_clk = ~client_clk;
  
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    master_clk = 1;
    piso_clk = 1;
    client_clk = 1;
    
    master_reset = 1;
    piso_reset = 1;
    client_reset = 1;
    
    master_en = 0;
    
    #500;
    
    // piso reset
    @(posedge piso_clk); #1;
    piso_reset = 0;
    $display("fifo reset LOW"); 
    #500;
    
    // node reset
    @(posedge master_clk); #1;
    master_reset = 0;
    @(posedge client_clk); #1;
    client_reset = 0;
    $display("node reset LOW");
    #500;
    
    $display("start running test");

    // node enable
    @(posedge master_clk); #1;
    master_en = 1;
    $display("node enable HIGH");
    
    #50000;
    
    // node disable
    @(posedge master_clk); #1;
    master_en = 0;
    $display("node enable LOW");
    
    #5000
    
    assert(client_error == 0)
    else 
      begin
        $error("\nFAIL... Error in client node");
        $finish;
      end
    
    assert(master_sent == client_received)
    else 
      begin
        $error("\nFAIL... Master node sent %d packets but client node received only %d\n", master_sent, client_received);
        $finish;
      end
    
    $display("\nPASS!\n");
    
    $display("Master node sent and client node received %d packets\n", master_sent);
    
    $finish;
    
  end

endmodule

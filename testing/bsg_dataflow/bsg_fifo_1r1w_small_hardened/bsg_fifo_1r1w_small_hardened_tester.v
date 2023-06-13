
//
// Paul Gao 08/2019
//
//

`timescale 1ps/1ps

`include "bsg_noc_links.svh"

module bsg_fifo_1r1w_small_hardened_tester

 #(parameter top_num_clocks_p = 3
  ,parameter width_p  = 64
  ,parameter els_p    = 4
  ,parameter channel_width_p = 8
  )
  
  ();
  
  `declare_bsg_ready_and_link_sif_s(width_p, bsg_ready_and_link_sif_s);
  
  logic master_clk, master_reset;
  logic client_clk, client_reset;
  logic fifo_clk, fifo_reset;
  
  logic master_en;
  logic master_error;
  logic [31:0] master_sent, master_received;
  
  bsg_ready_and_link_sif_s master_node_link_li;
  bsg_ready_and_link_sif_s master_node_link_lo;
  
  bsg_ready_and_link_sif_s client_node_link_li;
  bsg_ready_and_link_sif_s client_node_link_lo;
  
  
  bsg_fifo_1r1w_small_hardened_test_node
 #(.num_channels_p(width_p/channel_width_p)
  ,.channel_width_p(channel_width_p)
  ,.is_client_node_p(0)
  ) master_node
  (.node_clk_i  (master_clk)
  ,.node_reset_i(master_reset)
  ,.node_en_i   (master_en)
  
  ,.error_o   (master_error)
  ,.sent_o    (master_sent)
  ,.received_o(master_received)
   
  ,.clk_i   (fifo_clk)
  ,.reset_i (fifo_reset)
  
  ,.link_i(master_node_link_li)
  ,.link_o(master_node_link_lo)
  );
  
  bsg_fifo_1r1w_small
 #(.width_p (width_p)
  ,.els_p   (els_p)
  ,.harden_p(1)
  ) fifo_m2c
  (.clk_i  (fifo_clk)
  ,.reset_i(fifo_reset)
  ,.v_i    (master_node_link_lo.v)
  ,.ready_param_o(master_node_link_li.ready_and_rev)
  ,.data_i (master_node_link_lo.data)
  ,.v_o    (client_node_link_li.v)
  ,.data_o (client_node_link_li.data)
  ,.yumi_i (client_node_link_li.v & client_node_link_lo.ready_and_rev)
  );
  
  bsg_fifo_1r1w_small
 #(.width_p (width_p)
  ,.els_p   (els_p)
  ,.harden_p(1)
  ) fifo_c2m
  (.clk_i  (fifo_clk)
  ,.reset_i(fifo_reset)
  ,.v_i    (client_node_link_lo.v)
  ,.ready_param_o(client_node_link_li.ready_and_rev)
  ,.data_i (client_node_link_lo.data)
  ,.v_o    (master_node_link_li.v)
  ,.data_o (master_node_link_li.data)
  ,.yumi_i (master_node_link_li.v & master_node_link_lo.ready_and_rev)
  );

  bind bsg_fifo_1r1w_small_hardened bsg_fifo_1r1w_small_hardened_cov
 #(.els_p(els_p)
  ) pc_cov
  (.*
  );

  bsg_fifo_1r1w_small_hardened_test_node
 #(.num_channels_p(width_p/channel_width_p)
  ,.channel_width_p(channel_width_p)
  ,.is_client_node_p(1)
  ) client_node
  (.node_clk_i  (client_clk)
  ,.node_reset_i(client_reset)
  ,.node_en_i   (1'b0)
  
  ,.error_o   ()
  ,.sent_o    ()
  ,.received_o()
   
  ,.clk_i   (fifo_clk)
  ,.reset_i (fifo_reset)
  
  ,.link_i(client_node_link_li)
  ,.link_o(client_node_link_lo)
  );
  
  
  // Simulation of Clock
  localparam num_clocks_lp = top_num_clocks_p;
  wire [num_clocks_lp-1:0][31:0] clk_period_lo = {32'd7, 32'd5, 32'd3};

  logic [num_clocks_lp-1:0] master_clks, fifo_clks, client_clks;
  for (genvar i = 0; i < num_clocks_lp; i++)
  begin
    always #(clk_period_lo[i]) master_clks[i] = ~master_clks[i];
    always #(clk_period_lo[i])   fifo_clks[i]   = ~fifo_clks[i];
    always #(clk_period_lo[i]) client_clks[i] = ~client_clks[i];
  end

  logic [3:0] master_sel, fifo_sel, client_sel;
  assign master_clk = master_clks[master_sel];
  assign fifo_clk = fifo_clks[fifo_sel];
  assign client_clk = client_clks[client_sel];

  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    master_clks = '1;
    fifo_clks = '1;
    client_clks = '1;
    
    #500;

    for (integer i = 0; i < num_clocks_lp; i++)
      begin
    for (integer j = 0; j < num_clocks_lp; j++)
      begin
    for (integer k = 0; k < num_clocks_lp; k++)
      begin

    master_sel = i;
    fifo_sel = j;
    client_sel = k;

    master_reset = 1;
    fifo_reset = 1;
    client_reset = 1;
    
    master_en = 0;

    #500;

    // fifo reset
    @(posedge fifo_clk); #1;
    fifo_reset = 0;
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
    
    assert(master_error == 0)
    else 
      begin
        $error("\nFAIL... Error in loopback node");
        $finish;
      end
    
    assert(master_sent == master_received)
    else 
      begin
        $error("\nFAIL... Loopback node sent %d packets but received only %d\n", master_sent, master_received);
        $finish;
      end

    end
    end
    end

    $display("\nPASS!\n");
    
    $display("Loopback node sent and received %d packets\n", master_sent);
    
    $finish;
    
  end

endmodule

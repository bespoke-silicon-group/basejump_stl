
//
// Paul Gao 08/2019
//
//

`timescale 1ps/1ps

module bsg_fifo_1r1w_small_hardened_tester

 #(
   parameter width_p  = 80
  ,parameter els_p    = 16
  )
  
  ();
  
  logic master_clk, master_reset;
  logic client_clk, client_reset;
  logic fifo_clk, fifo_reset;
  
  logic master_en, client_en;
  
  logic master_node_v_lo, master_node_ready_li;
  logic [width_p-1:0] master_node_data_lo;
  
  logic master_node_v_li, master_node_ready_lo;
  logic [width_p-1:0] master_node_data_li;
  
  logic master_fifo_v_lo, master_fifo_ready_li;
  logic [width_p-1:0] master_fifo_data_lo;
  
  logic master_fifo_v_li, master_fifo_ready_lo;
  logic [width_p-1:0] master_fifo_data_li;
  
  logic client_fifo_v_lo, client_fifo_ready_li;
  logic [width_p-1:0] client_fifo_data_lo;
  
  logic client_fifo_v_li, client_fifo_ready_lo;
  logic [width_p-1:0] client_fifo_data_li;
  
  logic client_node_v_lo, client_node_ready_li;
  logic [width_p-1:0] client_node_data_lo;
  
  logic client_node_v_li, client_node_ready_lo;
  logic [width_p-1:0] client_node_data_li;
   
  // Simulation of Clock
  always #4 master_clk = ~master_clk;
  always #4 client_clk = ~client_clk;
  always #4 fifo_clk   = ~fifo_clk;
  
  bsg_test_node_master
 #(.ring_width_p(width_p)
  ,.master_id_p (0)
  ,.client_id_p (0)
  ) master_node
  (.clk_i     (master_clk)
  ,.reset_i   (master_reset)
  ,.en_i      (master_en)

  ,.v_i       (master_node_v_li)
  ,.data_i    (master_node_data_li)
  ,.ready_o   (master_node_ready_lo)

  ,.v_o       (master_node_v_lo)
  ,.data_o    (master_node_data_lo)
  ,.yumi_i    (master_node_v_lo & master_node_ready_li)
  );
  
  logic master_node_full_lo;
  assign master_node_ready_li = ~master_node_full_lo;
  
  bsg_async_fifo 
 #(.lg_size_p(3)
  ,.width_p  (width_p)
  ) master_n2f
  (.w_clk_i  (master_clk)
  ,.w_reset_i(master_reset)
  ,.w_enq_i  (master_node_v_lo & master_node_data_lo[64+:16]==16'h0020 & master_node_ready_li)
  ,.w_data_i (master_node_data_lo)
  ,.w_full_o (master_node_full_lo)
  ,.r_clk_i  (fifo_clk)
  ,.r_reset_i(fifo_reset)
  ,.r_deq_i  (master_fifo_v_li & master_fifo_ready_lo)
  ,.r_data_o (master_fifo_data_li)
  ,.r_valid_o(master_fifo_v_li)
  );
  
  logic master_fifo_full_lo;
  assign master_fifo_ready_li = ~master_fifo_full_lo;
  
  bsg_async_fifo 
 #(.lg_size_p(3)
  ,.width_p  (width_p)
  ) master_f2n
  (.w_clk_i  (fifo_clk)
  ,.w_reset_i(fifo_reset)
  ,.w_enq_i  (master_fifo_v_lo & master_fifo_ready_li)
  ,.w_data_i (master_fifo_data_lo)
  ,.w_full_o (master_fifo_full_lo)
  ,.r_clk_i  (master_clk)
  ,.r_reset_i(master_reset)
  ,.r_deq_i  (master_node_v_li & master_node_ready_lo)
  ,.r_data_o (master_node_data_li)
  ,.r_valid_o(master_node_v_li)
  );
  
  bsg_fifo_1r1w_small_hardened 
 #(.width_p (width_p)
  ,.els_p   (els_p)
  ) fifo_m2c
  (.clk_i  (fifo_clk)
  ,.reset_i(fifo_reset)
  ,.v_i    (master_fifo_v_li)
  ,.ready_o(master_fifo_ready_lo)
  ,.data_i (master_fifo_data_li)
  ,.v_o    (client_fifo_v_lo)
  ,.data_o (client_fifo_data_lo)
  ,.yumi_i (client_fifo_v_lo & client_fifo_ready_li)
  );
  
  bsg_fifo_1r1w_small_hardened 
 #(.width_p (width_p)
  ,.els_p   (els_p)
  ) fifo_c2m
  (.clk_i  (fifo_clk)
  ,.reset_i(fifo_reset)
  ,.v_i    (client_fifo_v_li)
  ,.ready_o(client_fifo_ready_lo)
  ,.data_i (client_fifo_data_li)
  ,.v_o    (master_fifo_v_lo)
  ,.data_o (master_fifo_data_lo)
  ,.yumi_i (master_fifo_v_lo & master_fifo_ready_li)
  );
  
  logic client_node_full_lo;
  assign client_node_ready_li = ~client_node_full_lo;
  
  bsg_async_fifo 
 #(.lg_size_p(3)
  ,.width_p  (width_p)
  ) client_n2f
  (.w_clk_i  (client_clk)
  ,.w_reset_i(client_reset)
  ,.w_enq_i  (client_node_v_lo & client_node_ready_li)
  ,.w_data_i (client_node_data_lo)
  ,.w_full_o (client_node_full_lo)
  ,.r_clk_i  (fifo_clk)
  ,.r_reset_i(fifo_reset)
  ,.r_deq_i  (client_fifo_v_li & client_fifo_ready_lo)
  ,.r_data_o (client_fifo_data_li)
  ,.r_valid_o(client_fifo_v_li)
  );
  
  logic client_fifo_full_lo;
  assign client_fifo_ready_li = ~client_fifo_full_lo;
  
  bsg_async_fifo 
 #(.lg_size_p(3)
  ,.width_p  (width_p)
  ) client_f2n
  (.w_clk_i  (fifo_clk)
  ,.w_reset_i(fifo_reset)
  ,.w_enq_i  (client_fifo_v_lo & client_fifo_ready_li)
  ,.w_data_i (client_fifo_data_lo)
  ,.w_full_o (client_fifo_full_lo)
  ,.r_clk_i  (client_clk)
  ,.r_reset_i(client_reset)
  ,.r_deq_i  (client_node_v_li & client_node_ready_lo)
  ,.r_data_o (client_node_data_li)
  ,.r_valid_o(client_node_v_li)
  );
  
  bsg_test_node_client
 #(.ring_width_p(width_p)
  ,.master_id_p (0)
  ,.client_id_p (0)
  ) client_node
  (.clk_i     (client_clk)
  ,.reset_i   (client_reset)
  ,.en_i      (client_en)

  ,.v_i       (client_node_v_li)
  ,.data_i    (client_node_data_li)
  ,.ready_o   (client_node_ready_lo)

  ,.v_o       (client_node_v_lo)
  ,.data_o    (client_node_data_lo)
  ,.yumi_i    (client_node_v_lo & client_node_ready_li)
  );
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    master_clk = 1;
    fifo_clk = 1;
    client_clk = 1;
    
    master_reset = 1;
    fifo_reset = 1;
    client_reset = 1;
    
    master_en = 1;
    client_en = 1;
    
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
    @(posedge client_clk); #1;
    client_en = 1;
    $display("node enable HIGH");
    
    #50000;
    
    // node disable
    @(posedge master_clk); #1;
    master_en = 0;
    @(posedge client_clk); #1;
    client_en = 0;
    $display("node enable LOW");
    
    $display("\nFINISHED!\n");
    
    $finish;
    
  end

endmodule

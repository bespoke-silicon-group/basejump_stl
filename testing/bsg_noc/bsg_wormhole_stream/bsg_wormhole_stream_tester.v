
`timescale 1ps/1ps

module bsg_wormhole_stream_tester

 #(parameter channel_width_p = 8

  ,parameter flit_width_p    = 32
  ,parameter len_width_p     = 4
  ,parameter cord_width_p    = 4
  
  // Adjust following 2 parameters to test different hardwares
  ,parameter hdr_width_p     = flit_width_p*1 // flit_wid_p*2
  ,parameter pr_data_width_p = flit_width_p*1 // flit_width_p*2, flit_width_p/2
  
  ,parameter pr_hdr_width_p  = hdr_width_p - (len_width_p+cord_width_p)
  )
  
  ();
  
  logic slow_clk, norm_clk, fast_clk;
  logic [1:0] master_sel, in_sel, out_sel, client_sel;
  
  logic master_clk, in_clk, out_clk, client_clk;
  logic master_reset, in_reset, out_reset, client_reset;
  
  logic master_en, client_error;
  logic [31:0] master_sent, client_received;
  
  logic hdr_v_li, hdr_ready_lo;
  logic [hdr_width_p-1:0] hdr_li;
  
  logic data_v_li, data_ready_lo;
  logic [pr_data_width_p-1:0] data_li;
  
  logic link_v_lo, link_full_li;
  logic [flit_width_p-1:0] link_data_lo;
  
  logic link_v_li, link_ready_and_lo;
  logic [flit_width_p-1:0] link_data_li;
  
  logic hdr_v_lo, hdr_ready_li;
  logic [hdr_width_p-1:0] hdr_lo;
  
  logic data_v_lo, data_ready_li;
  logic [pr_data_width_p-1:0] data_lo;
  
  
  bsg_wormhole_stream_test_node
 #(.channel_width_p (channel_width_p)
  ,.len_width_p     (len_width_p)
  ,.cord_width_p    (cord_width_p)
  ,.pr_hdr_width_p  (pr_hdr_width_p)
  ,.pr_data_width_p (pr_data_width_p)
  ,.is_client_node_p(0)
  ) master_node
  (.node_clk_i      (master_clk)
  ,.node_reset_i    (master_reset)
  ,.node_en_i       (master_en)

  ,.error_o         ()
  ,.sent_o          (master_sent)
  ,.received_o      ()

  ,.clk_i           (in_clk)
  ,.reset_i         (in_reset)

  ,.hdr_o           (hdr_li)
  ,.hdr_v_o         (hdr_v_li)
  ,.hdr_ready_i     (hdr_ready_lo)

  ,.hdr_i           ('0)
  ,.hdr_v_i         (1'b0)
  ,.hdr_ready_and_o     ()
  
  ,.data_o          (data_li)
  ,.data_v_o        (data_v_li)
  ,.data_ready_i    (data_ready_lo)

  ,.data_i          ('0)
  ,.data_v_i        (1'b0)
  ,.data_ready_and_o    ()
  );
  
  
  bsg_wormhole_stream_in
 #(.flit_width_p   (flit_width_p)
  ,.len_width_p    (len_width_p)
  ,.cord_width_p   (cord_width_p)
  ,.pr_hdr_width_p (pr_hdr_width_p)
  ,.pr_data_width_p(pr_data_width_p)
   ) stream_in
  (.clk_i          (in_clk)
  ,.reset_i        (in_reset)

  ,.hdr_i          (hdr_li)
  ,.hdr_v_i        (hdr_v_li)
  ,.hdr_ready_and_o    (hdr_ready_lo)

  ,.data_i         (data_li)
  ,.data_v_i       (data_v_li)
  ,.data_ready_and_o   (data_ready_lo)

  ,.link_data_o    (link_data_lo)
  ,.link_v_o       (link_v_lo)
  ,.link_ready_and_i   (~link_full_li)
  );
  

  bsg_async_fifo
 #(.lg_size_p(3)
  ,.width_p  (flit_width_p)
  ) in_to_out
  (.w_clk_i  (in_clk)
  ,.w_reset_i(in_reset)
  ,.w_enq_i  (link_v_lo & ~link_full_li)
  ,.w_data_i (link_data_lo)
  ,.w_full_o (link_full_li)

  ,.r_clk_i  (out_clk)
  ,.r_reset_i(out_reset)
  ,.r_deq_i  (link_v_li & link_ready_and_lo)
  ,.r_data_o (link_data_li)
  ,.r_valid_o(link_v_li)
  );

  
  bsg_wormhole_stream_out
 #(.flit_width_p   (flit_width_p)
  ,.len_width_p    (len_width_p)
  ,.cord_width_p   (cord_width_p)
  ,.pr_hdr_width_p (pr_hdr_width_p)
  ,.pr_data_width_p(pr_data_width_p)
   ) stream_out
  (.clk_i          (out_clk)
  ,.reset_i        (out_reset)

  ,.link_data_i    (link_data_li)
  ,.link_v_i       (link_v_li)
  ,.link_ready_and_o(link_ready_and_lo)

  ,.hdr_o          (hdr_lo)
  ,.hdr_v_o        (hdr_v_lo)
  ,.hdr_ready_and_i(hdr_ready_li)

  ,.data_o         (data_lo)
  ,.data_v_o       (data_v_lo)
  ,.data_ready_and_i(data_ready_li)
  );
  
  
  bsg_wormhole_stream_test_node
 #(.channel_width_p (channel_width_p)
  ,.len_width_p     (len_width_p)
  ,.cord_width_p    (cord_width_p)
  ,.pr_hdr_width_p  (pr_hdr_width_p)
  ,.pr_data_width_p (pr_data_width_p)
  ,.is_client_node_p(1)
  ) client_node
  (.node_clk_i      (client_clk)
  ,.node_reset_i    (client_reset)
  ,.node_en_i       (1'b1)

  ,.error_o         (client_error)
  ,.sent_o          ()
  ,.received_o      (client_received)

  ,.clk_i           (out_clk)
  ,.reset_i         (out_reset)

  ,.hdr_o           ()
  ,.hdr_v_o         ()
  ,.hdr_ready_i     (1'b1)

  ,.hdr_i           (hdr_lo)
  ,.hdr_v_i         (hdr_v_lo)
  ,.hdr_ready_and_o     (hdr_ready_li)
  
  ,.data_o          ()
  ,.data_v_o        ()
  ,.data_ready_i    (1'b1)

  ,.data_i          (data_lo)
  ,.data_v_i        (data_v_lo)
  ,.data_ready_and_o    (data_ready_li)
  );
  
  
  // Simulation of Clock
  always #13 slow_clk = ~slow_clk;
  always #8  norm_clk = ~norm_clk;
  always #3  fast_clk = ~fast_clk;
  
  // clock selection
  bsg_mux #(.width_p(1),.els_p(3)) master_mux
  (.data_i({fast_clk, norm_clk, slow_clk})
  ,.sel_i (master_sel)
  ,.data_o(master_clk));
  
  bsg_mux #(.width_p(1),.els_p(3)) in_mux
  (.data_i({fast_clk, norm_clk, slow_clk})
  ,.sel_i (in_sel)
  ,.data_o(in_clk));
  
  bsg_mux #(.width_p(1),.els_p(3)) out_mux
  (.data_i({fast_clk, norm_clk, slow_clk})
  ,.sel_i (out_sel)
  ,.data_o(out_clk));
  
  bsg_mux #(.width_p(1),.els_p(3)) client_mux
  (.data_i({fast_clk, norm_clk, slow_clk})
  ,.sel_i (client_sel)
  ,.data_o(client_clk));
  
  // reset sync
  bsg_launch_sync_sync #(.width_p(1)) blss_in
  (.iclk_i      (master_clk)
  ,.iclk_reset_i(1'b0)
  ,.oclk_i      (in_clk)
  ,.iclk_data_i (master_reset)
  ,.iclk_data_o ()
  ,.oclk_data_o (in_reset));
  
  bsg_launch_sync_sync #(.width_p(1)) blss_out
  (.iclk_i      (master_clk)
  ,.iclk_reset_i(1'b0)
  ,.oclk_i      (out_clk)
  ,.iclk_data_i (master_reset)
  ,.iclk_data_o ()
  ,.oclk_data_o (out_reset));
  
  bsg_launch_sync_sync #(.width_p(1)) blss_client
  (.iclk_i      (master_clk)
  ,.iclk_reset_i(1'b0)
  ,.oclk_i      (client_clk)
  ,.iclk_data_i (master_reset)
  ,.iclk_data_o ()
  ,.oclk_data_o (client_reset));
  
  // 5 different combinations of clock speeds to test flow control
  // 0==slow, 1==normal, 2==fast
  //
  logic [4:0][3:0][1:0] clk_sel = 
    {{2'd1, 2'd1, 2'd1, 2'd1}, 
     {2'b0, 2'd2, 2'd2, 2'd2}, 
     {2'd2, 2'd0, 2'd2, 2'd2}, 
     {2'd2, 2'd2, 2'd0, 2'd2}, 
     {2'd2, 2'd2, 2'd2, 2'd0}};
  
  integer i;
  
  initial 
  begin

    $display("Start Simulation\n");
  
    // Init
    slow_clk = 1;
    norm_clk = 1;
    fast_clk = 1;
    
    master_sel = 1;
    in_sel     = 1;
    out_sel    = 1;
    client_sel = 1;
    
    master_reset = 1;
    master_en = 0;
    
    #500;
    
    for (i = 0; i < 5; i++)
      begin
      
        master_sel = clk_sel[i][3];
        in_sel     = clk_sel[i][2];
        out_sel    = clk_sel[i][1];
        client_sel = clk_sel[i][0];
    
        // disable reset
        @(posedge master_clk); #1;
        master_reset = 0;
        $display("reset LOW"); 
        #500;

        // node enable
        @(posedge master_clk); #1;
        master_en = 1;
        $display("node enable HIGH");
        
        #20000;
        
        // node disable
        @(posedge master_clk); #1;
        master_en = 0;
        $display("node enable LOW");

        #5000;
        
        assert(client_error == 0)
        else 
          begin
            $error("\nFAIL... Error in client node");
            $finish;
          end
        
        assert(master_sent == client_received)
        else 
          begin
            $error("\nFAIL... master node sent %d packets but client node received only %d\n", master_sent, client_received);
            $finish;
          end
        $display("Master node sent and client node received %d packets\n", master_sent);
          
        // enable reset
        @(posedge master_clk); #1;
        master_reset = 1;
        $display("reset HIGH");
        #500;
        
    end
    
    
    
    $display("\nPASS!\n");
    $finish;
    
  end

endmodule

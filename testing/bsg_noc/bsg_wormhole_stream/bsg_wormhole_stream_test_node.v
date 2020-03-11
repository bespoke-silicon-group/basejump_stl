
module bsg_wormhole_stream_test_node

 #(parameter channel_width_p  = "inv"
  ,parameter len_width_p      = "inv"
  ,parameter cord_width_p     = "inv"
  ,parameter pr_hdr_width_p   = "inv"
  ,parameter pr_data_width_p  = "inv"
  ,parameter is_client_node_p = "inv"
  ,parameter num_channels_p   = 8
  
  ,localparam hdr_width_lp    = cord_width_p + len_width_p + pr_hdr_width_p
  )

  (input         node_clk_i  
  ,input         node_reset_i
  ,input         node_en_i   

  ,output logic  error_o     
  ,output [31:0] sent_o      
  ,output [31:0] received_o  

  ,input                        clk_i       
  ,input                        reset_i     

  ,output [hdr_width_lp-1:0]    hdr_o       
  ,output                       hdr_v_o     
  ,input                        hdr_ready_i 

  ,input  [hdr_width_lp-1:0]    hdr_i       
  ,input                        hdr_v_i     
  ,output                       hdr_ready_o 
  
  ,output [pr_data_width_p-1:0] data_o      
  ,output                       data_v_o    
  ,input                        data_ready_i

  ,input  [pr_data_width_p-1:0] data_i      
  ,input                        data_v_i    
  ,output                       data_ready_o
  );

  // Async fifo signals
  logic hdr_async_fifo_valid_li, hdr_async_fifo_yumi_lo;
  logic hdr_async_fifo_valid_lo, hdr_async_fifo_ready_li;

  logic [hdr_width_lp-1:0] hdr_async_fifo_data_li;
  logic [hdr_width_lp-1:0] hdr_async_fifo_data_lo;
  
  logic data_async_fifo_valid_li, data_async_fifo_yumi_lo;
  logic data_async_fifo_valid_lo, data_async_fifo_ready_li;

  logic [pr_data_width_p-1:0] data_async_fifo_data_li;
  logic [pr_data_width_p-1:0] data_async_fifo_data_lo;


  logic [num_channels_p*channel_width_p-1:0] hdr_gen, data_gen;
  logic hdr_gen_yumi, data_gen_yumi;

  test_bsg_data_gen
 #(.channel_width_p(channel_width_p)
  ,.num_channels_p(num_channels_p)
  ) test_hdr_gen
  (.clk_i  (node_clk_i)
  ,.reset_i(node_reset_i)
  ,.yumi_i (hdr_gen_yumi)
  ,.o      (hdr_gen)
  );

  test_bsg_data_gen
 #(.channel_width_p(channel_width_p)
  ,.num_channels_p(num_channels_p)
  ) test_data_gen
  (.clk_i  (node_clk_i)
  ,.reset_i(node_reset_i)
  ,.yumi_i (data_gen_yumi)
  ,.o      (data_gen)
  );
  
  logic [31:0] hdr_count;
  
  bsg_counter_clear_up
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ) hdr_counter
  (.clk_i  (node_clk_i)
  ,.reset_i(node_reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (hdr_gen_yumi)
  ,.count_o(hdr_count)
  );
  
  assign sent_o = hdr_count;
  assign received_o = hdr_count;
  
  
  logic [1:0] count_r;
  always_ff @(posedge node_clk_i)
    if (node_reset_i) 
        count_r <= 0;
    else              
        count_r <= count_r + hdr_gen_yumi;

  wire [hdr_width_lp-1:0] current_hdr = {pr_hdr_width_p'(hdr_gen) ,len_width_p'(count_r), cord_width_p'(3)};

  if (is_client_node_p == 0)
    begin: master
      /********************* Master node *********************/

      assign hdr_async_fifo_valid_li = node_en_i;
      assign hdr_async_fifo_data_li = current_hdr;
      assign hdr_gen_yumi = hdr_async_fifo_yumi_lo;
      
      assign data_async_fifo_valid_li = 1'b1;
      assign data_async_fifo_data_li = pr_data_width_p'(data_gen);
      assign data_gen_yumi = data_async_fifo_yumi_lo;

    end
  else
    begin: client
      /********************* Client node *********************/

      assign hdr_async_fifo_ready_li = 1'b1;
      assign hdr_gen_yumi = hdr_async_fifo_valid_lo;
      
      assign data_async_fifo_ready_li = 1'b1;
      assign data_gen_yumi = data_async_fifo_valid_lo;
      
      // Check errors
      
      always_ff @(posedge node_clk_i)
        if (node_reset_i)
            error_o <= 0;
        else
            if (hdr_async_fifo_valid_lo && current_hdr != hdr_async_fifo_data_lo)
              begin
                $error("%m mismatched %x %x", current_hdr, hdr_async_fifo_data_lo);
                error_o <= 1;
              end
            else if (data_async_fifo_valid_lo && pr_data_width_p'(data_gen) != data_async_fifo_data_lo)
              begin
                $error("%m mismatched %x %x", pr_data_width_p'(data_gen), data_async_fifo_data_lo);
                error_o <= 1;
              end
      
    end


  /********************* Async fifo to link *********************/

  // Node side async fifo input
  logic  hdr_async_fifo_full_lo;
  assign hdr_async_fifo_yumi_lo = ~hdr_async_fifo_full_lo & hdr_async_fifo_valid_li;

  // Link side async fifo input
  logic  hdr_link_async_fifo_full_lo;
  assign hdr_ready_o = ~hdr_link_async_fifo_full_lo;

  bsg_async_fifo
 #(.lg_size_p(3)
  ,.width_p  (hdr_width_lp)
  ) hdr_in
  (.w_clk_i  (clk_i)
  ,.w_reset_i(reset_i)
  ,.w_enq_i  (hdr_v_i & hdr_ready_o)
  ,.w_data_i (hdr_i)
  ,.w_full_o (hdr_link_async_fifo_full_lo)

  ,.r_clk_i  (node_clk_i)
  ,.r_reset_i(node_reset_i)
  ,.r_deq_i  (hdr_async_fifo_ready_li & hdr_async_fifo_valid_lo)
  ,.r_data_o (hdr_async_fifo_data_lo)
  ,.r_valid_o(hdr_async_fifo_valid_lo)
  );

  bsg_async_fifo
 #(.lg_size_p(3)
  ,.width_p  (hdr_width_lp)
  ) hdr_out
  (.w_clk_i  (node_clk_i)
  ,.w_reset_i(node_reset_i)
  ,.w_enq_i  (hdr_async_fifo_yumi_lo)
  ,.w_data_i (hdr_async_fifo_data_li)
  ,.w_full_o (hdr_async_fifo_full_lo)

  ,.r_clk_i  (clk_i)
  ,.r_reset_i(reset_i)
  ,.r_deq_i  (hdr_v_o & hdr_ready_i)
  ,.r_data_o (hdr_o)
  ,.r_valid_o(hdr_v_o)
  );
  
  // Node side async fifo input
  logic  data_async_fifo_full_lo;
  assign data_async_fifo_yumi_lo = ~data_async_fifo_full_lo & data_async_fifo_valid_li;

  // Link side async fifo input
  logic  data_link_async_fifo_full_lo;
  assign data_ready_o = ~data_link_async_fifo_full_lo;

  bsg_async_fifo
 #(.lg_size_p(3)
  ,.width_p  (pr_data_width_p)
  ) data_in
  (.w_clk_i  (clk_i)
  ,.w_reset_i(reset_i)
  ,.w_enq_i  (data_v_i & data_ready_o)
  ,.w_data_i (data_i)
  ,.w_full_o (data_link_async_fifo_full_lo)

  ,.r_clk_i  (node_clk_i)
  ,.r_reset_i(node_reset_i)
  ,.r_deq_i  (data_async_fifo_ready_li & data_async_fifo_valid_lo)
  ,.r_data_o (data_async_fifo_data_lo)
  ,.r_valid_o(data_async_fifo_valid_lo)
  );

  bsg_async_fifo
 #(.lg_size_p(3)
  ,.width_p  (pr_data_width_p)
  ) data_out
  (.w_clk_i  (node_clk_i)
  ,.w_reset_i(node_reset_i)
  ,.w_enq_i  (data_async_fifo_yumi_lo)
  ,.w_data_i (data_async_fifo_data_li)
  ,.w_full_o (data_async_fifo_full_lo)

  ,.r_clk_i  (clk_i)
  ,.r_reset_i(reset_i)
  ,.r_deq_i  (data_v_o & data_ready_i)
  ,.r_data_o (data_o)
  ,.r_valid_o(data_v_o)
  );

endmodule

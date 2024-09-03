
//
// Paul Gao 02/2021
//
//

module bsg_link_sdr_test_node

 #(parameter `BSG_INV_PARAM(num_channels_p       )
  ,parameter `BSG_INV_PARAM(channel_width_p      )
  ,parameter is_downstream_node_p = 0
  ,parameter lg_fifo_depth_lp     = 3
  ,parameter width_lp             = num_channels_p * channel_width_p
  )

  (// Node side
   input node_clk_i
  ,input node_reset_i
  ,input node_en_i

  ,output logic  error_o
  ,output [31:0] sent_o
  ,output [31:0] received_o

  // Link side
  ,input clk_i
  ,input reset_i

  ,input                 v_i
  ,input  [width_lp-1:0] data_i
  ,output                ready_o

  ,output                v_o
  ,output [width_lp-1:0] data_o
  ,input                 yumi_i
  );

  // Async fifo signals
  logic node_async_fifo_valid_li, node_async_fifo_ready_lo;
  logic node_async_fifo_valid_lo, node_async_fifo_yumi_li;

  logic [width_lp-1:0] node_async_fifo_data_li;
  logic [width_lp-1:0] node_async_fifo_data_lo;


  if (is_downstream_node_p == 0)
  begin: upstream
    // Generate data packets
    test_bsg_data_gen
   #(.channel_width_p(channel_width_p)
    ,.num_channels_p (num_channels_p)
    ) gen_out
    (.clk_i  (node_clk_i)
    ,.reset_i(node_reset_i)
    ,.yumi_i (node_async_fifo_valid_li & node_async_fifo_ready_lo)
    ,.o      (node_async_fifo_data_li)
    );

    // Send when node is enabled
    assign node_async_fifo_valid_li = node_en_i;

    // Count sent packets
    bsg_counter_clear_up
   #(.max_val_p (1<<32-1)
    ,.init_val_p(0)
    ) sent_count
    (.clk_i  (node_clk_i)
    ,.reset_i(node_reset_i)
    ,.clear_i(1'b0)
    ,.up_i   (node_async_fifo_valid_li & node_async_fifo_ready_lo)
    ,.count_o(sent_o)
    );
  end
  else
  begin: downstream
    // Generate checking packets
    logic [width_lp-1:0] data_check;
    test_bsg_data_gen
   #(.channel_width_p(channel_width_p)
    ,.num_channels_p (num_channels_p)
    ) gen_in
    (.clk_i  (node_clk_i)
    ,.reset_i(node_reset_i)
    ,.yumi_i (node_async_fifo_yumi_li)
    ,.o      (data_check)
    );

    // Always ready
    assign node_async_fifo_yumi_li = node_async_fifo_valid_lo;

    // Count received packets
    bsg_counter_clear_up
   #(.max_val_p (1<<32-1)
    ,.init_val_p(0)
    ) received_count
    (.clk_i  (node_clk_i)
    ,.reset_i(node_reset_i)
    ,.clear_i(1'b0)
    ,.up_i   (node_async_fifo_yumi_li)
    ,.count_o(received_o)
    );

    // Check errors    
    always_ff @(posedge node_clk_i)
        if (node_reset_i)
            error_o <= 0;
        else
            if (node_async_fifo_yumi_li && data_check != node_async_fifo_data_lo)
              begin
`ifndef BSG_HIDE_FROM_SYNTHESIS
                $error("%m mismatched resp data %x %x",data_check, node_async_fifo_data_lo);
`endif
                error_o <= 1;
              end
    end


  /********************* Async fifo to link *********************/

  // Node side async fifo input
  logic  node_async_fifo_full_lo;
  assign node_async_fifo_ready_lo = ~node_async_fifo_full_lo;

  // Link side async fifo input
  logic  link_async_fifo_full_lo;
  assign ready_o = ~link_async_fifo_full_lo;

  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (width_lp)
  ) wh_to_mc
  (.w_clk_i  (clk_i)
  ,.w_reset_i(reset_i)
  ,.w_enq_i  (v_i & ready_o)
  ,.w_data_i (data_i)
  ,.w_full_o (link_async_fifo_full_lo)

  ,.r_clk_i  (node_clk_i)
  ,.r_reset_i(node_reset_i)
  ,.r_deq_i  (node_async_fifo_yumi_li)
  ,.r_data_o (node_async_fifo_data_lo)
  ,.r_valid_o(node_async_fifo_valid_lo)
  );

  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (width_lp)
  ) mc_to_wh
  (.w_clk_i  (node_clk_i)
  ,.w_reset_i(node_reset_i)
  ,.w_enq_i  (node_async_fifo_valid_li & node_async_fifo_ready_lo)
  ,.w_data_i (node_async_fifo_data_li)
  ,.w_full_o (node_async_fifo_full_lo)

  ,.r_clk_i  (clk_i)
  ,.r_reset_i(reset_i)
  ,.r_deq_i  (yumi_i)
  ,.r_data_o (data_o)
  ,.r_valid_o(v_o)
  );

endmodule

`BSG_ABSTRACT_MODULE(bsg_link_sdr_test_node)

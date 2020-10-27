
//
// Paul Gao 08/2020
//
//

`include "bsg_noc_links.vh"

module bsg_parallel_in_serial_out_test_node

 #(parameter num_channels_p = "inv"
  ,parameter channel_width_p = "inv"
  ,parameter hi_to_lo_p = 0
  ,parameter link_width_p = "inv"
  ,parameter is_client_node_p = 0
  
  ,localparam width_lp = num_channels_p * channel_width_p
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(link_width_p)  
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

  ,input  [bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [bsg_ready_and_link_sif_width_lp-1:0] link_o
  );

  localparam lg_fifo_depth_lp = 3;

  genvar i;

  // Async fifo signals
  logic node_async_fifo_valid_li, node_async_fifo_yumi_lo;
  logic node_async_fifo_valid_lo, node_async_fifo_ready_li;

  logic [link_width_p-1:0] node_async_fifo_data_li;
  logic [link_width_p-1:0] node_async_fifo_data_lo;


  if (is_client_node_p == 0)
    begin: master
      /********************* Master node *********************/

      logic                             req_out_ready;
      logic [width_lp-1:0]              req_out_data;
      logic                             req_out_v;

      bsg_two_fifo
     #(.width_p(width_lp)
      ) req_out_fifo
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(req_out_ready)
      ,.v_i    (req_out_v)
      ,.data_i (req_out_data)

      ,.v_o    (node_async_fifo_valid_li)
      ,.data_o (node_async_fifo_data_li)
      ,.yumi_i (node_async_fifo_yumi_lo)
      );

      logic [width_lp-1:0] data_gen;

      test_bsg_data_gen
     #(.channel_width_p(channel_width_p)
      ,.num_channels_p(num_channels_p)
      ) gen_out
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)
      ,.yumi_i (req_out_v & req_out_ready)
      ,.o      (data_gen)
      );

      assign req_out_v               = node_en_i;
      assign req_out_data            = data_gen;

      // Count sent and received packets
      bsg_counter_clear_up
     #(.max_val_p(1<<32-1)
      ,.init_val_p(0)
      ) sent_count
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)
      ,.clear_i(1'b0)
      ,.up_i   (req_out_v & req_out_ready)
      ,.count_o(sent_o)
      );
    end
  else
    begin: client
      /********************* Client node *********************/

      logic                             resp_in_v;
      logic [width_lp-1:0]              resp_in_data;
      logic                             resp_in_yumi;
      
      bsg_serial_in_parallel_out_full
     #(.width_p(link_width_p)
      ,.els_p  (width_lp/link_width_p)
      ,.hi_to_lo_p(hi_to_lo_p)
      ) resp_in_sipof
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(node_async_fifo_ready_li)
      ,.v_i    (node_async_fifo_valid_lo)
      ,.data_i (node_async_fifo_data_lo)

      ,.v_o    (resp_in_v)
      ,.data_o (resp_in_data)
      ,.yumi_i (resp_in_yumi)
      );
      
      logic [width_lp-1:0] data_check;
      
      test_bsg_data_gen
     #(.channel_width_p(channel_width_p)
      ,.num_channels_p(num_channels_p)
      ) gen_in
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)
      ,.yumi_i (resp_in_v)
      ,.o      (data_check)
      );

      assign resp_in_yumi = resp_in_v;
      
      bsg_counter_clear_up
     #(.max_val_p(1<<32-1)
      ,.init_val_p(0)
      ) received_count
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)
      ,.clear_i(1'b0)
      ,.up_i   (resp_in_v)
      ,.count_o(received_o)
      );
      
      // Check errors
      always_ff @(posedge node_clk_i)
        if (node_reset_i)
            error_o <= 0;
        else
            if (resp_in_v && data_check != resp_in_data)
              begin
                $error("%m mismatched resp data %x %x",data_check, resp_in_data);
                error_o <= 1;
              end
    end


  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(link_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_i_cast, link_o_cast;

  assign link_i_cast = link_i;
  assign link_o = link_o_cast;


  /********************* Async fifo to link *********************/

  // Node side async fifo input
  logic  node_async_fifo_full_lo;
  assign node_async_fifo_yumi_lo = ~node_async_fifo_full_lo & node_async_fifo_valid_li;

  // Node side async fifo output
  logic  node_async_fifo_deq_li;
  assign node_async_fifo_deq_li = node_async_fifo_ready_li & node_async_fifo_valid_lo;

  // Link side async fifo input
  logic  link_async_fifo_full_lo;
  assign link_o_cast.ready_and_rev = ~link_async_fifo_full_lo;

  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (link_width_p)
  ) wh_to_mc
  (.w_clk_i  (clk_i)
  ,.w_reset_i(reset_i)
  ,.w_enq_i  (link_i_cast.v & link_o_cast.ready_and_rev)
  ,.w_data_i (link_i_cast.data)
  ,.w_full_o (link_async_fifo_full_lo)

  ,.r_clk_i  (node_clk_i)
  ,.r_reset_i(node_reset_i)
  ,.r_deq_i  (node_async_fifo_deq_li)
  ,.r_data_o (node_async_fifo_data_lo)
  ,.r_valid_o(node_async_fifo_valid_lo)
  );

  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (link_width_p)
  ) mc_to_wh
  (.w_clk_i  (node_clk_i)
  ,.w_reset_i(node_reset_i)
  ,.w_enq_i  (node_async_fifo_yumi_lo)
  ,.w_data_i (node_async_fifo_data_li)
  ,.w_full_o (node_async_fifo_full_lo)

  ,.r_clk_i  (clk_i)
  ,.r_reset_i(reset_i)
  ,.r_deq_i  (link_o_cast.v & link_i_cast.ready_and_rev)
  ,.r_data_o (link_o_cast.data)
  ,.r_valid_o(link_o_cast.v)
  );

endmodule

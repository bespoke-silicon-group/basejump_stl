
//
// Paul Gao 08/2019
//
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

`define declare_bsg_wormhole_concentrator_test_node_s(cid_width, load_width, header_struct_name, in_struct_name) \
  typedef struct packed {                                                      \
    logic [load_width-1:0]     load;                                           \
    logic [cid_width-1:0]      src_cid;                                        \
    logic [cid_width-1:0]      cid;                                            \
    header_struct_name         hdr;                                            \
  } in_struct_name

module bsg_wormhole_concentrator_test_node

 #(// Wormhole link parameters
   parameter flit_width_p = "inv"
  ,parameter cord_width_p = 5
  ,parameter len_width_p = "inv"
  ,parameter cid_width_p = "inv"

  ,parameter num_channels_p = "inv"
  ,parameter channel_width_p = "inv"
  ,parameter is_client_node_p = 0

  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(flit_width_p)  
  )

  (// Node side
   input node_clk_i
  ,input node_reset_i
  ,input node_en_i

  ,output logic  error_o
  ,output [31:0] sent_o
  ,output [31:0] received_o

  // Wormhole side
  ,input clk_i
  ,input reset_i

  ,input [cord_width_p-1:0] my_cord_i
  ,input [cord_width_p-1:0] dest_cord_i
  
  ,input [cid_width_p-1:0] my_cid_i
  ,input [cid_width_p-1:0] dest_cid_i

  ,input  [bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [bsg_ready_and_link_sif_width_lp-1:0] link_o
  );

  localparam lg_fifo_depth_lp = 3;
  localparam width_lp = num_channels_p * channel_width_p;

  genvar i;

  /********************* Packet definition *********************/
  
  `declare_bsg_wormhole_router_header_s(cord_width_p,len_width_p,bsg_wormhole_router_header_s);

  // Define wormhole packets
  `declare_bsg_wormhole_concentrator_test_node_s(cid_width_p, width_lp, bsg_wormhole_router_header_s, wormhole_concentrator_test_node_s);

  // Wormhole packet width
  localparam wh_width_lp = $bits(wormhole_concentrator_test_node_s);

  // Determine PISO and SIPOF convertion ratio
  localparam wh_ratio_lp = `BSG_CDIV(wh_width_lp, flit_width_p);

  // synopsys translate_off
  initial
  begin
    assert (len_width_p >= `BSG_SAFE_CLOG2(wh_ratio_lp))
    else $error("Wormhole packet len width %d is too narrow for ratio %d. Please increase len width.", len_width_p, wh_ratio_lp);
  end
  // synopsys translate_on

  // wormhole packets
  wormhole_concentrator_test_node_s node_piso_data_li_cast, node_sipof_data_lo_cast;
  
  logic node_piso_valid_li, node_piso_ready_lo;
  logic node_sipof_valid_lo, node_sipof_ready_li;


  if (is_client_node_p == 0)
    begin: master
      /********************* Master node *********************/

      logic                             resp_in_v;
      wormhole_concentrator_test_node_s resp_in_data;
      logic                             resp_in_yumi;

      logic                             req_out_ready;
      wormhole_concentrator_test_node_s req_out_data;
      logic                             req_out_v;

      bsg_two_fifo
     #(.width_p(wh_width_lp)
      ) resp_in_fifo
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(node_sipof_ready_li)
      ,.v_i    (node_sipof_valid_lo)
      ,.data_i (node_sipof_data_lo_cast)

      ,.v_o    (resp_in_v)
      ,.data_o (resp_in_data)
      ,.yumi_i (resp_in_yumi)
      );

      bsg_two_fifo
     #(.width_p(wh_width_lp)
      ) req_out_fifo
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(req_out_ready)
      ,.v_i    (req_out_v)
      ,.data_i (req_out_data)

      ,.v_o    (node_piso_valid_li)
      ,.data_o (node_piso_data_li_cast)
      ,.yumi_i (node_piso_valid_li & node_piso_ready_lo)
      );


      logic [width_lp-1:0] data_gen, data_check;

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
      assign req_out_data.hdr.cord   = dest_cord_i;
      assign req_out_data.hdr.len    = wh_ratio_lp-1;
      assign req_out_data.cid        = dest_cid_i;
      assign req_out_data.src_cid    = my_cid_i;
      assign req_out_data.load       = {'0, data_gen};

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
            if (resp_in_v && data_check != resp_in_data.load[width_lp-1:0])
              begin
                $error("%m mismatched resp data %x %x",data_check, resp_in_data.load[width_lp-1:0]);
                error_o <= 1;
              end
            else if (resp_in_v && !(my_cord_i == resp_in_data.hdr.cord))
              begin
                $error("%m mismatched resp cord %x %x", my_cord_i, resp_in_data.hdr.cord);
                error_o <= 1;
              end
            else if (resp_in_v && !(my_cid_i == resp_in_data.cid))
              begin
                $error("%m mismatched resp cid %x %x", my_cid_i, resp_in_data.cid);
                error_o <= 1;
              end 
    end
  else
    begin: client
      /********************* Client node *********************/

      logic                             req_in_v;
      wormhole_concentrator_test_node_s req_in_data;
      logic                             req_in_yumi;

      logic                             resp_out_ready;
      wormhole_concentrator_test_node_s resp_out_data;
      logic                             resp_out_v;

      bsg_two_fifo
     #(.width_p(wh_width_lp)
      ) req_in_fifo
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(node_sipof_ready_li)
      ,.v_i    (node_sipof_valid_lo)
      ,.data_i (node_sipof_data_lo_cast)

      ,.v_o    (req_in_v)
      ,.data_o (req_in_data)
      ,.yumi_i (req_in_yumi)
      );

      // loopback any data received
      assign resp_out_data.hdr.cord   = dest_cord_i;
      assign resp_out_data.hdr.len    = wh_ratio_lp-1;
      assign resp_out_data.cid        = req_in_data.src_cid;
      assign resp_out_data.src_cid    = my_cid_i;
      assign resp_out_data.load       = {'0, req_in_data.load[width_lp-1:0]};

      assign resp_out_v = req_in_v;
      assign req_in_yumi = resp_out_v & resp_out_ready;

      bsg_two_fifo
     #(.width_p(wh_width_lp)
      ) resp_out_fifo
      (.clk_i  (node_clk_i)
      ,.reset_i(node_reset_i)

      ,.ready_o(resp_out_ready)
      ,.v_i    (resp_out_v)
      ,.data_i (resp_out_data)

      ,.v_o    (node_piso_valid_li)
      ,.data_o (node_piso_data_li_cast)
      ,.yumi_i (node_piso_valid_li & node_piso_ready_lo)
      );
    end
  

  /********************* SIPOF and PISO *********************/

  // PISO and SIPOF signals
  logic [wh_ratio_lp*flit_width_p-1:0] node_piso_data_li, node_sipof_data_lo;

  assign node_piso_data_li       = {'0, node_piso_data_li_cast};
  assign node_sipof_data_lo_cast = node_sipof_data_lo[wh_width_lp-1:0];

  // Async fifo signals
  logic node_async_fifo_valid_li, node_async_fifo_yumi_lo;
  logic node_async_fifo_valid_lo, node_async_fifo_ready_li;

  logic [flit_width_p-1:0] node_async_fifo_data_li;
  logic [flit_width_p-1:0] node_async_fifo_data_lo;

  // fwd link piso and sipof
  bsg_parallel_in_serial_out
 #(.width_p(flit_width_p)
  ,.els_p  (wh_ratio_lp )
  ) piso
  (.clk_i  (node_clk_i  )
  ,.reset_i(node_reset_i)
  ,.valid_i(node_piso_valid_li)
  ,.data_i (node_piso_data_li )
  ,.ready_and_o(node_piso_ready_lo)
  ,.valid_o(node_async_fifo_valid_li)
  ,.data_o (node_async_fifo_data_li )
  ,.yumi_i (node_async_fifo_yumi_lo )
  );

  bsg_serial_in_parallel_out_full
 #(.width_p(flit_width_p)
  ,.els_p  (wh_ratio_lp )
  ) sipof
  (.clk_i  (node_clk_i  )
  ,.reset_i(node_reset_i)
  ,.v_i    (node_async_fifo_valid_lo)
  ,.ready_o(node_async_fifo_ready_li)
  ,.data_i (node_async_fifo_data_lo )
  ,.data_o (node_sipof_data_lo )
  ,.v_o    (node_sipof_valid_lo)
  ,.yumi_i (node_sipof_valid_lo & node_sipof_ready_li)
  );


  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_i_cast, link_o_cast;

  assign link_i_cast = link_i;
  assign link_o = link_o_cast;


  /********************* Async fifo to wormhole link *********************/

  // Node side async fifo input
  logic  node_async_fifo_full_lo;
  assign node_async_fifo_yumi_lo = ~node_async_fifo_full_lo & node_async_fifo_valid_li;

  // Node side async fifo output
  logic  node_async_fifo_deq_li;
  assign node_async_fifo_deq_li = node_async_fifo_ready_li & node_async_fifo_valid_lo;

  // Wormhole side async fifo input
  logic  wh_async_fifo_full_lo;
  assign link_o_cast.ready_and_rev = ~wh_async_fifo_full_lo;

  // This async fifo crosses from wormhole clock to node clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p)
  ) wh_to_mc
  (.w_clk_i  (clk_i)
  ,.w_reset_i(reset_i)
  ,.w_enq_i  (link_i_cast.v & link_o_cast.ready_and_rev)
  ,.w_data_i (link_i_cast.data)
  ,.w_full_o (wh_async_fifo_full_lo)

  ,.r_clk_i  (node_clk_i)
  ,.r_reset_i(node_reset_i)
  ,.r_deq_i  (node_async_fifo_deq_li)
  ,.r_data_o (node_async_fifo_data_lo)
  ,.r_valid_o(node_async_fifo_valid_lo)
  );

  // This async fifo crosses from node clock to wormhole clock
  bsg_async_fifo
 #(.lg_size_p(lg_fifo_depth_lp)
  ,.width_p  (flit_width_p)
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

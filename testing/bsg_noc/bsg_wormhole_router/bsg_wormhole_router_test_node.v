
//
// Paul Gao 06/2019
//
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

`define declare_bsg_wormhole_router_test_node_s(x_cord_width, y_cord_width, load_width, header_struct_name, in_struct_name) \
  typedef struct packed {                                                      \
    logic [load_width-1:0]     load;                                           \
    logic [y_cord_width-1:0]   src_y_cord;                                     \
    logic [x_cord_width-1:0]   src_x_cord;                                     \
    header_struct_name         hdr;                                            \
  } in_struct_name

module bsg_wormhole_router_test_node

 #(// Wormhole link parameters
   parameter wormhole_width_p = "inv"
  ,parameter wormhole_x_cord_width_p = "inv"
  ,parameter wormhole_y_cord_width_p = "inv"
  ,parameter wormhole_len_width_p = "inv"

  ,parameter fwd_num_channels_p = "inv"
  ,parameter rev_num_channels_p = "inv"
  ,parameter channel_width_p = "inv"

  ,localparam num_nets_lp = 2
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(wormhole_width_p)
  )

  (// Node side
   input mc_clk_i
  ,input mc_reset_i
  ,input mc_en_i

  ,output logic  error_o
  ,output [31:0] sent_o
  ,output [31:0] received_o

  // Wormhole side
  ,input clk_i
  ,input reset_i

  ,input [wormhole_x_cord_width_p-1:0] my_x_i
  ,input [wormhole_y_cord_width_p-1:0] my_y_i

  ,input [wormhole_x_cord_width_p-1:0] dest_x_i
  ,input [wormhole_y_cord_width_p-1:0] dest_y_i

  ,input  [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  );

  localparam lg_fifo_depth_lp = 3;
  localparam fwd_packet_index_lp = 1;
  localparam rev_packet_index_lp = 0;

  localparam num_channels_lp = `BSG_MIN(fwd_num_channels_p, rev_num_channels_p);
  localparam width_lp = num_channels_lp * channel_width_p;
  localparam fwd_width_lp = fwd_num_channels_p * channel_width_p;
  localparam rev_width_lp = rev_num_channels_p * channel_width_p;

  genvar i;

//   `declare_bsg_wormhole_router_header_s(wormhole_x_cord_width_p+wormhole_y_cord_width_p,wormhole_len_width_p,bsg_wormhole_router_header_s);
      `declare_bsg_wormhole_router_header_s(wormhole_x_cord_width_p,wormhole_len_width_p,bsg_wormhole_router_header_s);

  /********************* Packet definition *********************/

  // Define wormhole fwd and rev packets
  `declare_bsg_wormhole_router_test_node_s(wormhole_x_cord_width_p, wormhole_y_cord_width_p, fwd_width_lp, bsg_wormhole_router_header_s, fwd_wormhole_router_test_node_s);
  `declare_bsg_wormhole_router_test_node_s(wormhole_x_cord_width_p, wormhole_y_cord_width_p, rev_width_lp, bsg_wormhole_router_header_s, rev_wormhole_router_test_node_s);

  // Wormhole packet width
  localparam wh_fwd_width_lp = $bits(fwd_wormhole_router_test_node_s);
  localparam wh_rev_width_lp = $bits(rev_wormhole_router_test_node_s);

  // Determine PISO and SIPOF convertion ratio
  localparam wh_fwd_ratio_lp = `BSG_CDIV(wh_fwd_width_lp, wormhole_width_p);
  localparam wh_rev_ratio_lp = `BSG_CDIV(wh_rev_width_lp, wormhole_width_p);

  // synopsys translate_off
  initial
  begin
    assert (wormhole_len_width_p >= `BSG_SAFE_CLOG2(wh_fwd_ratio_lp))
    else $error("Wormhole packet len width %d is too narrow for fwd ratio %d. Please increase len width.", wormhole_len_width_p, wh_fwd_ratio_lp);

    assert (wormhole_len_width_p >= `BSG_SAFE_CLOG2(wh_rev_ratio_lp))
    else $error("Wormhole packet len width %d is too narrow for rev ratio %d. Please increase len width.", wormhole_len_width_p, wh_rev_ratio_lp);
  end
  // synopsys translate_on

  // fwd and rev wormhole packets
  fwd_wormhole_router_test_node_s mc_fwd_piso_data_li_cast, mc_fwd_sipof_data_lo_cast;
  rev_wormhole_router_test_node_s mc_rev_piso_data_li_cast, mc_rev_sipof_data_lo_cast;

  logic mc_fwd_piso_valid_li, mc_fwd_piso_ready_lo;
  logic mc_rev_piso_valid_li, mc_rev_piso_ready_lo;

  logic mc_fwd_sipof_valid_lo, mc_fwd_sipof_ready_li;
  logic mc_rev_sipof_valid_lo, mc_rev_sipof_ready_li;


  /********************* Master node *********************/

  logic                           resp_in_v;
  rev_wormhole_router_test_node_s resp_in_data;
  logic                           resp_in_yumi;

  logic                           req_out_ready;
  fwd_wormhole_router_test_node_s req_out_data;
  logic                           req_out_v;

  bsg_two_fifo
 #(.width_p(wh_rev_width_lp)
  ) resp_in_fifo
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)

  ,.ready_o(mc_rev_sipof_ready_li)
  ,.v_i    (mc_rev_sipof_valid_lo)
  ,.data_i (mc_rev_sipof_data_lo_cast)

  ,.v_o    (resp_in_v)
  ,.data_o (resp_in_data)
  ,.yumi_i (resp_in_yumi)
  );

  bsg_two_fifo
 #(.width_p(wh_fwd_width_lp)
  ) req_out_fifo
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)

  ,.ready_o(req_out_ready)
  ,.v_i    (req_out_v)
  ,.data_i (req_out_data)

  ,.v_o    (mc_fwd_piso_valid_li)
  ,.data_o (mc_fwd_piso_data_li_cast)
  ,.yumi_i (mc_fwd_piso_valid_li & mc_fwd_piso_ready_lo)
  );


  logic [width_lp-1:0] data_gen, data_check;

  test_bsg_data_gen
 #(.channel_width_p(channel_width_p)
  ,.num_channels_p(num_channels_lp)
  ) gen_out
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)
  ,.yumi_i (req_out_v & req_out_ready)
  ,.o      (data_gen)
  );

  assign req_out_v           = mc_en_i;
  assign req_out_data.hdr.cord[wormhole_x_cord_width_p-1:0] = dest_x_i;
//  assign req_out_data.hdr.cord[wormhole_x_cord_width_p+:wormhole_y_cord_width_p] = dest_y_i;
  assign req_out_data.hdr.len    = wh_fwd_ratio_lp-1;
  assign req_out_data.src_x_cord = my_x_i;
  assign req_out_data.src_y_cord = my_y_i;
  assign req_out_data.load   = {'0, data_gen};

  test_bsg_data_gen
 #(.channel_width_p(channel_width_p)
  ,.num_channels_p(num_channels_lp)
  ) gen_in
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)
  ,.yumi_i (resp_in_v)
  ,.o      (data_check)
  );

  assign resp_in_yumi = resp_in_v;

  // synopsys translate_off
  always_ff @(negedge mc_clk_i)
    if (resp_in_v & ~mc_reset_i)
      begin
        assert(data_check == resp_in_data.load[width_lp-1:0])
        else $error("check mismatch %x %x ", data_check,resp_in_data[width_lp-1:0]);

//        assert({my_y_i[wormhole_y_cord_width_p-1:0], my_x_i[wormhole_x_cord_width_p-1:0]} == resp_in_data.hdr.cord)
        assert(my_x_i[wormhole_x_cord_width_p-1:0] == resp_in_data.hdr.cord)
        else $error("Master: packet is routed to wrong destination!");
      end
  // synopsys translate_on

  // Count sent and received packets
  bsg_counter_clear_up
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ) sent_count
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (req_out_v & req_out_ready)
  ,.count_o(sent_o)
  );

  bsg_counter_clear_up
 #(.max_val_p(1<<32-1)
  ,.init_val_p(0)
  ) received_count
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)
  ,.clear_i(1'b0)
  ,.up_i   (resp_in_v)
  ,.count_o(received_o)
  );

  /********************* Slave node *********************/

  logic                           req_in_v;
  fwd_wormhole_router_test_node_s req_in_data;
  logic                           req_in_yumi;

  logic                           resp_out_ready;
  rev_wormhole_router_test_node_s resp_out_data;
  logic                           resp_out_v;

  bsg_two_fifo
 #(.width_p(wh_fwd_width_lp)
  ) req_in_fifo
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)

  ,.ready_o(mc_fwd_sipof_ready_li)
  ,.v_i    (mc_fwd_sipof_valid_lo)
  ,.data_i (mc_fwd_sipof_data_lo_cast)

  ,.v_o    (req_in_v)
  ,.data_o (req_in_data)
  ,.yumi_i (req_in_yumi)
  );

  // loopback any data received
  assign resp_out_data.hdr.cord = { // req_in_data.src_y_cord  [wormhole_y_cord_width_p-1:0] ,
                                    req_in_data.src_x_cord[wormhole_x_cord_width_p-1:0]};
  assign resp_out_data.hdr.len    = wh_rev_ratio_lp-1;
  assign resp_out_data.src_x_cord = my_x_i;
  assign resp_out_data.src_y_cord = my_y_i;
  assign resp_out_data.load = {'0, req_in_data.load[width_lp-1:0]};

  assign resp_out_v = req_in_v;
  assign req_in_yumi = resp_out_v & resp_out_ready;

  bsg_two_fifo
 #(.width_p(wh_rev_width_lp)
  ) resp_out_fifo
  (.clk_i  (mc_clk_i)
  ,.reset_i(mc_reset_i)

  ,.ready_o(resp_out_ready)
  ,.v_i    (resp_out_v)
  ,.data_i (resp_out_data)

  ,.v_o    (mc_rev_piso_valid_li)
  ,.data_o (mc_rev_piso_data_li_cast)
  ,.yumi_i (mc_rev_piso_valid_li & mc_rev_piso_ready_lo)
  );

  // synopsys translate_off
  always_ff @(negedge mc_clk_i)
    if (req_in_yumi & ~mc_reset_i)
      begin
//        assert({my_y_i[wormhole_y_cord_width_p-1:0], my_x_i[wormhole_x_cord_width_p-1:0]}  == req_in_data.hdr.cord)
      assert(my_x_i[wormhole_x_cord_width_p-1:0]  == req_in_data.hdr.cord)
        else $error("%m Slave: packet is routed to wrong destination! %b %b != %b (pkt=%h)"
                    , my_y_i, my_x_i, req_in_data.hdr.cord, req_in_data);
      end
  // synopsys translate_on


  /********************* Check error *********************/

  always_ff @(posedge mc_clk_i)
  if (mc_reset_i)
    error_o <= 0;
  else
    if (resp_in_v && data_check != resp_in_data.load[width_lp-1:0])
      begin
         $display("%m mismatched resp data %x %x",data_check,  resp_in_data.load[width_lp-1:0]);
        error_o <= 1;
      end
//    else if (resp_in_v && !({my_y_i, my_x_i} == resp_in_data.hdr.cord))
    else if (resp_in_v && !({my_x_i} == resp_in_data.hdr.cord))   
      begin
         $display("%m mismatched resp cord %x %x",{my_y_i[wormhole_y_cord_width_p-1:0], my_x_i[wormhole_x_cord_width_p-1:0]} , resp_in_data.hdr.cord);
        error_o <= 1;
      end
//    else if (req_in_yumi && !({my_y_i, my_x_i} == req_in_data.hdr.cord))
    else if (req_in_yumi && !(my_x_i == req_in_data.hdr.cord))
      begin
         $display("%m mismatched req cord %x %x",{my_y_i[wormhole_y_cord_width_p-1:0], my_x_i[wormhole_x_cord_width_p-1:0]} , req_in_data.hdr.cord);
        error_o <= 1;
      end
    else
      if (resp_in_v)
         $display("%m packet matched resp! %h",resp_in_data);
      else
        if (req_in_yumi)
          $display("%m packet matched req ! %h",req_in_data);



  /********************* SIPOF and PISO *********************/

  // PISO and SIPOF signals
  logic [wh_fwd_ratio_lp*wormhole_width_p-1:0] mc_fwd_piso_data_li, mc_fwd_sipof_data_lo;
  logic [wh_rev_ratio_lp*wormhole_width_p-1:0] mc_rev_piso_data_li, mc_rev_sipof_data_lo;

  assign mc_fwd_piso_data_li       = {'0, mc_fwd_piso_data_li_cast};
  assign mc_rev_piso_data_li       = {'0, mc_rev_piso_data_li_cast};
  assign mc_fwd_sipof_data_lo_cast = mc_fwd_sipof_data_lo[wh_fwd_width_lp-1:0];
  assign mc_rev_sipof_data_lo_cast = mc_rev_sipof_data_lo[wh_rev_width_lp-1:0];

  // Async fifo signals
  logic [num_nets_lp-1:0] mc_async_fifo_valid_li, mc_async_fifo_yumi_lo;
  logic [num_nets_lp-1:0] mc_async_fifo_valid_lo, mc_async_fifo_ready_li;

  logic [num_nets_lp-1:0][wormhole_width_p-1:0] mc_async_fifo_data_li;
  logic [num_nets_lp-1:0][wormhole_width_p-1:0] mc_async_fifo_data_lo;

  // fwd link piso and sipof
  bsg_parallel_in_serial_out
 #(.width_p(wormhole_width_p)
  ,.els_p  (wh_fwd_ratio_lp )
  ) fwd_piso
  (.clk_i  (mc_clk_i  )
  ,.reset_i(mc_reset_i)
  ,.valid_i(mc_fwd_piso_valid_li)
  ,.data_i (mc_fwd_piso_data_li )
  ,.ready_o(mc_fwd_piso_ready_lo)
  ,.valid_o(mc_async_fifo_valid_li[fwd_packet_index_lp])
  ,.data_o (mc_async_fifo_data_li [fwd_packet_index_lp])
  ,.yumi_i (mc_async_fifo_yumi_lo [fwd_packet_index_lp])
  );

  bsg_serial_in_parallel_out_full
 #(.width_p(wormhole_width_p)
  ,.els_p  (wh_fwd_ratio_lp )
  ) fwd_sipof
  (.clk_i  (mc_clk_i  )
  ,.reset_i(mc_reset_i)
  ,.v_i    (mc_async_fifo_valid_lo[fwd_packet_index_lp])
  ,.ready_o(mc_async_fifo_ready_li[fwd_packet_index_lp])
  ,.data_i (mc_async_fifo_data_lo [fwd_packet_index_lp])
  ,.data_o (mc_fwd_sipof_data_lo )
  ,.v_o    (mc_fwd_sipof_valid_lo)
  ,.yumi_i (mc_fwd_sipof_valid_lo & mc_fwd_sipof_ready_li)
  );

  // rev link piso and sipof
  bsg_parallel_in_serial_out
 #(.width_p(wormhole_width_p)
  ,.els_p  (wh_rev_ratio_lp )
  ) rev_piso
  (.clk_i  (mc_clk_i  )
  ,.reset_i(mc_reset_i)
  ,.valid_i(mc_rev_piso_valid_li)
  ,.data_i (mc_rev_piso_data_li )
  ,.ready_o(mc_rev_piso_ready_lo)
  ,.valid_o(mc_async_fifo_valid_li[rev_packet_index_lp])
  ,.data_o (mc_async_fifo_data_li [rev_packet_index_lp])
  ,.yumi_i (mc_async_fifo_yumi_lo [rev_packet_index_lp])
  );

  bsg_serial_in_parallel_out_full
 #(.width_p(wormhole_width_p)
  ,.els_p  (wh_rev_ratio_lp )
  ) rev_sipof
  (.clk_i  (mc_clk_i  )
  ,.reset_i(mc_reset_i)
  ,.v_i    (mc_async_fifo_valid_lo[rev_packet_index_lp])
  ,.ready_o(mc_async_fifo_ready_li[rev_packet_index_lp])
  ,.data_i (mc_async_fifo_data_lo [rev_packet_index_lp])
  ,.data_o (mc_rev_sipof_data_lo )
  ,.v_o    (mc_rev_sipof_valid_lo)
  ,.yumi_i (mc_rev_sipof_valid_lo & mc_fwd_sipof_ready_li)
  );


  /********************* Async fifo to wormhole link *********************/

  // Wormhole side signals
  logic [num_nets_lp-1:0] valid_lo, ready_li;
  logic [num_nets_lp-1:0][wormhole_width_p-1:0] data_lo;

  logic [num_nets_lp-1:0] valid_li, ready_lo;
  logic [num_nets_lp-1:0][wormhole_width_p-1:0] data_li;

  // Manycore side async fifo input
  logic [num_nets_lp-1:0] mc_async_fifo_full_lo;
  assign mc_async_fifo_yumi_lo = ~mc_async_fifo_full_lo & mc_async_fifo_valid_li;

  // Manycore side async fifo output
  logic [num_nets_lp-1:0] mc_async_fifo_deq_li;
  assign mc_async_fifo_deq_li = mc_async_fifo_ready_li & mc_async_fifo_valid_lo;

  // Wormhole side async fifo input
  logic [num_nets_lp-1:0] wh_async_fifo_full_lo;
  assign ready_lo = ~wh_async_fifo_full_lo;

  for (i = 0; i < num_nets_lp; i++)
  begin: afifo
    // This async fifo crosses from wormhole clock to manycore clock
    bsg_async_fifo
   #(.lg_size_p(lg_fifo_depth_lp)
    ,.width_p  (wormhole_width_p)
    ) wh_to_mc
    (.w_clk_i  (clk_i)
    ,.w_reset_i(reset_i)
    ,.w_enq_i  (valid_li[i] & ready_lo[i])
    ,.w_data_i (data_li[i])
    ,.w_full_o (wh_async_fifo_full_lo[i])

    ,.r_clk_i  (mc_clk_i)
    ,.r_reset_i(mc_reset_i)
    ,.r_deq_i  (mc_async_fifo_deq_li[i])
    ,.r_data_o (mc_async_fifo_data_lo[i])
    ,.r_valid_o(mc_async_fifo_valid_lo[i])
    );

    // This async fifo crosses from manycore clock to wormhole clock
    bsg_async_fifo
   #(.lg_size_p(lg_fifo_depth_lp)
    ,.width_p  (wormhole_width_p)
    ) mc_to_wh
    (.w_clk_i  (mc_clk_i)
    ,.w_reset_i(mc_reset_i)
    ,.w_enq_i  (mc_async_fifo_yumi_lo[i])
    ,.w_data_i (mc_async_fifo_data_li[i])
    ,.w_full_o (mc_async_fifo_full_lo[i])

    ,.r_clk_i  (clk_i)
    ,.r_reset_i(reset_i)
    ,.r_deq_i  (valid_lo[i] & ready_li[i])
    ,.r_data_o (data_lo[i])
    ,.r_valid_o(valid_lo[i])
    );
  end


  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(wormhole_width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_nets_lp-1:0] link_i_cast, link_o_cast;

  for (i = 0; i < num_nets_lp; i++)
  begin: noc_cast
    assign link_i_cast[i]               = link_i[i];
    assign link_o[i]                    = link_o_cast[i];

    assign valid_li[i]                  = link_i_cast[i].v;
    assign data_li[i]                   = link_i_cast[i].data;
    assign link_o_cast[i].ready_and_rev = ready_lo[i];

    assign link_o_cast[i].v             = valid_lo[i];
    assign link_o_cast[i].data          = data_lo[i];
    assign ready_li[i]                  = link_i_cast[i].ready_and_rev;
  end

endmodule

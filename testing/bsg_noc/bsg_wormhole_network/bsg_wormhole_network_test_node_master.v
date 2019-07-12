
//
// Paul Gao 06/2019
//
//

`include "bsg_noc_links.vh"
`include "bsg_wormhole_router.vh"

module bsg_wormhole_router_test_node_master

 #(// Wormhole link parameters
   parameter flit_width_p = "inv"
  ,parameter dims_p = 2
  ,parameter int cord_markers_pos_p[dims_p:0] = '{5, 4, 0}
  ,parameter len_width_p = "inv"

  ,parameter num_channels_p = "inv"
  ,parameter channel_width_p = "inv"

  ,localparam num_nets_lp = 2
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(flit_width_p)  
  ,localparam cord_width_lp = cord_markers_pos_p[dims_p]
  )

  (// Node side
   input clk_i
  ,input reset_i
  ,input [num_nets_lp-1:0] en_i

  ,output logic [num_nets_lp-1:0] error_o
  ,output logic [num_nets_lp-1:0][31:0] sent_o
  ,output logic [num_nets_lp-1:0][31:0] received_o

  // Wormhole side
  ,input [cord_width_lp-1:0] dest_cord_i

  ,input  [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [num_nets_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  );

  localparam width_lp = num_channels_p * channel_width_p;

  genvar i;

  /********************* Packet definition *********************/
  
  `declare_bsg_wormhole_router_header_s(cord_width_lp,len_width_p,bsg_wormhole_router_header_s);

  typedef struct packed {
    logic [flit_width_p-$bits(bsg_wormhole_router_header_s)-1:0] data;
    bsg_wormhole_router_header_s  hdr;
  } wormhole_network_header_flit_s;
  
  // synopsys translate_off
  initial
  begin
    assert ($bits(wormhole_network_header_flit_s)-$bits(bsg_wormhole_router_header_s) >= width_lp)
    else $error("Packet data width %d is too narrow for data width %d.", $bits(wormhole_network_header_flit_s)-$bits(bsg_wormhole_router_header_s), width_lp);
  end
  // synopsys translate_on
  
  
  /********************* Interfacing bsg_noc link *********************/

  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_nets_lp-1:0] link_i_cast, link_o_cast;

  for (i = 0; i < num_nets_lp; i++)
  begin: noc_cast
    assign link_i_cast[i]               = link_i[i];
    assign link_o[i]                    = link_o_cast[i];
  end  


  /********************* Master nodes (two of them) *********************/

  // ATTENTION: This loopback node is not using fwd and rev networks as usual.
  // fwd_link_o sends out fwd packets, rev_link_i receives loopback packets.
  // rev_link_o also sends out fwd packets, fwd_link_i receives loopback packets.

  for (i = 0; i < num_nets_lp; i++)
  begin: mstr

    logic                          resp_in_v;
    wormhole_network_header_flit_s resp_in_data;
    logic                          resp_in_yumi;

    logic                          req_out_ready;
    wormhole_network_header_flit_s req_out_data;
    logic                          req_out_v;

    bsg_one_fifo
   #(.width_p(flit_width_p)
    ) resp_in_fifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(link_o_cast[i].ready_and_rev)
    ,.v_i    (link_i_cast[i].v)
    ,.data_i (link_i_cast[i].data)

    ,.v_o    (resp_in_v)
    ,.data_o (resp_in_data)
    ,.yumi_i (resp_in_yumi)
    );

    bsg_one_fifo
   #(.width_p(flit_width_p)
    ) req_out_fifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(req_out_ready)
    ,.v_i    (req_out_v)
    ,.data_i (req_out_data)

    ,.v_o    (link_o_cast[i].v)
    ,.data_o (link_o_cast[i].data)
    ,.yumi_i (link_o_cast[i].v & link_i_cast[i].ready_and_rev)
    );

    logic [width_lp-1:0] data_gen, data_check;

    test_bsg_data_gen
   #(.channel_width_p(channel_width_p)
    ,.num_channels_p(num_channels_p)
    ) gen_out
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.yumi_i (req_out_v & req_out_ready)
    ,.o      (data_gen)
    );

    assign req_out_v               = en_i[i];
    assign req_out_data.hdr.cord   = dest_cord_i;
    assign req_out_data.hdr.len    = 0;
    assign req_out_data.data       = {'0, data_gen};

    test_bsg_data_gen
   #(.channel_width_p(channel_width_p)
    ,.num_channels_p(num_channels_p)
    ) gen_in
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.yumi_i (resp_in_v)
    ,.o      (data_check)
    );

    assign resp_in_yumi = resp_in_v;

    // Count sent and received packets
    bsg_counter_clear_up
   #(.max_val_p(1<<32-1)
    ,.init_val_p(0)
    ) sent_count
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(1'b0)
    ,.up_i   (req_out_v & req_out_ready)
    ,.count_o(sent_o[i])
    );

    bsg_counter_clear_up
   #(.max_val_p(1<<32-1)
    ,.init_val_p(0)
    ) received_count
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.clear_i(1'b0)
    ,.up_i   (resp_in_v)
    ,.count_o(received_o[i])
    );
    
    always_ff @(posedge clk_i)
        if (reset_i)
            error_o[i] <= 0;
        else
            if (resp_in_v && data_check != (width_lp'(resp_in_data.data)))
              begin
                $error("%m mismatched resp data %x %x",data_check, resp_in_data.data[width_lp-1:0]);
                error_o[i] <= 1;
              end
  end

endmodule

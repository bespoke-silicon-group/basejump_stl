//
// Paul Gao 03/2019
// 
// This module is a special version bsg_channel_tunnel that accepts wormhole packet
//
// Typical usage: When there are n wormhole routers (n wormhole networks)
// and need to merge them together to the IO channel (n >= 2)
// All wormhole packet parameters should match corresponding wormhole network
//
// Packet interleaving algorithm:
//
// When multiple source channels are valid at the same time, channel tunnel will interleave
// whole-packets in round-robin way. "whole-packet" means that flits of each wormhole 
// packet are always sent out back-to-back. 
//
// Implications:
//
// 1. It will NOT switch to next wormhole packet before previous one finish sending
// 2. Fairness is addressed in terms of number of wormhole packet transmitted, which
//    is independent of number of flits transmitted. Longer packet always takes 
//    up more bandwidth on multiplexed side.
// 3. Data buffer on receiver side takes longest possible wormhole packet into 
//    consideration, so it will never be filled up.
//
// *Refer to bsg_channel_tunnel for more information on credit-based flow control
//
//

/***************** Example data-paths for 2 inputs / outputs ****************************
  
            +-------+
            |Counter|
            +-------+
                /|                    +-----------+                 +-------+
  Input 1      + +------------------->+  OFIFO 1  +-------------+   |  Reg  |
 ------------->+ |                    +-----------+             |   +-------+
               + +--------+                                     |   |Counter|
                \|        |           +-----------+             |   +-------+
            +-------+  +------------->+  OFIFO 2  +-----------+ |      |\
            |Counter|  |  |           +-----------+           | +----->+ +
            +-------+  |  |                                   |        | |  Multi Output
                /|     |  |                                   +------->+ +-------------->
  Input 2      + +-----+  |  +-----------------------------+           | |
 ------------->+ |        +->+                             |    +----->+ +
               + +----+      |                             +----+      +/
                \+    +----->+                             |
                             |      BSG Channel Tunnel     |
                /+    +------+                             |
  Output 1     + +<---+      |                             +<---+      +\
 <-------------+ |        +--+                             |    +------+ +
               + +<----+  |  +-----------------------------+           | |  Multi Input
                \|     |  |                                   +--------+ +<-------------+
            +-------+  |  |                                   |        | |
            |Counter|  |  |           +-----------+           | +------+ +
            +-------+  +--------------+  IFIFO 1  +<----------+ |      |/
                /|        |           +-----------+             |   +-------+
  Output 2     + +<-------+                                     |   |Counter|
 <-------------+ |                    +-----------+             |   +-------+
               + +<-------------------+  IFIFO 2  +<------------+   |  Reg  |
                \|                    +-----------+                 +-------+
            +-------+
            |Counter|
            +-------+
  
****************************************************************************************/

`include "bsg_defines.v"
`include "bsg_noc_links.vh"

module  bsg_channel_tunnel_wormhole

 #(// Wormhole packet configurations
   // These parameters are properties of wormhole network
   parameter width_p          = "inv"
  ,parameter x_cord_width_p   = "inv"
  ,parameter y_cord_width_p   = "inv"
  ,parameter len_width_p      = "inv"
  ,parameter reserved_width_p = "inv"
  
  // Total number of inputs multiplexed / demultiplexed within channel tunnel
  // Typically this should match number of wormhole traffic streams being merged
  ,parameter num_in_p = "inv"
  
  // Max number of wormhole packets buffer can store
  // This is independent of how many flits each wormhole packet has
  ,parameter remote_credits_p = "inv"
  
  // Max possible "wormhole packet payload length" setting
  // An n-flits wormhole packet has 1 header flit and (n-1) payload flits
  // This parameter determines the size of payload-flits buffer
  ,parameter max_payload_flits_p = "inv"
  
  // How often does channel tunnel return credits to sender
  // Default value matches child module bsg_channel_tunnel
  // Channel tunnel return credits to sender every (2^lg_credit_decimation_p) packets
  // This is independent of how many flits each wormhole packet has
  ,parameter lg_credit_decimation_p = `BSG_MIN($clog2(remote_credits_p+1),4)
  
  // Use pseudo large fifo when read / write utilization is less than 50%
  // Given IO frequency f_io, number of IO channel num_ch, IO channel width io_width_p, 
  // the utilization can be calculated by:
  //
  //   utilization = (io_width_p*num_ch*f_io)/(width_p*f_clk_i)
  //
  // When f_clk_i > (2*io_width_p*num_ch*f_io)/(width_p), utilization is less than 50%
  ,parameter use_pseudo_large_fifo_p = 1
  
  // Local parameters
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p)
  )

  (input clk_i
  ,input reset_i
  
  // incoming multiplexed data
  ,input  [width_p-1:0] multi_data_i
  ,input                multi_v_i
  ,output               multi_ready_o

  // outgoing multiplexed data
  ,output [width_p-1:0] multi_data_o
  ,output               multi_v_o
  ,input                multi_yumi_i

  // demultiplexed data
  ,input  [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  );
  
  // Initial value for wormhole flit counters
  // Since wormhole length is (num_flits-1), counter should count from 0
  localparam counter_min_value_lp = 0;
  // Mux has one more input from original channel tunnel
  localparam mux_num_in_lp = num_in_p+1;
  localparam tag_width_lp  = $clog2(mux_num_in_lp);
  localparam raw_width_lp  = width_p-tag_width_lp;
  
  // Data structures for wormhole packet
  `declare_bsg_header_flit_s(width_p, reserved_width_p, x_cord_width_p, y_cord_width_p, len_width_p, header_flit_s);
  // Data structures for remapped wormhole packet
  `declare_bsg_channel_tunnel_header_flit_s(width_p, reserved_width_p, x_cord_width_p, y_cord_width_p, len_width_p, channel_tunnel_header_flit_s);
 
/*************************** Original Channel Tunnel ****************************/

  logic outside_valid_li, outside_yumi_lo;
  channel_tunnel_header_flit_s outside_data_li;
  
  logic outside_valid_lo, outside_yumi_li;
  channel_tunnel_header_flit_s outside_data_lo;
  
  logic [num_in_p-1:0] inside_valid_li, inside_yumi_lo;
  logic [num_in_p-1:0][raw_width_lp-1:0] ct_inside_data_li;
  
  logic [num_in_p-1:0] inside_valid_lo, inside_yumi_li;
  logic [num_in_p-1:0][raw_width_lp-1:0] ct_inside_data_lo;
  
  bsg_channel_tunnel
 #(.width_p(raw_width_lp)
  ,.num_in_p(num_in_p)
  ,.remote_credits_p(remote_credits_p)
  ,.use_pseudo_large_fifo_p(use_pseudo_large_fifo_p)
  ,.lg_credit_decimation_p(lg_credit_decimation_p)
  ) channel_tunnel
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)
  // outside
  ,.multi_data_i(outside_data_li)
  ,.multi_v_i   (outside_valid_li)
  ,.multi_yumi_o(outside_yumi_lo)

  ,.multi_data_o(outside_data_lo)
  ,.multi_v_o   (outside_valid_lo)
  ,.multi_yumi_i(outside_yumi_li)
  // inside
  ,.data_i(ct_inside_data_li)
  ,.v_i   (inside_valid_li)
  ,.yumi_o(inside_yumi_lo)

  ,.data_o(ct_inside_data_lo)
  ,.v_o   (inside_valid_lo)
  ,.yumi_i(inside_yumi_li)
  );
  
/*************************** Wormhole Packet Swizzle ****************************/

  // In wormhole packet structure, reserved bits are not on msb
  // Original channel tunnel appends tag to high bits
  // Need to swizzle header flit to move reserved bits to msb

  genvar i;

`define wormhole_swizzle(dest, src)       \
    assign dest.x_cord   = src.x_cord;    \
    assign dest.y_cord   = src.y_cord;    \
    assign dest.len      = src.len;       \
    assign dest.data     = src.data;      \
    assign dest.reserved = src.reserved // no semicolon 

  channel_tunnel_header_flit_s [num_in_p-1:0] ct_inside_data_li_cast,  ct_inside_data_lo_cast;
  header_flit_s [num_in_p-1:0] inside_data_li, inside_data_lo;
  
  for (i = 0; i < num_in_p; i++)
  begin: swizzle
    assign ct_inside_data_li     [i] = ct_inside_data_li_cast[i][raw_width_lp-1:0];
    assign ct_inside_data_lo_cast[i] = {'0, ct_inside_data_lo[i]};
    
    `wormhole_swizzle(ct_inside_data_li_cast[i], inside_data_li[i]);
    `wormhole_swizzle(inside_data_lo[i], ct_inside_data_lo_cast[i]);
  end
  
  channel_tunnel_header_flit_s multi_data_i_cast, multi_data_o_cast;
  assign multi_data_i_cast = multi_data_i;
  assign multi_data_o_cast = multi_data_o;
  
/*************************** BSG NOC Link Interface ****************************/

  logic [num_in_p-1:0] v_lo, yumi_li;
  header_flit_s [num_in_p-1:0] data_lo;
  
  logic [num_in_p-1:0] v_li, ready_lo;
  header_flit_s [num_in_p-1:0] data_li;
  
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_in_p-1:0] link_i_cast, link_o_cast;
  
  for (i = 0; i < num_in_p; i++) 
  begin: noc_cast
  
    assign link_i_cast[i]               = link_i[i];
    assign link_o[i]                    = link_o_cast[i];

    assign v_li[i]                      = link_i_cast[i].v;
    assign data_li[i]                   = link_i_cast[i].data;
    assign link_o_cast[i].ready_and_rev = ready_lo[i];

    assign link_o_cast[i].v             = v_lo[i];
    assign link_o_cast[i].data          = data_lo[i];
    assign yumi_li[i]                   = v_lo[i] & link_i_cast[i].ready_and_rev;
  
  end 
  
/*************************** Channel Tunnel Output ****************************/
  
  logic [mux_num_in_lp-1:0] ofifo_valid_lo, ofifo_yumi_li;
  logic [mux_num_in_lp-1:0][width_p-1:0] ofifo_data_lo;
  
  // This generated block is for wormhole packet flits buffering.
  // All wormhole packet headers are pushed into o_headerin fifo, then
  // go into original bsg_channel_tunnel.
  // Remaining data packet flits are buffered in ofifo.
  // A counter is used to handle the wormhole packet flits
  
  for (i = 0; i < num_in_p; i++) 
  begin: ch_out
  
    // Counter for demultiplexed wormhole packet input
    logic [len_width_p-1:0] ocount_r;
    logic ocount_r_is_min_lo, ocount_set_lo, ocount_down_lo;
    
    // Update counter only when packet flit is accepted into fifo
    // Set counter value to "wormhole packet len" when current flit is header flit
    assign ocount_set_lo      = v_li[i] & ready_lo[i] & ocount_r_is_min_lo; 
    assign ocount_down_lo     = v_li[i] & ready_lo[i] & ~ocount_r_is_min_lo; 
    assign ocount_r_is_min_lo = (ocount_r == counter_min_value_lp);
    
    bsg_counter_set_down
   #(.width_p   (len_width_p)
    ,.init_val_p(counter_min_value_lp)
    ,.set_and_down_exclusive_p(1)
    )
    ocount
    (.clk_i     (clk_i)
    ,.reset_i   (reset_i)
    ,.set_i     (ocount_set_lo)
    ,.val_i     (data_li[i].len)
    ,.down_i    (ocount_down_lo)
    ,.count_r_o (ocount_r)
    );
    
    // Data flit fifo
    //
    // ofifo size should be larger than 2 (default value is set to 4).
    // This is because there are two-cycle delay for wormhole header flit to
    // show up on the other side of channel tunnel.
    // To keep sending without bubble, ofifo must be large enough.
    logic ofifo_data_valid_li, ofifo_data_ready_lo;
    
    bsg_fifo_1r1w_small 
   #(.width_p(width_p)
    ,.els_p(4)
    ) ofifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ofifo_data_ready_lo)
    ,.data_i (data_li[i])
    ,.v_i    (ofifo_data_valid_li)

    ,.v_o    (ofifo_valid_lo[i])
    ,.data_o (ofifo_data_lo[i])
    ,.yumi_i (ofifo_yumi_li[i])
    );
    
    // Header flit fifo, going into bsg_channel_tunnel
    logic o_headerin_valid_li, o_headerin_ready_lo;
    
    bsg_two_fifo
   #(.width_p(width_p)
    ) o_headerin
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(o_headerin_ready_lo)
    ,.data_i (data_li[i])
    ,.v_i    (o_headerin_valid_li)

    ,.v_o    (inside_valid_li[i])
    ,.data_o (inside_data_li[i])
    ,.yumi_i (inside_yumi_lo[i])
    );
    
    // Demux splitting header flit and data flit traffic
    assign ofifo_data_valid_li = v_li[i] & ~ocount_r_is_min_lo;
    assign o_headerin_valid_li = v_li[i] &  ocount_r_is_min_lo;
    
    assign ready_lo[i] = (ocount_r_is_min_lo)? o_headerin_ready_lo : ofifo_data_ready_lo;

  end  
  
  // Header out of channel tunnel are buffered in bsg_two_fifo
  // TODO: might be removed later to reduce latency
  
  logic o_headerout_ready_lo;
  assign outside_yumi_li = o_headerout_ready_lo & outside_valid_lo;
  
  bsg_two_fifo 
 #(.width_p(width_p)
  ) o_headerout
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(o_headerout_ready_lo)
  ,.data_i (outside_data_lo)
  ,.v_i    (outside_valid_lo)

  ,.v_o    (ofifo_valid_lo[num_in_p])
  ,.data_o (ofifo_data_lo[num_in_p])
  ,.yumi_i (ofifo_yumi_li[num_in_p])
  );  
  
  // Channel Tunnel Output Multiplexing
  
  // Description of algorithm:
  // This is the main part for traffic multiplexing.
  // There are (n+1) streams of traffic: n ofifos and 1 channel tunnel.
  // The wormhole header flit comes out from channel tunnel, which selects the traffic.
  // Then data flits are poped out from selected ofifo, until the whole packet is sent.
  // Credit returning packet also come out from channel tunnel, which is a 1-flit packet.
  
  logic [tag_width_lp-1:0] multi_data_o_tag;
  logic [len_width_p-1:0]  multi_data_o_len;
  logic                    multi_data_o_is_credit;
  
  assign multi_data_o_tag       =  multi_data_o_cast[raw_width_lp+:tag_width_lp];
  assign multi_data_o_len       =  multi_data_o_cast.len;
  assign multi_data_o_is_credit = (multi_data_o_tag == num_in_p);
  
  // Counter for multiplexed output
  logic [len_width_p-1:0] ostate_r;
  logic ostate_r_is_min_lo, ostate_set_lo, ostate_down_lo;
  
  // Update counter only when packet flit dequeue from fifo
  // and upcoming packet is not for credit returning
  assign ostate_down_lo     = multi_yumi_i & ~ostate_r_is_min_lo;
  assign ostate_set_lo      = multi_yumi_i & ostate_r_is_min_lo & ~multi_data_o_is_credit;
  assign ostate_r_is_min_lo = (ostate_r == counter_min_value_lp);
  
  bsg_counter_set_down
 #(.width_p   (len_width_p)
  ,.init_val_p(counter_min_value_lp)
  ,.set_and_down_exclusive_p(1)
  )
  ostate
  (.clk_i    (clk_i)
  ,.reset_i  (reset_i)
  ,.set_i    (ostate_set_lo)
  ,.val_i    (multi_data_o_len)
  ,.down_i   (ostate_down_lo)
  ,.count_r_o(ostate_r)
  );
  
  // Register fifo selection
  logic [tag_width_lp-1:0] ofifo_sel_r;
  
  bsg_dff_reset_en 
 #(.width_p    (tag_width_lp)
  ,.reset_val_p(0)
  ) ofifo_reg
  (.clk_i      (clk_i)
  ,.reset_i    (reset_i)
  ,.data_i     (multi_data_o_tag)
  ,.en_i       (ostate_set_lo)
  ,.data_o     (ofifo_sel_r)
  );
  
  // Header flits come from channel tunnel
  // Data flits come from selected ofifos
  logic [tag_width_lp-1:0] omux_sel_lo;
  assign omux_sel_lo = (ostate_r_is_min_lo)? num_in_p : ofifo_sel_r;
  
  // data selection
  bsg_mux 
 #(.width_p(width_p)
  ,.els_p(mux_num_in_lp)
  ) out_data_mux
  (.data_i(ofifo_data_lo)
  ,.sel_i (omux_sel_lo)
  ,.data_o(multi_data_o)
  );
  
  // valid selection
  bsg_mux 
 #(.width_p(1)
  ,.els_p(mux_num_in_lp)
  ) out_v_mux
  (.data_i(ofifo_valid_lo)
  ,.sel_i (omux_sel_lo)
  ,.data_o(multi_v_o)
  );
  
  // yumi selection (valid-then-ready)
  bsg_decode_with_v 
 #(.num_out_p(mux_num_in_lp)
  ) out_yumi_bdwv
  (.i  (omux_sel_lo)
  ,.v_i(multi_yumi_i)
  ,.o  (ofifo_yumi_li)
  );
  
/*************************** Channel Tunnel Input ****************************/
  
  logic [mux_num_in_lp-1:0] ififo_valid_li, ififo_ready_lo; 
  
  // Channel Tunnel Multiplexed Input Demux
  
  // Description of algorithm:
  // This is the main part for traffic demultiplexing.
  // Traffic coming in has (n+1) possible destinations: n ififos and 1 channel tunnel.
  // Wormhole header flits and credit returning flit should go into channel tunnel.
  // Data flits should go into corresponding ififos.
  // Destination is selected by "reserved bits" generated by sender.
  
  logic multi_data_i_is_credit;
  logic [tag_width_lp-1:0] multi_data_i_tag;
  logic [len_width_p-1:0]  multi_data_i_len;
  
  assign multi_data_i_tag       =  multi_data_i_cast[raw_width_lp+:tag_width_lp];
  assign multi_data_i_len       =  multi_data_i_cast.len;
  assign multi_data_i_is_credit = (multi_data_i_tag == num_in_p);
  
  // Counter for multiplexed input
  logic [len_width_p-1:0] istate_r;
  logic istate_r_is_min_lo, istate_set_lo, istate_down_lo;
  
  // Update counter only when packet flit accepted to fifo
  // and upcoming packet is not for credit returning
  assign istate_down_lo     = multi_v_i & multi_ready_o & ~istate_r_is_min_lo;
  assign istate_set_lo      = multi_v_i & multi_ready_o & istate_r_is_min_lo 
                             & ~multi_data_i_is_credit;
  assign istate_r_is_min_lo = (istate_r == counter_min_value_lp);
  
  bsg_counter_set_down
 #(.width_p   (len_width_p)
  ,.init_val_p(counter_min_value_lp)
  ,.set_and_down_exclusive_p(1)
  )
  istate
  (.clk_i    (clk_i)
  ,.reset_i  (reset_i)
  ,.set_i    (istate_set_lo)
  ,.val_i    (multi_data_i_len)
  ,.down_i   (istate_down_lo)
  ,.count_r_o(istate_r)
  );
  
  // Register fifo selection
  logic [tag_width_lp-1:0] ififo_sel_r;
  
  bsg_dff_reset_en 
 #(.width_p    (tag_width_lp)
  ,.reset_val_p(0)
  ) ififo_reg
  (.clk_i      (clk_i)
  ,.reset_i    (reset_i)
  ,.data_i     (multi_data_i_tag)
  ,.en_i       (istate_set_lo)
  ,.data_o     (ififo_sel_r)
  );
  
  // Header flits come from channel tunnel
  // Data flits come from selected ofifos
  logic [tag_width_lp-1:0] imux_sel_lo;
  assign imux_sel_lo = (istate_r_is_min_lo)? num_in_p : ififo_sel_r;
  
  // ready selection
  bsg_mux 
 #(.width_p(1)
  ,.els_p(mux_num_in_lp)
  ) in_ready_mux
  (.data_i(ififo_ready_lo)
  ,.sel_i (imux_sel_lo)
  ,.data_o(multi_ready_o)
  );
  
  // valid selection
  bsg_decode_with_v
 #(.num_out_p(mux_num_in_lp)
  ) in_valid_bdwv
  (.i  (imux_sel_lo)
  ,.v_i(multi_v_i)
  ,.o  (ififo_valid_li)
  ); 
  
  // Header flits going into channel tunnel are buffered in fifo
  // TODO: might be removed later to reduce latency
  
  bsg_two_fifo 
 #(.width_p(width_p)
  ) i_headerin
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(ififo_ready_lo[num_in_p])
  ,.data_i (multi_data_i)
  ,.v_i    (ififo_valid_li[num_in_p])

  ,.v_o    (outside_valid_li)
  ,.data_o (outside_data_li)
  ,.yumi_i (outside_yumi_lo)
  );
  
  // This generated block is for wormhole data flits buffering.
  // All wormhole packet headers are stored in bsg_channel_tunnel.
  // Remaining data packet flits are buffered in ififo.
  // A counter is used to handle the wormhole packet flits
  
  for (i = 0; i < num_in_p; i++) 
  begin: ch_in
  
    logic ififo_valid_lo, ififo_yumi_li;
    logic [width_p-1:0] ififo_data_lo;
    
    // This large fifo holds all data flits received from sender.
    // All wormhole header flits are stored inside bsg_channel_tunnel, so
    // the size of ififo should be ((max_num_flits-1) * remote_credits_p), which
    // is exactly (max_payload_flits_p * remote_credits_p).
    if (use_pseudo_large_fifo_p == 0)
      begin: use_large
        bsg_fifo_1r1w_large 
       #(.width_p(width_p)
        ,.els_p(remote_credits_p*max_payload_flits_p)
        ) ififo
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(ififo_ready_lo[i])
        ,.data_i (multi_data_i)
        ,.v_i    (ififo_valid_li[i])

        ,.v_o    (ififo_valid_lo)
        ,.data_o (ififo_data_lo)
        ,.yumi_i (ififo_yumi_li)
        );
      end
    else
      begin: pseudo_large
        bsg_fifo_1r1w_pseudo_large 
       #(.width_p(width_p)
        ,.els_p(remote_credits_p*max_payload_flits_p)
        ) ififo
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(ififo_ready_lo[i])
        ,.data_i (multi_data_i)
        ,.v_i    (ififo_valid_li[i])

        ,.v_o    (ififo_valid_lo)
        ,.data_o (ififo_data_lo)
        ,.yumi_i (ififo_yumi_li)
        );
      end
    
    logic [len_width_p-1:0] icount_r;
    logic icount_r_is_min_lo, icount_set_lo, icount_down_lo;
    
    // Update counter only when packet flit dequeues from fifo
    // Set counter value to "wormhole packet len" when current flit is header flit
    assign icount_set_lo      = yumi_li[i] & icount_r_is_min_lo;
    assign icount_down_lo     = yumi_li[i] & ~icount_r_is_min_lo;
    assign icount_r_is_min_lo = (icount_r == counter_min_value_lp);
    
    bsg_counter_set_down
   #(.width_p   (len_width_p)
    ,.init_val_p(counter_min_value_lp)
    ,.set_and_down_exclusive_p(1)
    )
    icount
    (.clk_i    (clk_i)
    ,.reset_i  (reset_i)
    ,.set_i    (icount_set_lo)
    ,.val_i    (inside_data_lo[i].len)
    ,.down_i   (icount_down_lo)
    ,.count_r_o(icount_r)
    );
    
    // Mux merging header flit and data flit
    assign v_lo[i]           = (icount_r_is_min_lo)? inside_valid_lo[i] : ififo_valid_lo;
    assign data_lo[i]        = (icount_r_is_min_lo)? inside_data_lo[i]  : ififo_data_lo;
    
    assign ififo_yumi_li     = (icount_r_is_min_lo)? 0 : yumi_li[i];
    assign inside_yumi_li[i] = (icount_r_is_min_lo)? yumi_li[i] : 0;
  
  end
  
/*************************** Debugging Information ****************************/
  
  // synopsys translate_off
  initial 
  begin
  
    assert (reserved_width_p >= tag_width_lp)
    else 
      begin 
        $error("Wormhole packet reserved width %d is smaller than channel tunnel tag width %d. Please increase reserved width.", reserved_width_p, tag_width_lp);
        $finish;
      end

  end
  // synopsys translate_on

endmodule
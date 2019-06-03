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
// packet are always sent out back-to-back. After sending out current packet, channel tunnel 
// will decide whether to switch to another source channel.
//
// Refer to bsg_channel_tunnel for more information on credit-based flow control
//
//

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
  
  // Local parameters
  
  // Initial value for wormhole flit counters
  // Since wormhole length is (num_flits-1), counter should count from 0
  ,localparam counter_min_value_lp = 0 
  
  ,localparam mux_num_in_lp = num_in_p+1
  ,localparam tag_width_lp = $clog2(mux_num_in_lp)
  ,localparam raw_width_lp = width_p-tag_width_lp
  ,localparam len_offset_lp = width_p-reserved_width_p-x_cord_width_p-y_cord_width_p-len_width_p
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
  
  
  // Original Channel Tunnel
  logic outside_valid_li, outside_yumi_lo;
  logic [width_p-1:0] outside_data_li;
  
  logic outside_valid_lo, outside_yumi_li;
  logic [width_p-1:0] outside_data_lo;
  
  logic [num_in_p-1:0] inside_valid_li, inside_yumi_lo;
  logic [num_in_p-1:0][raw_width_lp-1:0] inside_data_li;
  
  logic [num_in_p-1:0] inside_valid_lo, inside_yumi_li;
  logic [num_in_p-1:0][raw_width_lp-1:0] inside_data_lo;

  
  bsg_channel_tunnel
 #(.width_p(raw_width_lp)
  ,.num_in_p(num_in_p)
  ,.remote_credits_p(remote_credits_p)
  ,.use_pseudo_large_fifo_p(1)
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
  ,.data_i(inside_data_li)
  ,.v_i   (inside_valid_li)
  ,.yumi_o(inside_yumi_lo)

  ,.data_o(inside_data_lo)
  ,.v_o   (inside_valid_lo)
  ,.yumi_i(inside_yumi_li)
  );
  
  
  genvar i;
  
  
  // Interfacing bsg_noc links 

  logic [num_in_p-1:0] v_o, yumi_i;
  logic [num_in_p-1:0][width_p-1:0] data_o;
  
  logic [num_in_p-1:0] v_i, ready_o;
  logic [num_in_p-1:0][width_p-1:0] data_i;
  
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_in_p-1:0] link_i_cast, link_o_cast;
  
  for (i = 0; i < num_in_p; i++) 
  begin: noc_cast
  
    assign link_i_cast[i]               = link_i[i];
    assign link_o[i]                    = link_o_cast[i];

    assign v_i[i]                       = link_i_cast[i].v;
    assign data_i[i]                    = link_i_cast[i].data;
    assign link_o_cast[i].ready_and_rev = ready_o[i];

    assign link_o_cast[i].v             = v_o[i];
    assign link_o_cast[i].data          = data_o[i];
    assign yumi_i[i]                    = v_o[i] & link_i_cast[i].ready_and_rev;
  
  end
  
  
  // Channel Tunnel Data Output
  
  logic [mux_num_in_lp-1:0] ofifo_valid_o, ofifo_yumi_i;
  logic [mux_num_in_lp-1:0][width_p-1:0] ofifo_data_o;
  
  // This generated block is for wormhole packet flits buffering.
  // All wormhole packet headers are pushed into o_headerin fifo, then
  // go into original bsg_channel_tunnel.
  // Remaining data packet flits are buffered in ofifo.
  // A counter is used to handle the wormhole packet flits
  
  for (i = 0; i < num_in_p; i++) 
  begin: ch_out
  
    logic ofifo_data_ready_o, ofifo_header_ready_o;
  
    // Header to CT
    logic [len_width_p-1:0] ocount_r;
    logic ocount_r_is_min, ocount_en;
    
    // Update counter only when packet flit is accepted into fifo
    // Set counter value to "wormhole packet len" when current flit is header flit
    assign ocount_en = v_i[i] & ready_o[i]; 
    
    bsg_counter_dynamic_start_en_down
   #(.width_p(len_width_p)
    ,.last_val_p(counter_min_value_lp)
    ) ocount
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)
    ,.en_i         (ocount_en)
    ,.start_i      (data_i[i][len_offset_lp+:len_width_p])
    ,.counter_o    (ocount_r)
    ,.is_last_val_o(ocount_r_is_min)
    );
    
    // Data fifo
    
    // ofifo size should be larger than 2 (default value is set to 4).
    // This is because there are two-cycle delay for wormhole header flit to
    // show up on the other side of channel tunnel.
    // To keep sending without bubble, ofifo must be large enough.
    
    bsg_fifo_1r1w_small 
   #(.width_p(width_p)
    ,.els_p(4)
    ) ofifo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ofifo_data_ready_o)
    ,.data_i (data_i[i])
    ,.v_i    (~ocount_r_is_min & v_i[i])

    ,.v_o    (ofifo_valid_o[i])
    ,.data_o (ofifo_data_o[i])
    ,.yumi_i (ofifo_yumi_i[i])
    );
    
    // Header fifo
    
    bsg_two_fifo
   #(.width_p(raw_width_lp)
    ) o_headerin
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ofifo_header_ready_o)
    ,.data_i (data_i[i][raw_width_lp-1:0])
    ,.v_i    (ocount_r_is_min & v_i[i])

    ,.v_o    (inside_valid_li[i])
    ,.data_o (inside_data_li[i])
    ,.yumi_i (inside_yumi_lo[i])
    );
    
    assign ready_o[i] = (ocount_r_is_min)? ofifo_header_ready_o : ofifo_data_ready_o;

  end
  
  
  // Header out of channel tunnel are buffered in bsg_two_fifo
  // TODO: might be removed later to reduce latency
  
  logic headerout_ready_o;
  assign outside_yumi_li = headerout_ready_o & outside_valid_lo;
  
  bsg_two_fifo 
 #(.width_p(width_p)
  ) o_headerout
  (.clk_i(clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(headerout_ready_o)
  ,.data_i (outside_data_lo)
  ,.v_i    (outside_valid_lo)

  ,.v_o    (ofifo_valid_o[num_in_p])
  ,.data_o (ofifo_data_o[num_in_p])
  ,.yumi_i (ofifo_yumi_i[num_in_p])
  );
  
  
  // Channel Tunnel Output Select
  
  // Description of algorithm:
  // This is the main part for traffic multiplexing.
  // There are (n+1) streams of traffic: n ofifos and 1 channel tunnel.
  // The wormhole header flit comes out from channel tunnel, which selects the traffic.
  // Then data flits are poped out from selected ofifo, until the whole packet is sent.
  // Credit returning packet also come out from channel tunnel, which is a 1-flit packet.
  
  logic [tag_width_lp-1:0] mux_sel_r, mux_sel_n;
  logic [len_width_p-1:0]  ostate_r, ostate_n;
  
  always_ff @(posedge clk_i) 
  begin
    if (reset_i) 
      begin
        ostate_r  <= counter_min_value_lp;
        mux_sel_r <= num_in_p;
      end 
    else 
      begin
        ostate_r  <= ostate_n;
        mux_sel_r <= mux_sel_n;
      end
  end
  
  // data selection
  bsg_mux 
 #(.width_p(width_p)
  ,.els_p(mux_num_in_lp)
  ) out_data_mux
  (.data_i(ofifo_data_o)
  ,.sel_i (mux_sel_r)
  ,.data_o(multi_data_o)
  );
  
  // valid selection
  bsg_mux 
 #(.width_p(1)
  ,.els_p(mux_num_in_lp)
  ) out_v_mux
  (.data_i(ofifo_valid_o)
  ,.sel_i (mux_sel_r)
  ,.data_o(multi_v_o)
  );
  
  // yumi selection (valid-then-ready)
  for (i = 0; i < mux_num_in_lp; i++) 
  begin: oyumi
    assign ofifo_yumi_i[i] = (i==mux_sel_r)? multi_yumi_i : 0;
  end
  
  // State machine to handle valid-data-yumi selection
  //
  // Initial state (or default state) selection is bsg_channel_tunnel
  // When a header flit come out from bsg_channel_tunnel, selection is updated based on
  // the source of upcoming wormhole packet (from which data buffer). After the whole packet is
  // sent, it returns to default state selection.
  // When a credit returning flit comes out, selection is not updated (it is a 1-flit packet).
  always_comb 
  begin
    
    ostate_n  = ostate_r;
    mux_sel_n = mux_sel_r;
    
    if (multi_yumi_i) 
        // When current wormhole packet finish sending
        // Return to default state
        if (ostate_r == 1) 
          begin
            mux_sel_n = num_in_p;
            ostate_n = ostate_r - 1;
          end
        // At default state
        // Send out wormhole packet header flit
        else if (ostate_r == counter_min_value_lp)
          begin
            // When upcoming packet is not for credit returning
            // Update state
            if (multi_data_o[raw_width_lp+:tag_width_lp] < num_in_p) 
              begin
                ostate_n = multi_data_o[len_offset_lp+:len_width_p];
                // When packet length is non-zero (payload flits non-zero)
                // Update ofifo selection
                if (multi_data_o[len_offset_lp+:len_width_p] != 0) 
                    mux_sel_n = multi_data_o[raw_width_lp+:tag_width_lp];
              end
          end
        // When sending out wormhole packet payload flits
        // Update state
        else
          begin
            ostate_n = ostate_r - 1;
          end
  
  end
  
  
  
  // Channel Tunnel Data Input
  
  logic [mux_num_in_lp-1:0] ififo_valid_i, ififo_ready_o;
  
  // This generated block is for wormhole data flits buffering.
  // All wormhole packet headers are stored in bsg_channel_tunnel.
  // Remaining data packet flits are buffered in ififo.
  // A counter is used to handle the wormhole packet flits
  
  for (i = 0; i < num_in_p; i++) 
  begin: ch_in
  
    logic ififo_valid_o, ififo_yumi_i;
    logic [width_p-1:0] ififo_data_o;
    
    // This large fifo holds all data flits received from sender.
    // All wormhole header flits are stored inside bsg_channel_tunnel, so
    // the size of ififo should be ((max_num_flits-1) * remote_credits_p), which
    // is exactly (max_payload_flits_p * remote_credits_p).
    bsg_fifo_1r1w_large 
   #(.width_p(width_p)
    ,.els_p(remote_credits_p*max_payload_flits_p)
    ) ififo
    (.clk_i  (clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ififo_ready_o[i])
    ,.data_i (multi_data_i)
    ,.v_i    (ififo_valid_i[i])

    ,.v_o    (ififo_valid_o)
    ,.data_o (ififo_data_o)
    ,.yumi_i (ififo_yumi_i)
    );
    
    // dummy data out of CT
    logic [len_width_p-1:0] icount_r;
    logic icount_r_is_min, icount_en;
    
    // Update counter only when packet flit dequeues from fifo
    // Set counter value to "wormhole packet len" when current flit is header flit
    assign icount_en = yumi_i[i];
    
    bsg_counter_dynamic_start_en_down
   #(.width_p(len_width_p)
    ,.last_val_p(counter_min_value_lp)
    ) icount
    (.clk_i        (clk_i)
    ,.reset_i      (reset_i)
    ,.en_i         (icount_en)
    ,.start_i      (inside_data_lo[i][len_offset_lp+:len_width_p])
    ,.counter_o    (icount_r)
    ,.is_last_val_o(icount_r_is_min)
    );
    
    // Decide whether to dequeue from channel tunnel or from ififo.
    assign v_o[i]            = (icount_r_is_min)? inside_valid_lo[i] : ififo_valid_o;
    assign data_o[i]         = (icount_r_is_min)? inside_data_lo[i] : ififo_data_o;
    assign ififo_yumi_i      = (icount_r_is_min)? 0 : yumi_i[i];
    assign inside_yumi_li[i] = (icount_r_is_min)? yumi_i[i] : 0;
  
  end
  
  
  // Header flits going into channel tunnel are buffered in fifo
  // TODO: might be removed later to reduce latency
  
  bsg_two_fifo 
 #(.width_p(width_p)
  ) i_dummyin
  (.clk_i  (clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(ififo_ready_o[num_in_p])
  ,.data_i (multi_data_i)
  ,.v_i    (ififo_valid_i[num_in_p])

  ,.v_o    (outside_valid_li)
  ,.data_o (outside_data_li)
  ,.yumi_i (outside_yumi_lo)
  );
  
  
  // Channel Tunnel Input Select
  
  // Description of algorithm:
  // This is the main part for traffic demultiplexing.
  // Traffic coming in has (n+1) possible destinations: n ififos and 1 channel tunnel.
  // Wormhole header flits and credit returning flit should go into channel tunnel.
  // Data flits should go into corresponding ififos.
  // Destination is selected by "reserved bits" generated by sender.
  
  logic [tag_width_lp-1:0] in_sel_r, in_sel_n;
  logic [len_width_p-1:0]  istate_r, istate_n;
  
  always_ff @(posedge clk_i) 
  begin
    if (reset_i) 
      begin
        istate_r <= counter_min_value_lp;
        in_sel_r <= num_in_p;
      end 
    else 
      begin
        istate_r <= istate_n;
        in_sel_r <= in_sel_n;
      end
  end
  
  // ready selection
  bsg_mux 
 #(.width_p(1)
  ,.els_p(mux_num_in_lp)
  ) in_ready_mux
  (.data_i(ififo_ready_o)
  ,.sel_i (in_sel_r)
  ,.data_o(multi_ready_o)
  );
  
  // valid selection
  for (i = 0; i < mux_num_in_lp; i++) 
  begin: iv
    assign ififo_valid_i[i] = (i==in_sel_r)? multi_v_i : 0;
  end
  
  
  // State machine to handle valid-ready selection
  //
  // Initial state (or default state) selection is to bsg_channel_tunnel
  // When a header flit come into bsg_channel_tunnel, selection is updated based on
  // the source of received wormhole packet (to which data buffer). After the whole packet is
  // received, it returns to default state selection.
  // When a credit returning flit ccomes in, selection is not updated (it is a 1-flit packet).
  always_comb 
  begin
    
    istate_n = istate_r;
    in_sel_n = in_sel_r;
    
    if (multi_v_i & multi_ready_o) 
        // When current wormhole packet finish receiving
        // Return to default state
        if (istate_r == (counter_min_value_lp+1)) 
          begin
            in_sel_n = num_in_p;
            istate_n = istate_r - 1;
          end
        // At default state
        // Receive wormhole packet header flit
        else if (istate_r == counter_min_value_lp) 
          begin
            // When received packet is not for credit returning
            // Update state
            if (multi_data_i[raw_width_lp+:tag_width_lp] < num_in_p) 
              begin
                istate_n = multi_data_i[len_offset_lp+:len_width_p];
                // When packet length is non-zero (payload flits non-zero)
                // Update ififo selection
                if (multi_data_i[len_offset_lp+:len_width_p] != 0)
                    in_sel_n = multi_data_i[raw_width_lp+:tag_width_lp];
              end
          end
        // When receiving wormhole packet payload flits
        // Update state
        else 
          begin
            istate_n = istate_r - 1;
          end
  
  end
  
  
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
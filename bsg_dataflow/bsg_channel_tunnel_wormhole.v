//
// Paul Gao 03/2019
//

`include "bsg_noc_links.vh"

module  bsg_channel_tunnel_wormhole

 #(// Wormhole packet configurations
   parameter width_p = "inv"
  ,parameter x_cord_width_p = "inv"
  ,parameter y_cord_width_p = "inv"
  ,parameter len_width_p = "inv"
  ,parameter reserved_width_p = "inv"
  
  // Total number of channels
  ,parameter num_in_p = "inv"
  
  // Max number of wormhole packets buffer can store
  ,parameter remote_credits_p = "inv"
  
  // Max possible number of wormhole packet flits
  ,parameter max_len_p = "inv"
  
  // How often (every ? wormhole packets) does channel tunnel return credits
  ,parameter lg_credit_decimation_p = "inv"
  
  // Local parameters
  ,localparam tag_width_lp = $clog2(num_in_p+1)
  ,localparam raw_width_lp = width_p-tag_width_lp
  ,localparam len_offset_lp = width_p-reserved_width_p
                    -x_cord_width_p-y_cord_width_p-len_width_p
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p))

  (input clk_i
  ,input reset_i
  
  // incoming multiplexed data
  ,input [width_p-1:0] multi_data_i
  ,input multi_v_i
  ,output multi_ready_o

  // outgoing multiplexed data
  ,output [width_p-1:0] multi_data_o
  ,output multi_v_o
  ,input multi_yumi_i

  // demultiplexed data
  ,input [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [num_in_p-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o);
  
  
  // Original Channel Tunnel
  logic outside_valid_i, outside_yumi_o;
  logic [width_p-1:0] outside_data_i;
  
  logic outside_valid_o, outside_yumi_i;
  logic [width_p-1:0] outside_data_o;
  
  logic [num_in_p-1:0] inside_valid_i, inside_yumi_o;
  logic [num_in_p-1:0][raw_width_lp-1:0] inside_data_i;
  
  logic [num_in_p-1:0] inside_valid_o, inside_yumi_i;
  logic [num_in_p-1:0][raw_width_lp-1:0] inside_data_o;

  
  bsg_channel_tunnel
 #(.width_p(raw_width_lp)
  ,.num_in_p(num_in_p)
  ,.remote_credits_p(remote_credits_p)
  ,.use_pseudo_large_fifo_p(1)
  ,.lg_credit_decimation_p(lg_credit_decimation_p))
  channel_tunnel
  (.clk_i(clk_i)
  ,.reset_i(reset_i)
  // outside
  ,.multi_data_i(outside_data_i)
  ,.multi_v_i(outside_valid_i)
  ,.multi_yumi_o(outside_yumi_o)

  ,.multi_data_o(outside_data_o)
  ,.multi_v_o(outside_valid_o)
  ,.multi_yumi_i(outside_yumi_i)
  // inside
  ,.data_i(inside_data_i)
  ,.v_i(inside_valid_i)
  ,.yumi_o(inside_yumi_o)

  ,.data_o(inside_data_o)
  ,.v_o(inside_valid_o)
  ,.yumi_i(inside_yumi_i));
  
  
  genvar i;
  
  
  // Interfacing bsg_noc links 

  logic [num_in_p-1:0] v_o, yumi_i;
  logic [num_in_p-1:0][width_p-1:0] data_o;
  
  logic [num_in_p-1:0] v_i, ready_o;
  logic [num_in_p-1:0][width_p-1:0] data_i;
  
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [num_in_p-1:0] link_i_cast, link_o_cast;
  
  for (i = 0; i < num_in_p; i++) begin
  
    assign link_i_cast[i] = link_i[i];
    assign link_o[i] = link_o_cast[i];

    assign v_i[i] = link_i_cast[i].v;
    assign data_i[i] = link_i_cast[i].data;
    assign link_o_cast[i].ready_and_rev = ready_o[i];

    assign link_o_cast[i].v = v_o[i];
    assign link_o_cast[i].data = data_o[i];
    assign yumi_i[i] = v_o[i] & link_i_cast[i].ready_and_rev;
  
  end
  
  
  // Channel Tunnel Data Output
  logic [num_in_p+1-1:0] ofifo_valid_o, ofifo_yumi_i;
  logic [num_in_p+1-1:0][width_p-1:0] ofifo_data_o;
  
  for (i = 0; i < num_in_p; i++) begin
  
    logic ofifo_data_ready_o, ofifo_header_ready_o;
  
    // Header to CT
    logic [len_width_p-1:0] ocount_r, ocount_n;
    assign ocount_n = (v_i[i] & ready_o[i])? 
        (ocount_r==0)? data_i[i][len_offset_lp+:len_width_p] : ocount_r-1 : ocount_r;
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            ocount_r <= 0;
        else
            ocount_r <= ocount_n;
    end
    
    // Data fifo
    bsg_fifo_1r1w_small 
   #(.width_p(width_p)
    ,.els_p(4)) 
    ofifo
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ofifo_data_ready_o)
    ,.data_i(data_i[i])
    ,.v_i(~(ocount_r==0) & v_i[i])

    ,.v_o(ofifo_valid_o[i])
    ,.data_o(ofifo_data_o[i])
    ,.yumi_i(ofifo_yumi_i[i]));
    
    // Header fifo
    bsg_two_fifo
   #(.width_p(raw_width_lp))
    o_headerin
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ofifo_header_ready_o)
    ,.data_i(data_i[i][raw_width_lp-1:0])
    ,.v_i((ocount_r==0) & v_i[i])

    ,.v_o(inside_valid_i[i])
    ,.data_o(inside_data_i[i])
    ,.yumi_i(inside_yumi_o[i]));
    
    assign ready_o[i] = (ocount_r==0)? ofifo_header_ready_o : ofifo_data_ready_o;

  end
  
  
  // Header out of CT
  // TODO: might be removed later to reduce latency
  
  logic headerout_ready_o;
  assign outside_yumi_i = headerout_ready_o & outside_valid_o;
  
  bsg_two_fifo 
 #(.width_p(width_p)) 
  o_headerout
  (.clk_i(clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(headerout_ready_o)
  ,.data_i(outside_data_o)
  ,.v_i(outside_valid_o)

  ,.v_o(ofifo_valid_o[num_in_p])
  ,.data_o(ofifo_data_o[num_in_p])
  ,.yumi_i(ofifo_yumi_i[num_in_p]));
  
  
  // Channel Tunnel Output Select
  logic [tag_width_lp-1:0] mux_sel_r, mux_sel_n;
  logic [len_width_p-1:0] ostate_r, ostate_n;
  
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
        ostate_r <= 0;
        mux_sel_r <= num_in_p;
    end else begin
        ostate_r <= ostate_n;
        mux_sel_r <= mux_sel_n;
    end
  end
  
  bsg_mux 
 #(.width_p(width_p)
  ,.els_p(num_in_p+1))
  out_data_mux
  (.data_i(ofifo_data_o)
  ,.sel_i(mux_sel_r)
  ,.data_o(multi_data_o));
  
  bsg_mux 
 #(.width_p(1)
  ,.els_p(num_in_p+1))
  out_v_mux
  (.data_i(ofifo_valid_o)
  ,.sel_i(mux_sel_r)
  ,.data_o(multi_v_o));
  
  for (i = 0; i < num_in_p+1; i++) begin
    assign ofifo_yumi_i[i] = (i==mux_sel_r)? multi_yumi_i : 0;
  end
  
  always_comb begin
    
    ostate_n = ostate_r;
    mux_sel_n = mux_sel_r;
    
    if (multi_yumi_i) begin
        if (ostate_r == 1) begin
            mux_sel_n = num_in_p;
            ostate_n = ostate_r - 1;
        end
        else if (ostate_r == 0) begin
            if (multi_data_o[raw_width_lp+:tag_width_lp] < num_in_p) begin
                ostate_n = multi_data_o[len_offset_lp+:len_width_p];
                if (multi_data_o[len_offset_lp+:len_width_p] != 0) begin
                    mux_sel_n = multi_data_o[raw_width_lp+:tag_width_lp];
                end
            end
        end
        else begin
            ostate_n = ostate_r - 1;
        end
    end
  
  end
  
  
  
  // Channel Tunnel Data Input
  logic [num_in_p+1-1:0] ififo_valid_i, ififo_ready_o;
  
  for (i = 0; i < num_in_p; i++) begin
  
    logic ififo_valid_o, ififo_yumi_i;
    logic [width_p-1:0] ififo_data_o;
    
    bsg_fifo_1r1w_large 
   #(.width_p(width_p)
    ,.els_p(remote_credits_p*max_len_p)) 
    ififo
    (.clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.ready_o(ififo_ready_o[i])
    ,.data_i(multi_data_i)
    ,.v_i(ififo_valid_i[i])

    ,.v_o(ififo_valid_o)
    ,.data_o(ififo_data_o)
    ,.yumi_i(ififo_yumi_i));
    
    // dummy data out of CT
    logic [len_width_p-1:0] icount_r, icount_n;
    assign icount_n = (yumi_i[i])? 
        (icount_r==0)? inside_data_o[i][len_offset_lp+:len_width_p] : icount_r-1 : icount_r;
    
    always_ff @(posedge clk_i) begin
        if (reset_i)
            icount_r <= 0;
        else
            icount_r <= icount_n;
    end
    
    assign v_o[i] = (icount_r==0)? inside_valid_o[i] : ififo_valid_o;
    assign data_o[i] = (icount_r==0)? inside_data_o[i] : ififo_data_o;
    assign ififo_yumi_i = (icount_r==0)? 0 : yumi_i[i];
    assign inside_yumi_i[i] = (icount_r==0)? yumi_i[i] : 0;
  
  end
  
  
  // Header into CT
  // TODO: might be removed later to reduce latency
  
  bsg_two_fifo 
 #(.width_p(width_p)) 
  i_dummyin
  (.clk_i(clk_i)
  ,.reset_i(reset_i)

  ,.ready_o(ififo_ready_o[num_in_p])
  ,.data_i(multi_data_i)
  ,.v_i(ififo_valid_i[num_in_p])

  ,.v_o(outside_valid_i)
  ,.data_o(outside_data_i)
  ,.yumi_i(outside_yumi_o));
  
  
  // Channel Tunnel Input Select
  logic [tag_width_lp-1:0] in_sel_r, in_sel_n;
  logic [len_width_p-1:0] istate_r, istate_n;
  
  always_ff @(posedge clk_i) begin
    if (reset_i) begin
        istate_r <= 0;
        in_sel_r <= num_in_p;
    end else begin
        istate_r <= istate_n;
        in_sel_r <= in_sel_n;
    end
  end
  
  bsg_mux 
 #(.width_p(1)
  ,.els_p(num_in_p+1))
  in_ready_mux
  (.data_i(ififo_ready_o)
  ,.sel_i(in_sel_r)
  ,.data_o(multi_ready_o));
  
  for (i = 0; i < num_in_p+1; i++) begin
    assign ififo_valid_i[i] = (i==in_sel_r)? multi_v_i : 0;
  end
  
  always_comb begin
    
    istate_n = istate_r;
    in_sel_n = in_sel_r;
    
    if (multi_v_i & multi_ready_o) begin
        if (istate_r == 1) begin
            in_sel_n = num_in_p;
            istate_n = istate_r - 1;
        end
        else if (istate_r == 0) begin
            if (multi_data_i[raw_width_lp+:tag_width_lp] < num_in_p) begin
                istate_n = multi_data_i[len_offset_lp+:len_width_p];
                if (multi_data_i[len_offset_lp+:len_width_p] != 0) begin
                    in_sel_n = multi_data_i[raw_width_lp+:tag_width_lp];
                end
            end
        end
        else begin
            istate_n = istate_r - 1;
        end
    end
  
  end
  
  
  // synopsys translate_off
  initial begin
  
    assert (reserved_width_p >= tag_width_lp)
    else begin 
        $error("Wormhole packet reserved width %d is smaller than channel tunnel tag width %d. Please increase reserved width.", reserved_width_p, tag_width_lp);
        $finish;
    end

  end
  // synopsys translate_on
  

endmodule
//
// Paul Gao 03/2019
//
// West has small x_cord, East has large x_cord
// North has small y_cord, south has large y_cord
//
// Direction index: P=0, W=1, E=2, N=3, S=4
// For 1D routing, should use P, W, E
//
// Wormhole packet length does not include first cycle
// If a wormhole packet takes n cycles to send, then length = (n-1)
//

`include "bsg_noc_links.vh"

module  bsg_wormhole_router

  // import enum Dirs for directions
  import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (local node)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south

 #(parameter width_p          = "inv"
  ,parameter x_cord_width_p   = "inv"
  ,parameter y_cord_width_p   = "inv"
  ,parameter len_width_p      = "inv"
  ,parameter reserved_width_p = 0
   
   // By default router only has Proc, West and East directions
   // Set enable_2d_routing_p=1 to enable North and South directions
  ,parameter enable_2d_routing_p = 1'b0
  
  // When enable_yx_routing_p==0, route WE direction then NS
  // Otherwise, route NS first then WE
  ,parameter enable_yx_routing_p = 1'b0
  
  // When header_on_lsb_p==1, header flit is {payload, reserved, length, y_cord, x_cord}
  // header_on_lsb_p==0 no longer supported
  // Leave this parameter here for backward compatibility
  ,parameter header_on_lsb_p = 1'b1
  
  // Local parameters
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p)
  ,localparam dirs_lp = (enable_2d_routing_p==0)? 3 : 5

  // Stub ports sequence: SNEWP
  ,parameter stub_in_p  = {dirs_lp{1'b0}}
  ,parameter stub_out_p = {dirs_lp{1'b0}})
  
  (input clk_i
  ,input reset_i
  
  // Wormhole links
  ,input  [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  
  // Configuration
  ,input [x_cord_width_p-1:0] my_x_i
  ,input [y_cord_width_p-1:0] my_y_i);
  
  // header_on_lsb_p==0 no longer supported
  initial 
  begin
    assert (header_on_lsb_p != 0)
    else 
      begin 
        $error("header_on_lsb_p==0 no longer supported.");
        $finish;
      end
  end
  
  genvar i, j;
  
  // Data structures for wormhole header flit
  `declare_bsg_header_flit_no_reserved_s(width_p, x_cord_width_p, y_cord_width_p, len_width_p, header_flit_s);
  header_flit_s [dirs_lp-1:0] data_li, data_lo;
  
  // Interfacing bsg_noc links 
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [dirs_lp-1:0] link_i_cast, link_o_cast;  
  
  for (i = 0; i < dirs_lp; i++)
  begin: link_cast
    `bsg_ready_and_link_sif_s_cast(link_i[i], link_o[i], link_i_cast[i], link_o_cast[i]);
    assign data_li[i] = link_i_cast[i].data;
    assign link_o_cast[i].data = data_lo[i];
  end

  // Input Data fifos
  logic [dirs_lp-1:0] fifo_valid_lo, fifo_yumi_li;
  header_flit_s [dirs_lp-1:0] fifo_data_lo;
  
  // stubbed ports accept all I/O and send none.
  logic [dirs_lp-1:0] ready_i_stub;
  
  for (i = 0; i < dirs_lp; i++)
  begin: ready_stub
    assign ready_i_stub[i] = link_i_cast[i].ready_and_rev | stub_out_p[i];
  end
  
  for (i = 0; i < dirs_lp; i++) 
  begin: in_fifo
    if (stub_in_p[i] == 0) 
      begin: no_stub
        bsg_two_fifo 
       #(.width_p(width_p)) 
        fifo
        (.clk_i  (clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(link_o_cast  [i].ready_and_rev)
        ,.data_i (data_li      [i])
        ,.v_i    (link_i_cast  [i].v)

        ,.v_o    (fifo_valid_lo[i])
        ,.data_o (fifo_data_lo [i])
        ,.yumi_i (fifo_yumi_li [i])
        );        
      end 
    else
      begin: stub
        assign fifo_valid_lo[i]               = 1'b0;
        assign fifo_data_lo [i]               = '0;
        assign link_o_cast  [i].ready_and_rev = 1'b1;
      end
  end
  
  // input length counter
  // TODO: replace with bsg generic counter
  logic [dirs_lp-1:0][len_width_p-1:0] in_count_r;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: in_count
    always @(posedge clk_i) 
        if (reset_i)
            in_count_r[i] <= len_width_p'(0);
        else
            if (fifo_yumi_li[i])
                if (in_count_r[i] == len_width_p'(0))
                    in_count_r[i] <= fifo_data_lo[i].len;
                else
                    in_count_r[i] <= in_count_r[i] - len_width_p'(1);
  end
  
  // destination registers
  logic [dirs_lp-1:0][dirs_lp-1:0] dest_r;
  logic [dirs_lp-1:0][dirs_lp-1:0] dest_n ;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: dest
    always @(posedge clk_i)
        dest_r[i] <= dest_n[i];
  end
  
  // new valid signals on input fifo side
  logic [dirs_lp-1:0][dirs_lp-1:0] new_valid;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: rof1
    for (j = 0; j < dirs_lp; j++) 
      begin: rof2
        assign new_valid[i][j] = fifo_valid_lo[i] & dest_n[i][j];
      end
  end
  
  // round robin arbiter wires
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_grants_o;

  // fifo yumi signals
  for (i = 0; i < dirs_lp; i++) 
  begin: rof3
    assign fifo_yumi_li[i] = | (arb_grants_o[i]);
  end

  // output length counter
  // TODO: replace with bsg generic counter
  logic [dirs_lp-1:0][len_width_p-1:0] out_count_r;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: out_count
    always @(posedge clk_i) 
        if (reset_i)
            out_count_r[i] <= len_width_p'(0);
        else
            if (link_o_cast[i].v & ready_i_stub[i])
                if (out_count_r[i] == len_width_p'(0))
                    out_count_r[i] <= data_lo[i].len;
                else
                    out_count_r[i] <= out_count_r[i] - len_width_p'(1);
  end

  // valid signals on arbiter side
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_valid ;
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_grants_r ;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: rof4
    for (j = 0; j < dirs_lp; j++) 
      begin: rof5
        always @(posedge clk_i) 
            if (out_count_r[j] == len_width_p'(0))
                arb_grants_r[i][j] <= arb_grants_o[i][j];
          
        assign arb_valid[i][j] = 
            (out_count_r[j] == len_width_p'(0))
            ? new_valid[i][j] 
            : new_valid[i][j] & arb_grants_r[i][j];  
    end
  end
  
  // mux select sequence parameter
  localparam LEN = 3;
  localparam COL = 4;
  localparam SEQ = {LEN'(N), LEN'(E), LEN'(W), LEN'(P)
                   ,LEN'(S), LEN'(E), LEN'(W), LEN'(P)
                   ,LEN'(S), LEN'(N), LEN'(W), LEN'(P)
                   ,LEN'(S), LEN'(N), LEN'(E), LEN'(P)
                   ,LEN'(S), LEN'(N), LEN'(E), LEN'(W)};
                                    
  // concatenated wires in mux_sel sequence
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_valid_concatenated;
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_grants_concatenated;
  logic [dirs_lp-1:0][dirs_lp-1:0] arb_sel_o;
  logic [dirs_lp-1:0][dirs_lp-1:0][width_p-1:0] fifo_data_concatenated;
  
  // W, E, N and S do not support loopback
  for (i = W; i < dirs_lp; i++) 
  begin: out_side
    for (j = 0; j < dirs_lp-1; j++) 
      begin: rof6
        localparam ORIG_DIR = SEQ[(i*LEN*COL+j*LEN)+:LEN];
        
        assign arb_valid_concatenated[i][j] = arb_valid       [ORIG_DIR][i];
        assign arb_grants_o   [ORIG_DIR][i] = arb_grants_concatenated[i][j];
        assign fifo_data_concatenated[i][j] = fifo_data_lo       [ORIG_DIR];
      end
    
    // round robin arbiter
    bsg_round_robin_arb 
   #(.inputs_p(dirs_lp-1))
    rr_arb
    (.clk_i      (clk_i)
    ,.reset_i    (reset_i)
    ,.grants_en_i(ready_i_stub[i])

    ,.reqs_i       (arb_valid_concatenated [i][dirs_lp-2:0])
    ,.grants_o     (arb_grants_concatenated[i][dirs_lp-2:0])
    ,.sel_one_hot_o(arb_sel_o              [i][dirs_lp-2:0])

    ,.v_o   (link_o_cast[i].v)
    ,.tag_o ()
    ,.yumi_i(link_o_cast[i].v & ready_i_stub[i])
    );
    
    // mux for output data
    bsg_mux_one_hot  
   #(.width_p(width_p)
    ,.els_p  (dirs_lp-1))
    mux
    (.data_i       (fifo_data_concatenated[i][dirs_lp-2:0])
    ,.sel_one_hot_i(arb_sel_o             [i][dirs_lp-2:0])
    ,.data_o       (data_lo               [i])
    );
    
    // Do not support loopback
    assign arb_grants_o[i][i] = 1'b0;
  end
  
  // Processor side support loopback
  for (j = 0; j < dirs_lp; j++) 
  begin: rof7
    assign arb_valid_concatenated[P][j] = arb_valid              [j][P];
    assign arb_grants_o          [j][P] = arb_grants_concatenated[P][j];
    assign fifo_data_concatenated[P][j] = fifo_data_lo           [j];
  end
    
  bsg_round_robin_arb 
 #(.inputs_p(dirs_lp))
  rr_arb_proc
  (.clk_i      (clk_i)
  ,.reset_i    (reset_i)
  ,.grants_en_i(ready_i_stub[P])

  ,.reqs_i       (arb_valid_concatenated [P][dirs_lp-1:0])
  ,.grants_o     (arb_grants_concatenated[P][dirs_lp-1:0])
  ,.sel_one_hot_o(arb_sel_o              [P][dirs_lp-1:0])

  ,.v_o   (link_o_cast[P].v)
  ,.tag_o ()
  ,.yumi_i(link_o_cast[P].v & ready_i_stub[P])
  );
    
  bsg_mux_one_hot  
 #(.width_p(width_p)
  ,.els_p  (dirs_lp))
  mux_proc
  (.data_i       (fifo_data_concatenated[P][dirs_lp-1:0])
  ,.sel_one_hot_i(arb_sel_o             [P][dirs_lp-1:0])
  ,.data_o       (data_lo               [P])
  );
  
  // destination id selection wires
  logic [dirs_lp-1:0][x_cord_width_p-1:0] fifo_dest_x;
  logic [dirs_lp-1:0][y_cord_width_p-1:0] fifo_dest_y;
  
  for (i = 0; i < dirs_lp; i++) 
  begin: rof8
    assign fifo_dest_x[i] = fifo_data_lo[i].x_cord;
    assign fifo_dest_y[i] = fifo_data_lo[i].y_cord;
  end

  // Destination Selection
  
  if (enable_2d_routing_p == 0) 
  begin: route_1d
  
    for (i = 0; i < dirs_lp; i++)
      begin: dirs
      
        always_comb 
          begin
            dest_n[i] = dest_r[i];
            if (in_count_r[i] == len_width_p'(0)) 
              begin
                dest_n[i] = {dirs_lp{1'b0}};
                if (fifo_dest_x[i] == my_x_i) dest_n[i][P] = 1'b1;
                if (fifo_dest_x[i] <  my_x_i) dest_n[i][W] = 1'b1;
                if (fifo_dest_x[i] >  my_x_i) dest_n[i][E] = 1'b1;
              end
          end
          
      end: dirs
      
  end: route_1d
  else 
  begin: route_2d
    if (enable_yx_routing_p == 0) 
      begin: route_xy
      
        for (i = 0; i < dirs_lp; i++) 
          begin: dirs
          
            always_comb 
              begin
                dest_n[i] = dest_r[i];
                if (in_count_r[i] == len_width_p'(0)) 
                  begin
                    dest_n[i] = {dirs_lp{1'b0}};
                    if (fifo_dest_x[i] == my_x_i) 
                      begin
                        if (fifo_dest_y[i] == my_y_i) dest_n[i][P] = 1'b1;
                        if (fifo_dest_y[i] <  my_y_i) dest_n[i][N] = 1'b1;
                        if (fifo_dest_y[i] >  my_y_i) dest_n[i][S] = 1'b1;
                      end
                    if (fifo_dest_x[i] < my_x_i) dest_n[i][W] = 1'b1;
                    if (fifo_dest_x[i] > my_x_i) dest_n[i][E] = 1'b1;
                  end
              end
              
          end: dirs
          
      end: route_xy 
    else 
      begin: route_yx
      
        for (i = 0; i < dirs_lp; i++) 
          begin: dirs
          
            always_comb
              begin
                dest_n[i] = dest_r[i];
                if (in_count_r[i] == len_width_p'(0)) 
                  begin
                    dest_n[i] = {dirs_lp{1'b0}};
                    if (fifo_dest_y[i] == my_y_i) 
                      begin
                        if (fifo_dest_x[i] == my_x_i) dest_n[i][P] = 1'b1;
                        if (fifo_dest_x[i] <  my_x_i) dest_n[i][W] = 1'b1;
                        if (fifo_dest_x[i] >  my_x_i) dest_n[i][E] = 1'b1;
                      end
                    if (fifo_dest_y[i] < my_y_i) dest_n[i][N] = 1'b1;
                    if (fifo_dest_y[i] > my_y_i) dest_n[i][S] = 1'b1;
                  end
              end
              
          end: dirs
          
      end : route_yx
  end : route_2d
  
  // synopsys translate_off
  initial begin
    assert(width_p >= x_cord_width_p+y_cord_width_p+len_width_p+reserved_width_p)
    else $error("width_p must be wider than header width!");
  end
  // synopsys translate_on
  
endmodule
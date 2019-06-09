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

 #(parameter width_p = "inv"
  ,parameter x_cord_width_p = "inv"
  ,parameter y_cord_width_p = "inv"
  ,parameter len_width_p = "inv"
 
  // MBT: reserved means that nobody should use it
  // MBT: this is more like extra header bits?
  ,parameter reserved_width_p = 0
   
  // MBT: dimensions_p = 0
  ,parameter enable_2d_routing_p = 1'b0
  
  // When enable_yx_routing_p==0, route WE direction then NS
  // Otherwise, route NS first then WE
  // MBT: use_yx_routing_p is more consistent with BaseJump STL style
  ,parameter enable_yx_routing_p = 1'b0
  
  // When header_on_lsb==0, first cycle is {reserved, x_cord, y_cord, length, payload}
  // Otherwise, first cycle is {payload, length, y_cord, x_cord, reserved}

   // MBT we should remove this parameter
   // who are you trying to be backward compatible with?
  ,parameter header_on_lsb_p = 1'b0
  
  // Local parameters
  ,localparam bsg_ready_and_link_sif_width_lp = `bsg_ready_and_link_sif_width(width_p)
  ,localparam dirs_lp = (enable_2d_routing_p==0)? 3 : 5

  // MBT: remove this bug_pront interface. People should only use the struct fields, so that we 
  // MBT: we can modify the struct and it will still work.
  ,localparam reserved_offset_lp = (header_on_lsb_p==0)? width_p-reserved_width_p : 0
  ,localparam x_cord_offset_lp = (header_on_lsb_p==0)? 
                    reserved_offset_lp-x_cord_width_p : reserved_offset_lp+reserved_width_p
  ,localparam y_cord_offset_lp = (header_on_lsb_p==0)?
                    x_cord_offset_lp-y_cord_width_p : x_cord_offset_lp+x_cord_width_p
  ,localparam len_offset_lp = (header_on_lsb_p==0)?
                    y_cord_offset_lp-len_width_p : y_cord_offset_lp+y_cord_width_p

  // Stub ports sequence: SNEWP
  ,parameter stub_in_p = {dirs_lp{1'b0}}
  ,parameter stub_out_p = {dirs_lp{1'b0}})
  
  (input clk_i
  ,input reset_i
  
  // Traffics
  ,input [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
  ,output [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o
  
  // Configuration
  ,input [x_cord_width_p-1:0] my_x_i
  ,input [y_cord_width_p-1:0] my_y_i);
  
  genvar i, j;
  
  // Interfacing bsg_noc links 
  
  logic [x_cord_width_p-1:0] local_x_cord_i;
  logic [y_cord_width_p-1:0] local_y_cord_i;
  
  assign local_x_cord_i = my_x_i;
  assign local_y_cord_i = my_y_i;

  logic [dirs_lp-1:0] valid_o, ready_i;
  logic [dirs_lp-1:0][width_p-1:0] data_o;
  
  logic [dirs_lp-1:0] valid_i, ready_o;
  logic [dirs_lp-1:0][width_p-1:0] data_i;
  
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  
  for (i = 0; i < dirs_lp; i++) 
    begin
      // MBT: let's factor this into a macro since it seems to be a very common case and we repeat a lot of code
      // MBT `bsg_ready_and_link_sif_s_cast (link_i, link_o, link_i_cast, link_o_cast)
      // MBT in this case, it should be (link_i[i], link_o[i], link_i_cast[i], link_o_cast[i])
      // MBT where possible, you should use link_i_cast[i].valid and not have to pull things out into valid_i 
      bsg_ready_and_link_sif_s link_i_cast, link_o_cast;
    
      assign link_i_cast = link_i[i];
      assign link_o[i] = link_o_cast;
    
      assign valid_i[i] = link_i_cast.v;
      assign data_i[i] = link_i_cast.data;
      assign link_o_cast.ready_and_rev = ready_o[i];
    
      assign link_o_cast.v = valid_o[i];
      assign link_o_cast.data = data_o[i];
      assign ready_i[i] = link_i_cast.ready_and_rev;
    end

  // Input Data fifos

  logic [dirs_lp-1:0] fifo_valid_o, fifo_yumi_i;
  logic [width_p-1:0] fifo_data_o [dirs_lp-1:0];
  
  // stubbed ports accept all I/O and send none.
  
  logic [dirs_lp-1:0] ready_i_stub;
  assign ready_i_stub = ready_i |((dirs_lp)'(stub_out_p));
  
  for (i = 0; i < dirs_lp; i++) begin: in_ff
    if (stub_in_p[i] == 0) 
      begin: no_stub
        bsg_two_fifo 
        #(.width_p(width_p)) 
        two_fifo
        (.clk_i(clk_i)
        ,.reset_i(reset_i)

        ,.ready_o(ready_o[i])
        ,.data_i(data_i[i])
        ,.v_i(valid_i[i])

        ,.v_o(fifo_valid_o[i])
        ,.data_o(fifo_data_o[i])
        ,.yumi_i(fifo_yumi_i[i]));        
      end 
    else 
      begin: stub
        assign fifo_valid_o[i] = 1'b0;
        assign fifo_data_o[i] = 0;
        assign ready_o[i] = 1'b1;        
    end
  end
  
  // input length counter
  
  logic [len_width_p-1:0] count_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
    begin: count
      always @(posedge clk_i) 
      begin
        count_r[i] <= (reset_i)? 0 : (fifo_yumi_i[i])? 
            ((count_r[i]==0)? fifo_data_o[i][len_offset_lp+:len_width_p] : count_r[i]-1) : count_r[i];
      end
    end
  
  // destination registers

  logic [dirs_lp-1:0] dest_r [dirs_lp-1:0];
  logic [dirs_lp-1:0] dest_n [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
    begin: rof
      always @(posedge clk_i)
        dest_r[i] <= dest_n[i];
    end
  
  // new valid signals on fifo side
  
  logic [dirs_lp-1:0] new_valid [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
    begin: rof2
      for (j = 0; j < dirs_lp; j++) 
        begin: rof3
          assign new_valid[i][j] = fifo_valid_o[i] & dest_n[i][j];
        end
    end
  
  // round robin arbiter wires
  
  logic [dirs_lp-1:0] arb_grants_o [dirs_lp-1:0];
            
  // fifo yumi signals
  
  for (i = 0; i < dirs_lp; i++) 
  begin: rof4
    assign fifo_yumi_i[i] = | (arb_grants_o[i]);
  end
                      
  // output length counter
  
  logic [len_width_p-1:0] out_count_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
    begin: out_count
      always @(posedge clk_i) 
        begin
          out_count_r[i] <= (reset_i)? 0 : (valid_o[i] & ready_i_stub[i])? 
            ((out_count_r[i]==0)? data_o[i][len_offset_lp+:len_width_p] : out_count_r[i]-1) : out_count_r[i];
        end
    end

  // valid signals on arbiter side
  
  logic [dirs_lp-1:0] arb_valid [dirs_lp-1:0];
  logic [dirs_lp-1:0] arb_grants_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
    begin
      for (j = 0; j < dirs_lp; j++) 
        begin    
          always @(posedge clk_i) 
            arb_grants_r[i][j] <= (out_count_r[j]==0)? arb_grants_o[i][j] : arb_grants_r[i][j];
          
          assign arb_valid[i][j] = (out_count_r[j]==0)? new_valid[i][j] : new_valid[i][j] & arb_grants_r[i][j];  
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
  logic [dirs_lp-1:0] arb_valid_concatenated [dirs_lp-1:0];
  logic [dirs_lp-1:0] arb_grants_concatenated [dirs_lp-1:0];
  logic [dirs_lp-1:0] arb_sel_o [dirs_lp-1:0];
  logic [dirs_lp-1:0][width_p-1:0] fifo_data_concatenated [dirs_lp-1:0];
  
  // W, E, N and S do not support loopback

  for (i = W; i < dirs_lp; i++) 
    begin: out_side
      for (j = 0; j < dirs_lp-1; j++) 
        begin
          localparam ORIG_DIR = SEQ[(i*LEN*COL+j*LEN)+:LEN];
        
          assign arb_valid_concatenated[i][j] = arb_valid[ORIG_DIR]    [i];
          assign arb_grants_o[ORIG_DIR][i]    = arb_grants_concatenated[i][j];
          assign fifo_data_concatenated[i][j] = fifo_data_o[ORIG_DIR];
        end
    
    // round robin arbiter
    bsg_round_robin_arb 
    #(.inputs_p(dirs_lp-1))
    rr_arb
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.grants_en_i(ready_i_stub[i])

    ,.reqs_i(arb_valid_concatenated[i][dirs_lp-2:0])
    ,.grants_o(arb_grants_concatenated[i][dirs_lp-2:0])
    ,.sel_one_hot_o(arb_sel_o[i][dirs_lp-2:0])

    ,.v_o(valid_o[i])
    ,.tag_o()
    ,.yumi_i(valid_o[i] & ready_i_stub[i])
    );
    
    // mux for output data_i
    bsg_mux_one_hot  
    #(.width_p(width_p)
    ,.els_p(dirs_lp-1))
    mux
    (.data_i(fifo_data_concatenated[i][dirs_lp-2:0])
    ,.sel_one_hot_i(arb_sel_o[i][dirs_lp-2:0])
    ,.data_o(data_o[i]));
    
    // Do not support loopback
    assign arb_grants_o[i][i] = 1'b0;
  end
  
  
  // Processor side support loopback
  
  for (j = 0; j < dirs_lp; j++) 
    begin
      assign arb_valid_concatenated[P][j] = arb_valid[j][P];
      assign arb_grants_o[j][P] = arb_grants_concatenated[P][j];
      assign fifo_data_concatenated[P][j] = fifo_data_o[j];
    end
    
  bsg_round_robin_arb 
  #(.inputs_p(dirs_lp))
  rr_arb_proc
  (.clk_i(clk_i)
  ,.reset_i(reset_i)
  ,.grants_en_i(ready_i_stub[P])

  ,.reqs_i(arb_valid_concatenated[P][dirs_lp-1:0])
  ,.grants_o(arb_grants_concatenated[P][dirs_lp-1:0])
  ,.sel_one_hot_o(arb_sel_o[P][dirs_lp-1:0])

  ,.v_o(valid_o[P])
  ,.tag_o()
  ,.yumi_i(valid_o[P] & ready_i_stub[P]));
    
  bsg_mux_one_hot  
  #(.width_p(width_p)
  ,.els_p(dirs_lp))
  mux_proc
  (.data_i(fifo_data_concatenated[P][dirs_lp-1:0])
  ,.sel_one_hot_i(arb_sel_o[P][dirs_lp-1:0])
  ,.data_o(data_o[P]));
  
  // destination id selection wires
  logic [x_cord_width_p-1:0] fifo_dest_x [dirs_lp-1:0];
  logic [y_cord_width_p-1:0] fifo_dest_y [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) 
  begin
    assign fifo_dest_x[i] = fifo_data_o[i][x_cord_offset_lp+:x_cord_width_p];
    assign fifo_dest_y[i] = fifo_data_o[i][y_cord_offset_lp+:y_cord_width_p];
  end

  // Destination Selection
  
  if (enable_2d_routing_p == 0) 
    begin: route_1d
      for (i = 0; i < dirs_lp; i++) 
        begin
          always_comb 
            begin
              dest_n[i] = dest_r[i];
              if (count_r[i]==0) 
                begin
                  dest_n[i] = {dirs_lp{1'b0}};
                  if (fifo_dest_x[i] == local_x_cord_i) dest_n[i][P] = 1'b1;
                  if (fifo_dest_x[i] < local_x_cord_i)  dest_n[i][W] = 1'b1;
                  if (fifo_dest_x[i] > local_x_cord_i)  dest_n[i][E] = 1'b1;
              end
            end
        end       
    end 
  else 
    begin: route_2d
      if (enable_yx_routing_p == 0) 
        begin: route_xy
          for (i = 0; i < dirs_lp; i++) 
            begin
              always_comb 
                begin
                  dest_n[i] = dest_r[i];
                  if (count_r[i]==0) 
                    begin
                      dest_n[i] = {dirs_lp{1'b0}};
                      if (fifo_dest_x[i] == local_x_cord_i) 
                        begin
                          if (fifo_dest_y[i] == local_y_cord_i) dest_n[i][P] = 1'b1;
                          if (fifo_dest_y[i] < local_y_cord_i) dest_n[i][N] = 1'b1;
                          if (fifo_dest_y[i] > local_y_cord_i) dest_n[i][S] = 1'b1;
                        end
                      if (fifo_dest_x[i] < local_x_cord_i) dest_n[i][W] = 1'b1;
                      if (fifo_dest_x[i] > local_x_cord_i) dest_n[i][E] = 1'b1;
                    end
                end
            end
        end: route_xy 
      else 
        begin: route_yx
          for (i = 0; i < dirs_lp; i++) 
            begin
              always_comb 
                begin
                  dest_n[i] = dest_r[i];
                  if (count_r[i]==0) 
                    begin
                      dest_n[i] = {dirs_lp{1'b0}};
                      if (fifo_dest_y[i] == local_y_cord_i) 
                        begin
                          if (fifo_dest_x[i] == local_x_cord_i) dest_n[i][P] = 1'b1;
                          if (fifo_dest_x[i] < local_x_cord_i) dest_n[i][W] = 1'b1;
                          if (fifo_dest_x[i] > local_x_cord_i) dest_n[i][E] = 1'b1;
                        end
                      if (fifo_dest_y[i] < local_y_cord_i) dest_n[i][N] = 1'b1;
                      if (fifo_dest_y[i] > local_y_cord_i) dest_n[i][S] = 1'b1;
                    end
                end
            end
        end : route_yx
    end : route_2d
  
  // synopsys translate_off
  initial begin
    assert(width_p >= x_cord_width_p+y_cord_width_p+len_width_p+reserved_width_p)
    else $error("width_p must be wider than header width!");
  end
  // synopsys translate_on
  
endmodule













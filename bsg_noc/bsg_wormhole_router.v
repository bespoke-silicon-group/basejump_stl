//
// Paul Gao 03/2019
//
// West has small id, East has large id
// North has small id, south has large id
//
// Direction index: P=0, W=1, E=2, N=3, S=4
// For 1D routing, should use P, W, E
//

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
  ,parameter enable_2d_routing_p = 1'b0
  ,localparam dirs_lp = (enable_2d_routing_p==0)? 3 : 5
  ,localparam x_cord_offset_lp = width_p-x_cord_width_p
  ,localparam y_cord_offset_lp = x_cord_offset_lp-y_cord_width_p
  ,localparam len_offset_lp = y_cord_offset_lp-len_width_p)

  (input clk_i
  ,input reset_i
  
  // Configuration
  ,input [x_cord_width_p-1:0] local_x_cord_i
  ,input [y_cord_width_p-1:0] local_y_cord_i
  
  // Input Traffics
  ,input [dirs_lp-1:0] valid_i // early
  ,input [width_p-1:0] data_i [dirs_lp-1:0]
  ,output [dirs_lp-1:0] ready_o // early
  
  // Output Traffics
  ,output [dirs_lp-1:0] valid_o // early
  ,output [width_p-1:0] data_o [dirs_lp-1:0]
  ,input [dirs_lp-1:0] ready_i // early
  );
  
  
  genvar i, j;
  
  
  // Input Data fifos

  logic [dirs_lp-1:0] fifo_valid_o, fifo_yumi_i;
  logic [width_p-1:0] fifo_data_o [dirs_lp-1:0];

  for (i = 0; i < dirs_lp; i++) begin: in_ff
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
  
  
  // input length counter
  
  logic [len_width_p-1:0] count_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin: count
    always @(posedge clk_i) begin
        count_r[i] <= (reset_i)? 1 : (fifo_yumi_i[i])? 
            ((count_r[i]==1)? fifo_data_o[i][len_offset_lp+:len_width_p] : count_r[i]-1) : count_r[i];
    end
  end
  
  
  // destination registers

  logic [dirs_lp-1:0] dest_r [dirs_lp-1:0];
  logic [dirs_lp-1:0] dest_n [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin
    always @(posedge clk_i) begin
        dest_r[i] <= dest_n[i];
    end
  end
  
  
  // new valid signals on fifo side
  
  logic [dirs_lp-1:0] new_valid [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin
    for (j = 0; j < dirs_lp; j++) begin
        if (i == j)
            assign new_valid[i][j] = 1'b0;
        else
            assign new_valid[i][j] = fifo_valid_o[i] & dest_n[i][j];
    end
  end
  
  
  // round robin arbiter wires
  
  logic [dirs_lp-1:0] arb_grants_o [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++)
    for (j = 0; j < dirs_lp; j++)
        if (i == j) assign arb_grants_o[i][j] = 1'b0;
            
  
  // fifo yumi signals
  
  for (i = 0; i < dirs_lp; i++) begin
    assign fifo_yumi_i[i] = | (arb_grants_o[i]);
  end
            
            
  // output length counter
  
  logic [len_width_p-1:0] out_count_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin: out_count
    always @(posedge clk_i) begin
        out_count_r[i] <= (reset_i)? 1 : (valid_o[i] & ready_i[i])? 
            ((out_count_r[i]==1)? data_o[i][len_offset_lp+:len_width_p] : out_count_r[i]-1) : out_count_r[i];
    end
  end
  
  
  // valid signals on arbiter side
  
  logic [dirs_lp-1:0] arb_valid [dirs_lp-1:0];
  logic [dirs_lp-1:0] arb_grants_r [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin
    for (j = 0; j < dirs_lp; j++) begin
    
        always @(posedge clk_i) begin
            arb_grants_r[i][j] <= (out_count_r[j]==1)? arb_grants_o[i][j] : arb_grants_r[i][j];
        end
        
        assign arb_valid[i][j] = (out_count_r[j]==1)? new_valid[i][j] : new_valid[i][j] & arb_grants_r[i][j];
    
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
  logic [dirs_lp-2:0] arb_valid_concatenated [dirs_lp-1:0];
  logic [dirs_lp-2:0] arb_grants_concatenated [dirs_lp-1:0];
  logic [dirs_lp-2:0] arb_sel_o [dirs_lp-1:0];
  logic [dirs_lp-2:0][width_p-1:0] fifo_data_concatenated [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin
    for (j = 0; j < dirs_lp-1; j++) begin
    
        localparam ORIG_DIR = SEQ[(i*LEN*COL+j*LEN)+:LEN];
        
        assign arb_valid_concatenated[i][j] = arb_valid[ORIG_DIR][i];
        assign arb_grants_o[ORIG_DIR][i] = arb_grants_concatenated[i][j];
        assign fifo_data_concatenated[i][j] = fifo_data_o[ORIG_DIR];
        
    end
  end
  

  for (i = 0; i < dirs_lp; i++) begin: out_side
    
    // round robin arbiter
    bsg_round_robin_arb 
    #(.inputs_p(dirs_lp-1))
    rr_arb
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.grants_en_i(ready_i[i])

    ,.reqs_i(arb_valid_concatenated[i])
    ,.grants_o(arb_grants_concatenated[i])
    ,.sel_one_hot_o(arb_sel_o[i])

    ,.v_o(valid_o[i])
    ,.tag_o()
    ,.yumi_i(valid_o[i] & ready_i[i]));
    
    
    // mux for output data_i
    bsg_mux_one_hot  
    #(.width_p(width_p)
    ,.els_p(dirs_lp-1))
    mux
    (.data_i(fifo_data_concatenated[i])
    ,.sel_one_hot_i(arb_sel_o[i])
    ,.data_o(data_o[i]));

  end
  
  
  // destination id wires
  logic [x_cord_width_p-1:0] fifo_dest_x [dirs_lp-1:0];
  logic [y_cord_width_p-1:0] fifo_dest_y [dirs_lp-1:0];
  
  for (i = 0; i < dirs_lp; i++) begin
    assign fifo_dest_x[i] = fifo_data_o[i][x_cord_offset_lp+:x_cord_width_p];
    assign fifo_dest_y[i] = fifo_data_o[i][y_cord_offset_lp+:y_cord_width_p];
  end
  
  
  
  if (enable_2d_routing_p) begin: route_2d
  
  
  
    // Destination Selection
    
    always_comb begin
    
        dest_n[P] = dest_r[P];
        dest_n[W] = dest_r[W];
        dest_n[E] = dest_r[E];
        dest_n[N] = dest_r[N];
        dest_n[S] = dest_r[S];
        
        if (count_r[P]==1) begin
            dest_n[P] = {dirs_lp{1'b0}};
            if (fifo_dest_x[P] == local_x_cord_i)
                if (fifo_dest_y[P] < local_y_cord_i)
                    dest_n[P][N] = 1'b1;
                else
                    dest_n[P][S] = 1'b1;
            else
                if (fifo_dest_x[P] < local_x_cord_i)
                    dest_n[P][W] = 1'b1;
                else
                    dest_n[P][E] = 1'b1;
        end
        
        if (count_r[W]==1) begin
            dest_n[W] = {dirs_lp{1'b0}};
            if (fifo_dest_x[W] == local_x_cord_i)
                if (fifo_dest_y[W] == local_y_cord_i)
                    dest_n[W][P] = 1'b1;
                else
                    if (fifo_dest_y[W] < local_y_cord_i)
                        dest_n[W][N] = 1'b1;
                    else
                        dest_n[W][S] = 1'b1;
            else
                dest_n[W][E] = 1'b1;
        end
        
        if (count_r[E]==1) begin
            dest_n[E] = {dirs_lp{1'b0}};
            if (fifo_dest_x[E] == local_x_cord_i)
                if (fifo_dest_y[E] == local_y_cord_i)
                    dest_n[E][P] = 1'b1;
                else
                    if (fifo_dest_y[E] < local_y_cord_i)
                        dest_n[E][N] = 1'b1;
                    else
                        dest_n[E][S] = 1'b1;
            else
                dest_n[E][W] = 1'b1;
        end
        
        if (count_r[N]==1) begin
            dest_n[N] = {dirs_lp{1'b0}};
            if (fifo_dest_x[N] == local_x_cord_i)
                if (fifo_dest_y[N] == local_y_cord_i)
                    dest_n[N][P] = 1'b1;
                else
                    dest_n[N][S] = 1'b1;
            else
                if (fifo_dest_x[N] < local_x_cord_i)
                    dest_n[N][W] = 1'b1;
                else
                    dest_n[N][E] = 1'b1;
        end
        
        if (count_r[S]==1) begin
            dest_n[S] = {dirs_lp{1'b0}};
            if (fifo_dest_x[S] == local_x_cord_i)
                if (fifo_dest_y[S] == local_y_cord_i)
                    dest_n[S][P] = 1'b1;
                else
                    dest_n[S][N] = 1'b1;
            else
                if (fifo_dest_x[S] < local_x_cord_i)
                    dest_n[S][W] = 1'b1;
                else
                    dest_n[S][E] = 1'b1;
        end

    end
    
    

  end else begin: route_1d



    // Destination Selection
    
    always_comb begin
    
        dest_n[P] = dest_r[P];
        dest_n[W] = dest_r[W];
        dest_n[E] = dest_r[E];
        
        if (count_r[P]==1) begin
            dest_n[P] = {dirs_lp{1'b0}};
            if (fifo_dest_x[P] < local_x_cord_i)
                dest_n[P][W] = 1'b1;
            else
                dest_n[P][E] = 1'b1;
        end
        
        if (count_r[W]==1) begin
            dest_n[W] = {dirs_lp{1'b0}};
            if (fifo_dest_x[W] == local_x_cord_i)
                dest_n[W][P] = 1'b1;
            else
                dest_n[W][E] = 1'b1;
        end
        
        if (count_r[E]==1) begin
            dest_n[E] = {dirs_lp{1'b0}};
            if (fifo_dest_x[E] == local_x_cord_i)
                dest_n[E][P] = 1'b1;
            else
                dest_n[E][W] = 1'b1;
        end

    end
    
    
  
  end
endmodule









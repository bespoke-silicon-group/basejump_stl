// import enum Dirs for directions
import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (processor core)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south


// Dimension ordered routing decoder
// based on X then Y routing, it outputs a set of grant signals

module bsg_mesh_router_dor_decoder #( parameter xcord_width_p = -1
                                     ,parameter ycord_width_p = -1
                                     ,parameter dirs_p  = 5
                                    )
 ( input [dirs_p-1:0] valid_i

  ,input [dirs_p-1:0][xcord_width_p-1:0] x_dirs_i
  ,input [dirs_p-1:0][ycord_width_p-1:0] y_dirs_i

  ,input [xcord_width_p-1:0] my_x_i
  ,input [ycord_width_p-1:0] my_y_i

  ,output [dirs_p-1:0][dirs_p-1:0] req_o
 );

  wire [dirs_p-1:0] x_eq;
  wire [dirs_p-1:0] y_eq;
  wire [dirs_p-1:0] x_gt;
  wire [dirs_p-1:0] y_gt;

  // this is the routing function;
  genvar i;

  for (i = 0; i < dirs_p; i=i+1)
  begin: comps
    assign x_eq[i] = (x_dirs_i[i] == my_x_i);
    assign y_eq[i] = (y_dirs_i[i] == my_y_i);
    assign x_gt[i] = (x_dirs_i[i] > my_x_i);
    assign y_gt[i] = (y_dirs_i[i] > my_y_i);
  end

  // request signals: format req[<input dir>][<output dir>]
  wire [dirs_p-1:0][dirs_p-1:0] req;

  for (i = W; i <= E; i=i+1)
  begin: WE_req
    assign req_o[i][(i==W) ? E : W] = valid_i[i] &  ~x_eq[i];
    assign req_o[i][P] = valid_i[i] & x_eq[i] & y_eq[i];
    assign req_o[i][S] = valid_i[i] & x_eq[i] & y_gt[i];
    assign req_o[i][N] = valid_i[i] & x_eq[i] & ~y_gt[i] & ~y_eq[i];
    assign req_o[i][(i==W) ? W:E] = 1'b0;
  end

  for (i = N; i <=S; i=i+1)
  begin: NS_req
    assign req_o[i][(i==N) ? S : N] =  valid_i[i] & ~y_eq[i];
    assign req_o[i][P] =  valid_i[i] & y_eq[i];
    assign req_o[i][E] = 1'b0;
    assign req_o[i][W] = 1'b0;
    assign req_o[i][(i==N) ? N : S] = 1'b0;
  end

  assign req_o[P][E]  =  valid_i[P] & x_gt [P];
  assign req_o[P][W]  =  valid_i[P] & !(x_eq[P] | x_gt[P]);
  assign req_o[P][S]  =  valid_i[P] & x_eq[P] & y_gt  [P];
  assign req_o[P][N]  =  valid_i[P] & x_eq[P] & ~y_gt[P] & ~y_eq[P];
  assign req_o[P][P]  =  valid_i[P] & x_eq[P] & y_eq [P];

endmodule




module bsg_mesh_router #( parameter dirs_p=5
                         ,parameter width_p=-1
                         ,parameter xcord_width_p=-1
                         ,parameter ycord_width_p=-1
                         ,parameter debug_p    = 0
                        )
 ( input clk_i
  ,input reset_i

   // dirs: NESWP (P=0, W=1, E=2, N=3, S=4)

  ,input   [dirs_p-1:0] [width_p-1:0] data_i  // from input twofer
  ,input   [dirs_p-1:0]               valid_i // from input twofer
  ,output  logic [dirs_p-1:0]         yumi_o  // to input twofer

  ,input   [dirs_p-1:0]               ready_i // from output twofer
  ,output  [dirs_p-1:0] [width_p-1:0] data_o  // to output twofer
  ,output  logic [dirs_p-1:0]         valid_o // to output twofer


  ,input   [xcord_width_p-1:0] my_x_i           // node's x and y coord
  ,input   [ycord_width_p-1:0] my_y_i
 );

  wire [dirs_p-1:0][xcord_width_p-1:0] x_dirs;
  wire [dirs_p-1:0][ycord_width_p-1:0] y_dirs;

  genvar i;

  for (i = 0; i < dirs_p; i=i+1)
  begin: reshape
     assign x_dirs[i] = data_i[i][0+:xcord_width_p];
     assign y_dirs[i] = data_i[i][xcord_width_p+:ycord_width_p];
  end

  wire [dirs_p-1:0][dirs_p-1:0] req;

  bsg_mesh_router_dor_decoder  #( .xcord_width_p(xcord_width_p)
                                 ,.ycord_width_p(ycord_width_p)
                                 ,.dirs_p     (dirs_p)
                                ) dor_decoder
                                ( .valid_i
                                 ,.my_x_i, .my_y_i
                                 ,.x_dirs_i(x_dirs), .y_dirs_i(y_dirs)
                                 ,.req_o(req)
                                );

  // valid out signals; we get these out quickly before we determine whose data we actually send

  assign valid_o[W] = ready_i[W] & (req[P][W] | req[E][W]);
  assign valid_o[E] = ready_i[E] & (req[P][E] | req[W][E]);

  assign valid_o[P] = ready_i[P] & (req[P][P] | req[N][P] | req[E][P] | req[S][P] | req[W][P]);
  assign valid_o[N] = ready_i[N] & (req[P][N] | req[W][N] | req[E][N] | req[S][N]);
  assign valid_o[S] = ready_i[S] & (req[P][S] | req[W][S] | req[E][S] | req[N][S]);

   // synopsys translate off
   if (debug_p)
   for (i = P; i <= S; i=i+1)
     begin: rof
        Dirs dir = Dirs ' (i);

        always_ff @(negedge clk_i)
          begin
	     if (valid_i[i])
	       $display("%m wants to send %x to {x,y}={%x,%x} from dir %s, req[SNEWP] = %b, ready_i[SNEWP] = %b", data_i[i], x_dirs[i],y_dirs[i],dir.name(), req[i], ready_i); 
            if (valid_o[i])
               $display("%m sending %x in dir %s", data_o[i], dir.name());
          end
     end


   // synopsys translate on

  // grant signals: format <output dir>_gnt_<input dir>
  // these determine whose data we actually send
  wire W_gnt_e, W_gnt_p;
  wire E_gnt_w, E_gnt_p;
  wire N_gnt_s, N_gnt_e, N_gnt_w, N_gnt_p;
  wire S_gnt_n, S_gnt_w, S_gnt_e, S_gnt_p;
  wire P_gnt_p, P_gnt_e, P_gnt_s, P_gnt_n, P_gnt_w;

  bsg_round_robin_arb #(.inputs_p(2)
                       ) west_rr_arb
                       (.clk_i
                        ,.reset_i
                        ,.ready_i(ready_i[W])
                        ,.reqs_i({req[E][W], req[P][W]})
                        ,.grants_o({W_gnt_e, W_gnt_p})
                       );

  bsg_round_robin_arb #(.inputs_p(2)
                       ) east_rr_arb
                       (.clk_i
                        ,.reset_i
                        ,.ready_i(ready_i[E])
                        ,.reqs_i({req[W][E], req[P][E]})
                        ,.grants_o({E_gnt_w, E_gnt_p})
                       );

  bsg_round_robin_arb #(.inputs_p(4)
                       ) north_rr_arb
                       (.clk_i
                        ,.reset_i
                        ,.ready_i(ready_i[N])
                        ,.reqs_i({req[S][N], req[E][N], req[W][N], req[P][N]})
                        ,.grants_o({ N_gnt_s, N_gnt_e, N_gnt_w, N_gnt_p })
                       );

  bsg_round_robin_arb #(.inputs_p(4)
                       ) south_rr_arb
                       (.clk_i
                        ,.reset_i
                        ,.ready_i(ready_i[S])
                        ,.reqs_i({req[N][S], req[E][S], req[W][S], req[P][S]})
                        ,.grants_o({ S_gnt_n, S_gnt_e, S_gnt_w, S_gnt_p })
                       );


  bsg_round_robin_arb #(.inputs_p(5)
                       ) proc_rr_arb
                       (.clk_i
                        ,.reset_i
                        ,.ready_i(ready_i[P])
                        ,.reqs_i({req[S][P], req[N][P], req[E][P], req[W][P], req[P][P]})
                        ,.grants_o({ P_gnt_s, P_gnt_n, P_gnt_e, P_gnt_w, P_gnt_p })
                       );

  // data out signals; this is a big crossbar that actually routes the data

  bsg_mux_one_hot #(.width_p(width_p)
                    ,.els_p(2)
                   ) mux_data_west
                   (.data_i        ({data_i[P], data_i[E]})
                    ,.sel_one_hot_i({W_gnt_p  , W_gnt_e  })
                    ,.data_o       (data_o[W])
                   );

  bsg_mux_one_hot #(.width_p(width_p)
                    ,.els_p(2)
                   ) mux_data_east
                   (.data_i        ({data_i[P], data_i[W]})
                    ,.sel_one_hot_i({E_gnt_p  , E_gnt_w  })
                    ,.data_o       (data_o[E])
                   );


  bsg_mux_one_hot #(.width_p(width_p)
                    ,.els_p(5)
                   ) mux_data_proc
                   (.data_i        ({data_i[P], data_i[E], data_i[S], data_i[W], data_i[N]})
                    ,.sel_one_hot_i({P_gnt_p  , P_gnt_e  , P_gnt_s  , P_gnt_w  , P_gnt_n  })
                    ,.data_o       (data_o[P])
                   );

  bsg_mux_one_hot #(.width_p(width_p)
                    ,.els_p(4)
                   ) mux_data_north
                   (.data_i        ({data_i[P], data_i[E], data_i[S], data_i[W]})
                    ,.sel_one_hot_i({N_gnt_p  , N_gnt_e  , N_gnt_s  , N_gnt_w  })
                    ,.data_o       (data_o[N])
                   );

  bsg_mux_one_hot #(.width_p(width_p)
                    ,.els_p(4)
                   ) mux_data_south
                   (.data_i        ({data_i[P], data_i[E], data_i[N], data_i[W]})
                    ,.sel_one_hot_i({S_gnt_p  , S_gnt_e  , S_gnt_n  , S_gnt_w  })
                    ,.data_o       (data_o[S])
                   );


  // yumi signals; this deques the data from the inputs

  assign yumi_o[W] = E_gnt_w | N_gnt_w | S_gnt_w | P_gnt_w;
  assign yumi_o[E] = W_gnt_e | N_gnt_e | S_gnt_e | P_gnt_e;
  assign yumi_o[P] = E_gnt_p | N_gnt_p | S_gnt_p | P_gnt_p | W_gnt_p;
  assign yumi_o[N] = S_gnt_n | P_gnt_n;
  assign yumi_o[S] = N_gnt_s | P_gnt_s;

endmodule

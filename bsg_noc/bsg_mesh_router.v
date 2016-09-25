// bsg_mesh_router
//
// this router requires that the X coordinates be located
// at lowest bits in the packet, and the Y coordinates at the next lowest position
//

// import enum Dirs for directions
import bsg_noc_pkg::Dirs
       , bsg_noc_pkg::P  // proc (processor core)
       , bsg_noc_pkg::W  // west
       , bsg_noc_pkg::E  // east
       , bsg_noc_pkg::N  // north
       , bsg_noc_pkg::S; // south

//
// Dimension ordered routing decoder
// based on X then Y routing, it outputs a set of grant signals
//
// stub_p facilitates removal of logic that is not used on edge tiles
// allow_S_to_EW_p is used to allow I/O devices to be placed on the
// south edge of the mesh. The south edge is the only edge that has
// non-negative coordinates, and is routable on-mesh with XY routing.
//

module bsg_mesh_router_dor_decoder #( parameter x_cord_width_p  = -1
                                      ,parameter y_cord_width_p = -1
                                      ,parameter dirs_lp       = 5
                                      ,parameter stub_p        = { dirs_lp {1'b0} }  // SNEWP
                                      ,parameter allow_S_to_EW_p = 0
                                    )
 (input clk_i   // debug only
  ,input [dirs_lp-1:0] v_i

  ,input [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs_i
  ,input [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs_i

  ,input [x_cord_width_p-1:0] my_x_i
  ,input [y_cord_width_p-1:0] my_y_i

  ,output [dirs_lp-1:0][dirs_lp-1:0] req_o
 );

   wire [dirs_lp-1:0] x_eq, x_gt, x_lt;
   wire [dirs_lp-1:0] y_eq, y_gt, y_lt;

   wire [dirs_lp-1:0] v_i_stub = v_i & ~stub_p;

   // this is the routing function;
   genvar            i;

   for (i = 0; i < dirs_lp; i=i+1)
     begin: comps
        assign x_eq[i] = (x_dirs_i[i] == my_x_i);
        assign y_eq[i] = (y_dirs_i[i] == my_y_i);
        assign x_gt[i] = (x_dirs_i[i] > my_x_i);
        assign y_gt[i] = (y_dirs_i[i] > my_y_i);
        assign x_lt[i] = ~x_gt[i] & ~x_eq[i];
        assign y_lt[i] = ~y_gt[i] & ~y_eq[i];
     end

   // synopsys translate_off

   always @(negedge clk_i)
     begin
        if ((v_i[N] & ~x_eq[N]) | (~allow_S_to_EW_p & v_i[S] & ~x_eq[S]))
          begin
             $error("%m horizontal route needed from N/S port");
             $finish();
          end

        if ((v_i[E] & x_gt[E]) | (v_i[W] & x_lt[W]))
          begin
             $error("%m doubleback route on E/W port");
             $finish();
          end

        if ((v_i[N] & y_lt[N]) | (v_i[S] & y_gt[S]))
          begin
             $error("%m doubleback route on N/S port N:YX=%d,%d S:YX=%d,%d at Tile %d,%d",y_dirs_i[N],x_dirs_i[N],y_dirs_i[S],x_dirs_i[S],my_y_i,my_x_i);
             $finish();
          end
     end
   // synopsys translate_on

  // request signals: format req[<input dir>][<output dir>]
  wire [dirs_lp-1:0][dirs_lp-1:0] req;

  for (i = W; i <= E; i=i+1)
  begin: WE_req
    assign req_o[i][(i==W) ? E : W] = v_i_stub[i] &  ~x_eq[i];
    assign req_o[i][P] = v_i_stub[i] & x_eq[i] & y_eq[i];
    assign req_o[i][S] = v_i_stub[i] & x_eq[i] & y_gt[i];
    assign req_o[i][N] = v_i_stub[i] & x_eq[i] & y_lt[i];
    assign req_o[i][(i==W) ? W:E] = 1'b0;
  end

   for (i = N; i <=S; i=i+1)
     begin: NS_req
        wire weird_route = ~x_eq[i] & allow_S_to_EW_p & (i==S);
        assign req_o[i][(i==N) ? S : N] =  v_i_stub[i] & ~y_eq[i] & ~weird_route;
        assign req_o[i][P] =  v_i_stub[i] & y_eq[i] & ~weird_route;
        assign req_o[i][W] = v_i_stub[i] & weird_route & ~x_gt[i];
        assign req_o[i][E] = v_i_stub[i] & weird_route &  x_gt[i];
        assign req_o[i][(i==N) ? N : S] = 1'b0;
     end

  assign req_o[P][E]  =  v_i_stub[P] & x_gt [P];
  assign req_o[P][W]  =  v_i_stub[P] & x_lt [P];
  assign req_o[P][S]  =  v_i_stub[P] & x_eq[P] & y_gt [P];
  assign req_o[P][N]  =  v_i_stub[P] & x_eq[P] & y_lt [P];
  assign req_o[P][P]  =  v_i_stub[P] & x_eq[P] & y_eq [P];

endmodule


module bsg_mesh_router #(
                         parameter width_p        = -1
                         ,parameter x_cord_width_p = -1
                         ,parameter y_cord_width_p = -1
                         ,parameter debug_p       = 0
                         ,parameter dirs_lp       = 5
                         ,parameter stub_p        = { dirs_lp {1'b0} }  // SNEWP
                         ,parameter allow_S_to_EW_p = 0
                         )
   ( input clk_i
     ,input reset_i

     // dirs: NESWP (P=0, W=1, E=2, N=3, S=4)

     ,input   [dirs_lp-1:0] [width_p-1:0] data_i  // from input twofer
     ,input   [dirs_lp-1:0]               v_i // from input twofer
     ,output  logic [dirs_lp-1:0]         yumi_o  // to input twofer

     ,input   [dirs_lp-1:0]               ready_i // from output twofer
     ,output  [dirs_lp-1:0] [width_p-1:0] data_o  // to output twofer
     ,output  logic [dirs_lp-1:0]         v_o // to output twofer

     ,input   [x_cord_width_p-1:0] my_x_i           // node's x and y coord
     ,input   [y_cord_width_p-1:0] my_y_i
     );

   wire [dirs_lp-1:0][x_cord_width_p-1:0] x_dirs;
   wire [dirs_lp-1:0][y_cord_width_p-1:0] y_dirs;

   // stubbed ports accept all I/O and send none.

   wire [dirs_lp-1:0] ready_i_stub = ready_i | stub_p;
   wire [dirs_lp-1:0] v_i_stub     = v_i     & ~stub_p;

   genvar                               i;

   for (i = 0; i < dirs_lp; i=i+1)
     begin: reshape
        assign x_dirs[i] = data_i[i][0+:x_cord_width_p];
        assign y_dirs[i] = data_i[i][x_cord_width_p+:y_cord_width_p];
     end

   wire [dirs_lp-1:0][dirs_lp-1:0] req;

   bsg_mesh_router_dor_decoder  #( .x_cord_width_p  (x_cord_width_p)
                                   ,.y_cord_width_p (y_cord_width_p)
                                   ,.dirs_lp        (dirs_lp)
                                   ,.allow_S_to_EW_p(allow_S_to_EW_p)
                                   ) dor_decoder
     ( .clk_i(clk_i)   // debug only
       ,.v_i(v_i_stub)
       ,.my_x_i, .my_y_i
       ,.x_dirs_i(x_dirs), .y_dirs_i(y_dirs)
       ,.req_o(req)
       );

   // synopsys translate_off
   if (debug_p)
     for (i = P; i <= S; i=i+1)
       begin: rof
          Dirs dir = Dirs ' (i);

          always_ff @(negedge clk_i)
            begin
               if (v_i_stub[i])
                 $display("%m wants to send %x to {x,y}={%x,%x} from dir %s, req[SNEWP] = %b, ready_i[SNEWP] = %b"
                          , data_i[i], x_dirs[i],y_dirs[i],dir.name(), req[i], ready_i_stub);
               if (v_o[i])
                 $display("%m sending %x in dir %s", data_o[i], dir.name());
            end
       end

   // synopsys translate_on

   // grant signals: format <output dir>_gnt_<input dir>
   // these determine whose data we actually send
   wire W_gnt_e, W_gnt_p, W_gnt_s;
   wire E_gnt_w, E_gnt_p, E_gnt_s;
   wire N_gnt_s, N_gnt_e, N_gnt_w, N_gnt_p;
   wire S_gnt_n, S_gnt_w, S_gnt_e, S_gnt_p;
   wire P_gnt_p, P_gnt_e, P_gnt_s, P_gnt_n, P_gnt_w;


   if (allow_S_to_EW_p)
     begin : fi
        bsg_round_robin_arb #(.inputs_p(3)
                              ) west_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[W])

           ,.reqs_i  ({req[E][W], req[P][W], req[S][W]})
           ,.grants_o({W_gnt_e, W_gnt_p, W_gnt_s})

           ,.v_o      (v_o[W])
           ,.tag_o    ()
           ,.yumi_i   (v_o[W])
           );

        bsg_round_robin_arb #(.inputs_p(3)
                              ) east_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[E])

           ,.reqs_i({req[W][E], req[P][E], req[S][E]})
           ,.grants_o({E_gnt_w, E_gnt_p, E_gnt_s})

           ,.v_o   (v_o[E])
           ,.tag_o ()
           ,.yumi_i(v_o[E])
           );
     end
   else
     begin
        assign W_gnt_s = 1'b0;
        assign E_gnt_s = 1'b0;

	bsg_round_robin_arb #(.inputs_p(2)
                              ) west_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[W])

           ,.reqs_i({req[E][W], req[P][W]})
           ,.grants_o({W_gnt_e, W_gnt_p})

           ,.v_o    (v_o[W])
           ,.tag_o  ()
           ,.yumi_i (v_o[W])
           );

        bsg_round_robin_arb #(.inputs_p(2)
                              ) east_rr_arb
          (.clk_i
           ,.reset_i
           ,.grants_en_i(ready_i_stub[E])

           ,.reqs_i({req[W][E], req[P][E]})
           ,.grants_o({E_gnt_w, E_gnt_p})

           ,.v_o   (v_o[E])
           ,.tag_o ()
           ,.yumi_i(v_o[E])
           );
     end

   bsg_round_robin_arb #(.inputs_p(4)
                         ) north_rr_arb
     (.clk_i
      ,.reset_i
      ,.grants_en_i(ready_i_stub[N])

      ,.reqs_i({req[S][N], req[E][N], req[W][N], req[P][N]})
      ,.grants_o({ N_gnt_s, N_gnt_e, N_gnt_w, N_gnt_p })

      ,.v_o   (v_o[N])
      ,.tag_o ()
      ,.yumi_i(v_o[N])
      );

   bsg_round_robin_arb #(.inputs_p(4)
                         ) south_rr_arb
     (.clk_i
      ,.reset_i

      ,.grants_en_i(ready_i_stub[S])

      ,.reqs_i({req[N][S], req[E][S], req[W][S], req[P][S]})
      ,.grants_o({ S_gnt_n, S_gnt_e, S_gnt_w, S_gnt_p })

      ,.v_o   (v_o[S])
      ,.tag_o ()
      ,.yumi_i(v_o[S])
      );

   bsg_round_robin_arb #(.inputs_p(5)
                         ) proc_rr_arb
     (.clk_i
      ,.reset_i
      ,.grants_en_i(ready_i_stub[P])

      ,.reqs_i({req[S][P], req[N][P], req[E][P], req[W][P], req[P][P]})
      ,.grants_o({ P_gnt_s, P_gnt_n, P_gnt_e, P_gnt_w, P_gnt_p })

      ,.v_o   (v_o[P])
      ,.tag_o ()
      ,.yumi_i(v_o[P])
      );

   // data out signals; this is a big crossbar that actually routes the data

   if (allow_S_to_EW_p)
     begin
        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(3)
                          ) mux_data_west
          (.data_i        ({data_i[P], data_i[E], data_i[S]})
           ,.sel_one_hot_i({W_gnt_p  , W_gnt_e, W_gnt_s  })
           ,.data_o       (data_o[W])
           );

        bsg_mux_one_hot #(.width_p(width_p)
                          ,.els_p(3)
                          ) mux_data_east
           (.data_i        ({data_i[P], data_i[W], data_i[S]})
            ,.sel_one_hot_i({E_gnt_p  , E_gnt_w, E_gnt_s  })
            ,.data_o       (data_o[E])
            );
     end
   else
     begin
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
     end

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
   assign yumi_o[S] = N_gnt_s | P_gnt_s | W_gnt_s | E_gnt_s;

endmodule

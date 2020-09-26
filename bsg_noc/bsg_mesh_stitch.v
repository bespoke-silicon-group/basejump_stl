// bsg_mesh_stitch
//
// MBT 5-26-16
//
// stitches together wires according to a mesh topology; edges
// are returned in hor and ver arrays.
//

`include "bsg_defines.v"

module bsg_mesh_stitch
  import bsg_noc_pkg::*; // P=0, W, E, N, S
  #(parameter width_p = "inv" // data width
    , x_max_p = "inv"
    , y_max_p = "inv"
    , nets_p  = 1 // optional parameter that allows for multiple networks to be routed together
    )
   (input    [y_max_p-1:0][x_max_p-1:0][nets_p-1:0][S:W][width_p-1:0] outs_i // for each node, each direction
    , output [y_max_p-1:0][x_max_p-1:0][nets_p-1:0][S:W][width_p-1:0] ins_o

    // these are the edge of the greater tile
    , input  [E:W][y_max_p-1:0][nets_p-1:0][width_p-1:0] hor_i
    , output [E:W][y_max_p-1:0][nets_p-1:0][width_p-1:0] hor_o
    , input  [S:N][x_max_p-1:0][nets_p-1:0][width_p-1:0] ver_i
    , output [S:N][x_max_p-1:0][nets_p-1:0][width_p-1:0] ver_o
    );

   genvar r,c,net;

   for (net = 0; net < nets_p; net=net+1)
     begin: _n

        for (r = 0; r < y_max_p; r=r+1)
          begin: _r
             assign hor_o[E][r][net] = outs_i[r][x_max_p-1][net][E];
             assign hor_o[W][r][net] = outs_i[r][0        ][net][W];

             for (c = 0; c < x_max_p; c=c+1)
               begin: _c
                 assign ins_o[r][c][net][S] = (r == y_max_p-1)
                                            ? ver_i[S][c][net]
                                            : outs_i[(r == y_max_p-1) ? r : r+1][c][net][N]; // ?: for warning
                 assign ins_o[r][c][net][N] = (r == 0)
                                            ? ver_i[N][c][net]
                                            : outs_i[r ? r-1: 0][c][net][S]; // ?: to eliminate warning
                 assign ins_o[r][c][net][E] = (c == x_max_p-1)
                                            ? hor_i[E][r][net]
                                            : outs_i[r][(c == x_max_p-1) ? c : (c+1)][net][W]; // ?: for warning
                 assign ins_o[r][c][net][W] = (c == 0)
                                            ? hor_i[W][r][net]
                                            : outs_i[r][c ? (c-1) :0][net][E]; // ?: to eliminate warning
               end // block: c
          end // block: r

        for (c = 0; c < x_max_p; c=c+1)
          begin: _c
             assign ver_o[S][c][net] = outs_i[y_max_p-1][c][net][S];
             assign ver_o[N][c][net] = outs_i[0        ][c][net][N];
          end
     end // block: _n

endmodule




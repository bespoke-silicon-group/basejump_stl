//
// N-dimensional wormhole dimension ordered decoder
//
// given input coordinates for the target of a message, and for the current node
// it will output a one hot vector which is which direction that header should be routed
//
//

`include "bsg_defines.v"

module bsg_wormhole_router_decoder_dor
#(parameter dims_p=2
  // cord_dims_p is normally the same as dims_p.  However, the override allows users to pass
  // a larger cord array than necessary, useful for parameterizing between 1d/nd networks
  ,parameter cord_dims_p=dims_p
  ,parameter reverse_order_p=0 // e.g., 1->Y THEN X, 0->X THEN Y routing
  // pass in the markers that delineates storage of dimension fields
  // so for example {5, 4, 0} means dim0=[4-1:0], dim1=[5-1:4]
  , parameter int cord_markers_pos_p[cord_dims_p:0] = '{ 5, 4, 0 }
  , parameter output_dirs_lp=2*dims_p+1
  )
   (input   [cord_markers_pos_p[dims_p]-1:0]    target_cord_i
    , input [cord_markers_pos_p[dims_p]-1:0]        my_cord_i
    , output [output_dirs_lp-1:0]                       req_o
    );

   genvar i;

   logic [dims_p-1:0] eq, lt, gt;

   for (i = 0; i < dims_p; i=i+1)
     begin: rof
        localparam upper_marker_lp = cord_markers_pos_p[i+1];
        localparam lower_marker_lp = cord_markers_pos_p[i];
        localparam local_cord_width_p = upper_marker_lp - lower_marker_lp;

        wire [local_cord_width_p-1:0] targ_cord = target_cord_i[upper_marker_lp-1:lower_marker_lp];
        wire [local_cord_width_p-1:0] my_cord   =     my_cord_i[upper_marker_lp-1:lower_marker_lp];

        assign eq[i] = (targ_cord == my_cord);
        assign lt[i] = (targ_cord < my_cord);
        assign gt[i] = ~eq[i] & ~lt[i];
     end // block: rof

   // handle base case
   assign req_o[0] = & eq;  // processor is at 0 in enum

   if (reverse_order_p)
     begin: rev
        assign req_o[(dims_p-1)*2+1]   = lt[dims_p-1];
        assign req_o[(dims_p-1)*2+1+1] = gt[dims_p-1];

        if (dims_p > 1)
          begin : fi1
            for (i = (dims_p-1)-1; i >= 0; i--)
              begin: rof3
                 assign req_o[i*2+1]   = &eq[dims_p-1:i+1] & lt[i];
                 assign req_o[i*2+1+1] = &eq[dims_p-1:i+1] & gt[i];
              end
          end
     end // if (reverse_order_p)
   else
     begin: fwd
        assign req_o[1] = lt[0]; // down   (W,N)
        assign req_o[2] = gt[0]; // up     (E,S)

        for (i = 1; i < dims_p; i++)
          begin: rof2
             assign req_o[i*2+1]   = (&eq[i-1:0]) & lt[i];
             assign req_o[i*2+1+1] = (&eq[i-1:0]) & gt[i];
          end
     end // else: !if(reverse_order_p)

`ifndef SYNTHESIS
       initial assert(bsg_noc_pkg::P == 0
                      && bsg_noc_pkg::W == 1
                      && bsg_noc_pkg::E == 2
                      && bsg_noc_pkg::N == 3
                      && bsg_noc_pkg::S == 4) else $error("%m: bsg_noc_pkg dirs are inconsistent with this module");
`endif

endmodule

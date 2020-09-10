// MBT 8-15-2015
//
// bsg_sort
//
// This is a sorting network implementation.
// Currently, it implements a stable 4-item sort -- very efficiently.
//
// It takes as input parameters the inclusive bit range
// to use for comparison. This allows us to move both
// data and tags through the sorting network.
//
// NOTE: This code is UNTESTED.
//

`include "bsg_defines.v"

module bsg_sort_4 #(parameter width_p="inv",
                         items_p = 4
                         , t_p   = width_p-1
                         , b_p   = 0
                         )
   (input    [width_p-1:0] i [items_p-1:0]
    , output [width_p-1:0] o [items_p-1:0]
    );

   initial
     assert (items_p==4) else $error("unhandled case");

   wire [width_p-1:0] s0 [items_p-1:0];
   wire [width_p-1:0] s1 [items_p-1:0];
   wire [width_p-1:0] s2 [items_p-1:0];
   wire [width_p-1:0] s3 [items_p-1:0];

   wire               swapped_3_1;

   assign s0 = i;

   // stage 1: compare_and swap  <3,2> and <1,0>

  bsg_compare_and_swap #(.width_p(width_p), .t_p(t_p), .b_p(b_p)) cas_0
   (.data_i({s0[1], s0[0]}), .data_o({s1[1], s1[0]}));

  bsg_compare_and_swap #(.width_p(width_p), .t_p(t_p), .b_p(b_p)) cas_1
   (.data_i({s0[3], s0[2]}), .data_o({s1[3], s1[2]}));

   // stage 2: compare_and swap  <2,0> and <3,1>

  bsg_compare_and_swap #(.width_p(width_p), .t_p(t_p), .b_p(b_p)) cas_2
   (.data_i({s1[2], s1[0]}), .data_o({s2[2], s2[0]}));

  bsg_compare_and_swap #(.width_p(width_p), .t_p(t_p), .b_p(b_p)) cas_3
   (.data_i({s1[3], s1[1]}), .data_o({s2[3], s2[1]}), .swapped_o(swapped_3_1));

   // stage 3: compare_and swap  <2,1>
   //
   // we also swap if they are equal and if <3,1> resulted in a swap
   // this will reintroduce stability into the sort
   //

   bsg_compare_and_swap #(.width_p(width_p), .t_p(t_p), .b_p(b_p)
                          , .cond_swap_on_equal_p(1)) cas_4
   (.data_i({s2[2], s2[1]})
    , .swap_on_equal_i(swapped_3_1)
    , .data_o({s3[2], s3[1]})
    );

   assign s3[3] = s2[3];
   assign s3[0] = s2[0];

   assign o = s3;

endmodule


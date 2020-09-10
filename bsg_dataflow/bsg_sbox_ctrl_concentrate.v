// MBT 8-15-2014
// FIXME untested
//
// Given a bit vector, generate
// permutation vectors that perform
// concentration (fwd) and deconcentration (bkwd).
//
//
//           bit   fwd          bkwd
//   pos.   vec    vec          vec
//     3     1 --\    1      --- 2
//                \         /
//     2     1 -\  -> 3  <--  -- 1
//               \           /
//     1     0    --> 2  <---    3 --> 1

//     0     1 -----> 0  <------ 0
//
//
// This version is fully general, and can support a variable
// number of inputs. However, the stable sort function would
// need to be expanded to support other numbers besides 4.
//

/*
 * This also would have worked (for case of 4):
 *
 * vec           fwd_perm   bkwd_perm
 * 3210
 *
 * 0000:  3210 11_10_01_00 3210 11_10_01_00
 * 0001:  3210 11_10_01_00 3210 11_10_01_00
 * 0010:  3201 11_10_00_01 3201 11_11_0
 * 0011:  3210 11_10_01_00 3210
 * 0100:  3012 11_00_01_10 3012
 * 0101:  3120 11_01_10_00 3120
 * 0110:  3021 11_00_10_01 3102
 * 0111:  3210 11_10_01_00 3210
 *
 * 1000:  0213 00_10_01_11 0213
 * 1001:  1230 01_10_11_00 1230
 * 1010:  0231 00_10_11_01 1203
 * 1011:  2310 10_11_01_00 2310
 * 1100:  1032 01_00_11_10 1032
 * 1101:  1320 01_11_10_00 2130
 * 1110:  0321 00_11_10_01 2103
 * 1111:  3210 11_10_01_00 3210
 *
 */

`include "bsg_defines.v"

module bsg_sbox_ctrl_concentrate #(parameter width_p=4, lg_width_p=$bits(width_p))
   (  input  [width_p-1:0] vec_i
      , output [lg_width_p-1:0] fwd_perm_o  [width_p-1:0]
      , output [width_p-1:0] fwd_valid_o
      , output [lg_width_p-1:0] bkwd_perm_o [width_p-1:0]
      );

initial
  // just because bsg_sort has not implemented sorting networks
  // besides four elements
  assert(width_p==4) 
    else $error("stable sort function needs to be generalized to support width_p!=4");


   // *********************************************
   // *
   // * generate forward indices using sorting network
   // *

   // * initialize input to sorting network with indexes of bits
   // * and high bit set to vector bit. we do a stable sort on the vector bit
   // * and the output is a vector of the indexes, concentrated.
   //

   wire [lg_width_p:0] fwd_sort_li [width_p-1:0];
   wire [lg_width_p:0] fwd_sort_lo [width_p-1:0];

   for (i = 0; i < width_p; i=i+1)
     assign fwd_sort_li[i] = { ~vec_i[i], i[0+:lg_width_p] };

   bsg_sort_stable #(  .width_p(lg_width_p+1)
                       , .items_p(4)
                       , .t_p(width_p)    // sort based on vector bit
                       , .b_p(width_p-1)
                       ) sort_stable
   (.i(fwd_sort_li)
    ,.o(fwd_sort_lo)
    );

   for (i=0; i < width_p; i=i+1)
     begin
        assign fwd_perm_o[i][0+:lg_width_p] = fwd_sort_lo[i][0+:lg_width_p];
        assign fwd_valid_o[i] = fwd_sort_lo[i][lg_width_p];
     end

   // *********************************************
   // *
   // * generate backward indices using sorting network
   // *
   //

   wire [lg_width_p*2-1:0] bkwd_sort_li [width_p-1:0];
   wire [lg_width_p*2-1:0] bkwd_sort_lo [width_p-1:0];

   for (i = 0; i < width_p; i=i+1)
     assign bkwd_sort_li[i] = { fwd_perm_o[i], i[0+:lg_width_p] };

   bsg_sort_stable #( .width_p(2*lg_width_p)
                      , .items_p(4)
                      , .t_p(2*lg_width_p-1)
                      , .b_p(lg_width_p)
                      ) sort_stable_2
   (.i(bkwd_sort_li)
    ,.o(bkwd_sort_lo)
    );

   for (i=0; i < width_p; i=i+1)
     assign bkwd_perm_o[i] = bkwd_sort_lo[i][0+:lg_width_p];

endmodule

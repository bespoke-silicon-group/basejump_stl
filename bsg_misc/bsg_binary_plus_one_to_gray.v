// MBT 2/28/2015
//
// This module computes gray(x+1),
// where x is a binary value.
//
// It has not been determined whether this beats
// synthesis of (x+1) ^ ((x+1) >> 1). Synopsys has some
// killer adder implementations.
// However, it has a good shot, since it uses
// mostly ands and not xors.
//

/*
 Since x and x+1 differ by at most 1 bit, we
 can figure out which bit it is that will change.

 Take for example:

 x  g(x) g(x+1) diff

 000 000 001     001
 001 001 011     010
 010 011 010     001
 011 010 110     100
 100 110 111     001
 101 111 101     010
 110 101 100     001
 111 100 000     100

 We can replicate diff with:

  x   and-scan  drop_hi 0append1  (~(x >> 1)  & x) drop_hi
 000  000       00     0001      0001              001
 001  001       01     0011      0010              010
 010  000       00     0001      0001              001
 011  011       11     0111      0100              100
 100  000       00     0001      0001              001
 101  001       01     0011      0010              010
 110  000       00     0001      0001              001
 111  111       11     0111      0100              100
 */


`include "bsg_defines.v"

module bsg_binary_plus_one_to_gray #(parameter width_p = -1)
   (input [width_p-1:0] binary_i
    , output [width_p-1:0] gray_o
    );

   wire [width_p-1:0] binary_scan;

   bsg_scan #(.width_p(width_p)
              ,.and_p(1)
              ,.lo_to_hi_p(1)
              ) scan_and (.i(binary_i), .o(binary_scan));

   wire [width_p:0]   temp = { 1'b0, binary_scan[width_p-2:0], 1'b1};
   wire [width_p-1:0] edge_detect = ~temp[width_p:1] & temp[width_p-1:0];

   // xor gray code of binary_i with the bit that should change
   assign gray_o = (binary_i >> 1) ^ (binary_i) ^ edge_detect;

endmodule

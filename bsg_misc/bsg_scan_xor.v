// MBT 10/16/14
//
// note: this does a scan from hi bit to lo
// so the high bit is always unchanged
//

module bsg_scan_xor #(parameter width_p = -1)
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

   // derivation of the scan code:

   // width_p = 1           1
   // t1 = i
   //
   // width_p = 4           1111
   // t1 = i ^ (i >> 1)     1111 ^ 0111 --> 1000
   // t2 = t1 ^ (t1 >> 2)   1000 ^ 0010 --> 1010
   // t4 = t2 ^ (t2 >> 4)   1010 ^ 0000 --> 1010  (not needed)

   // width_p = 5           11111
   // t1 = i ^ (i >> 1)     11111 ^ 01111 --> 10000
   // t2 = t1 ^ (t1 >> 2)   10000 ^ 00100 --> 10100
   // t4 = t2 ^ (t2 >> 4)   10100 ^ 00001 --> 10101 (needed)

   // width_p = 8           1111_1111
   // t1 = i ^ (i >> 1)     1111_1111 ^ 0111_1111 --> 1000_0000
   // t2 = t1 ^ (t1 >> 2)   1000_0000 ^ 0010_0000 --> 1010_0000
   // t4 = t2 ^ (t2 >> 4)   1010_0000 ^ 0000_1010 --> 1010_1010 (needed)

   //
   //        1 2 3 4 5 6 7 8 9
   // clog2  0 1 2 2 3 3 3 3 4

   genvar j;

   wire [$clog2(width_p)+1:0][width_p-1:0] t;

   assign t[0] = i;

   for (j = 0; j < $clog2(width_p); j = j + 1)
     begin : row
        assign t[j+1] = t[j] ^ (t[j] >> (1 << j));
     end

   assign o = t[$clog2(width_p)];

   // always @(o)
   //  $display("bsg_scan_xor %b = %b",i,o);

endmodule

// MBT 10/16/14
//
// note: this does a scan from hi bit to lo
// so the high bit is always unchanged
//

module bsg_scan #(parameter width_p = -1
                  , parameter xor_p = 0
                  , parameter and_p = 0
                  , parameter or_p = 0
                  , parameter lo_to_hi_p = 0
                  )
   (input    [width_p-1:0] i
    , output [width_p-1:0] o
    );

   // derivation of the scan code (xor case):

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

   // synopsys translate_off
   initial
      assert( $countones({xor_p & 1'b1, and_p & 1'b1, or_p & 1'b1}) == 1)
        else $error("bsg_scan: only one function may be selected\n");
   // synopsys translate_on

   genvar j;

   wire [$clog2(width_p):0][width_p-1:0] t;

   wire [width_p-1:0]                      fill;

   // streaming operation; reverses bits
   if (lo_to_hi_p)
     assign t[0] = {<< {i}};
   else
     assign t[0] = i;

   for (j = 0; j < $clog2(width_p); j = j + 1)
     begin : row
        wire [width_p-1:0] shifted = width_p ' ({fill, t[j]} >> (1 << j));

        if (xor_p)
          begin
             assign fill = { width_p {1'b0} };
             assign t[j+1] = t[j] ^ shifted;
          end
        else if (and_p)
          begin
             assign fill = { width_p {1'b1} };
             assign t[j+1] = t[j] & shifted;
          end
        else if (or_p)
          begin
             assign fill = { width_p {1'b0} };
             assign t[j+1] = t[j] | shifted;
          end
     end

   // reverse bits
   if (lo_to_hi_p)
     assign o = {<< {t[$clog2(width_p)]}};
   else
     assign o = t[$clog2(width_p)];

   // always @(o)
   //  $display("bsg_scan (xor_p %b and_p %b  or_p %b) %b = %b",xor_p[0],and_p[0],or_p[0],i,o);

endmodule

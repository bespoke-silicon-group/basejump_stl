// MBT 10-26-14
//
//
// Counts the number of set bits in a thermometer code.
// A thermometer code is of the form 0*1*.
//

`include "bsg_defines.v"

module bsg_thermometer_count #(parameter width_p = -1)
   (input [width_p-1:0] i
    // we need to represent width_p+1 values (0..width_p), so
    // we need the +1.
    , output [$clog2(width_p+1)-1:0] o
    );

   // parallel prefix is a bit slow for these cases

   if (width_p == 1)
     assign o = i;
   else
     if (width_p == 2)
       assign o = { i[1], i[0] & ~ i[1] };
     else
       // 000  0     0
       // 001  0     1
       // 011  1     0
       // 111  1     1

       if (width_p == 3)
         assign o = { i[1], i[2] | (i[0] & ~i[1]) };
       else
       // 3210
       // 0000  0     0     0
       // 0001  0     0     1
       // 0011  0     1     0
       // 0111  0     1     1
       // 1111  1     0     0

         if (width_p == 4)
	   //           assign o = {i[3], ~i[3] & i[1], (~i[3] & i[0]) & ~(i[2]^i[1]) };
	   // DC likes the xor's
           assign o = {i[3], ~i[3] & i[1], ^i };
         else

           // this converts from a thermometer code (01111)
           // to a one hot code                     (10000)
           // basically by edge-detecting it.
           //
           // the important parts are the corner cases:
           // 0000 --> ~(0_0000) & (0000_1) --> 0000_1 (0)
           // 1111 --> ~(0_1111) & (1111_0) --> 1_0000 (4)
           //

           begin : big
              wire [width_p:0] one_hot =   (  ~{ 1'b0,      i } )
                & (   { i   ,   1'b1 } );

              bsg_encode_one_hot #(.width_p(width_p+1)) encode_one_hot
                (.i(one_hot)
                 ,.addr_o(o)
                 ,.v_o()
                 );
           end

endmodule

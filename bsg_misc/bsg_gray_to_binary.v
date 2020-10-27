// MBT 7/25/14
//
// From "advanced chip design: practical examples in verilog"
// p. 183.
//

`include "bsg_defines.v"

module bsg_gray_to_binary #(parameter width_p = -1)
   (input    [width_p-1:0] gray_i
    , output [width_p-1:0] binary_o
    );

   // or alternatively
   // the entertaining:
   //   assign binary_o[width_p-1:0] = ({1'b0, binary_o[width_p-1:1]} ^ gray_i[width_p-1:0]);

/*
   assign binary_o[width_p-1] = gray_i[width_p-1];

   generate
      genvar i;

      for (i = 0; i < width_p-1; i=i+1)
        begin
           assign binary_o[i] = binary_o[i+1] ^ gray_i[i];
        end

   endgenerate
 */

   // logarithmic depth of the above

   bsg_scan #(.width_p(width_p)
	      ,.xor_p(1)
	      ) scan_xor
        (.i(gray_i)
        ,.o(binary_o));

endmodule

// bsg_hash_bank
//
// This module takes a binary address, and a constant number of banks, and then hashes the
// address across the banks efficiently; outputing the bank #, and the index at that bank.
// This is useful for banking memories; or spreading cache coherence directory information
// across multiple directories.
//
// Since we support non-power of two banks, some banks will be larger than others.
// The hash function guarantees that the difference in size of the banks is no greater than 1.
//
// Here is what is supported:
//
// Bank counts of 2^n * (2^m-1), where n=0,1,2... and m = 1,2,3,4,5...
//
// i.e., 2,3,4,6=2*3,7,8,12=3*4,14=7*2,15,16,24=3*8,28=4*7,30=15*2,32
//        1  3  7 15  31   63  127       
//       ------------------------
//     1| 1  3  7  15  31   63  127
//     2| 2  6 14  30  62  126  254  --> Bank counts of 1,2,3,4,6,7,8,12,14,15,16,24,28,30,31,32
//     4| 4 12 28  60  124 252  508
//     8| 8 24 56  120 248 504  ....
//    16|16 48 112 240 496
//    32|32 96 224
//    64|64 192
//
// The function uses the higher-order bits to select the bank number
// to use lower-order bits, you can reverse the bit sequence on input to the module
// using the {<< {i}} operator.
//
// see also the module bsg_hash_bank_reverse, which takes a bank and index
// and produces the original address
//
// TODO: it may make sense to add support for other #'s of banks via
// the Verilog modulo operator; it may be sufficiently efficient for small binary addresses
//
// TODO: evaluate PPA versus yosys and DC modulo operator
//
// TODO: a pathway to support hash functions that are a factor of 2^n+1 seems possible but is only onlined in this code
// see comments for how the math would work. This would support banking of 5,9 and maybe higher.
//
//

`include "bsg_defines.v"

module bsg_hash_bank #(parameter banks_p="inv", width_p="inv",     
                       index_width_lp=$clog2((2**width_p+banks_p-1)/banks_p), 
                       lg_banks_lp=`BSG_SAFE_CLOG2(banks_p), debug_lp=0)
  (/* input clk,*/
   input [width_p-1:0] i
   ,output [lg_banks_lp-1:0]      bank_o
   ,output [index_width_lp-1:0]   index_o
  );
  
  genvar j;
  
  
  if (banks_p == 1)
    begin: hash1
      assign index_o = i;
      assign bank_o = 1'b0;
    end	
  else
  if (banks_p == 2)
    begin: hash2
      assign bank_o  = i[width_p-1];
      assign index_o = i[width_p-2:0];
    end  
  else
    if (~banks_p[0])
      begin: hashpow2
        assign bank_o [0] = i[width_p-1];
        bsg_hash_bank #(.banks_p(banks_p >> 1),.width_p(width_p-1)) bhb (/* .clk(clk), */.i(i[width_p-2:0]),.bank_o(bank_o[lg_banks_lp-1:1]),.index_o(index_o));
      end
  else
    if ((banks_p & (banks_p+1))==0) // test for (2^N)-1
    begin : hash3
      if ((width_p % lg_banks_lp)!=0)
        begin : odd
          wire _unused;
          
          bsg_hash_bank #(.banks_p(banks_p),.width_p(width_p+1))
          hf (/* .clk,*/ .i({i,1'b0}),.bank_o(bank_o),.index_o({index_o,_unused}));
        end
      else 
        begin : even
          localparam frac_width_lp = width_p/lg_banks_lp;
          wire [lg_banks_lp-1:0][frac_width_lp-1:0] unzippered;
	
	      /*  This is the hash function we implement.

          banks=3

          00 XX XX -> Bank 0, 00 XX XX
		      01 XX XX -> Bank 1, 00 XX XX
		      10 XX XX -> Bank 2, 00 XX XX
		      11 00 XX -> Bank 0, 01 00 XX
		      11 01 XX -> Bank 1, 01 00 XX
		      11 10 XX -> Bank 2, 01 00 XX
		      11 11 00 -> Bank 0, 01 01 00
		      11 11 01 -> Bank 1, 01 01 00
		      11 11 10 -> Bank 2, 01 01 00
		      11 11 11 -> Bank 3, 01 01 01

         banks=5 --> partially reuse 2^N-1 = 15 trick
          banks=9 --> partially reuse 2^N-1 = 63 trick
          banks=21 --> partially reuse 2^N-1 = 63 trick
          banks=15 --> partially reuse 2^N-1 = 255 trick
          banks=17 --> partially reuse 2^N-1 = 255 trick
          banks=51 --> "
          banks=85 -->
          banks=73 --> 2^N-1=511 
          banks=11,31,33,93,341 --> 2^N-1=1023
          banks=23,89->2047

          H
                    Bank      Index
		  
          0000 XXXX XXXX 0    00 XXXX XXXX 
          0001 XXXX XXXX 1    00 XXXX XXXX 
          0010 XXXX XXXX 2    00 XXXX XXXX 
          0011 XXXX XXXX 3    00 XXXX XXXX 
          
          0100 XXXX XXXX 4    00 XXXX XXXX 
          0101 XXXX XXXX 0    01 XXXX XXXX 
          0110 XXXX XXXX 1    01 XXXX XXXX 
          0111 XXXX XXXX 2    01 XXXX XXXX 
          
          1000 XXXX XXXX 3    01 XXXX XXXX 
          1001 XXXX XXXX 4    01 XXXX XXXX 
          1010 XXXX XXXX 0    10 XXXX XXXX 
          1011 XXXX XXXX 1    10 XXXX XXXX 
          
          1100 XXXX XXXX 2    10 XXXX XXXX 
          1101 XXXX XXXX 3    10 XXXX XXXX 
          1110 XXXX XXXX 4    10 XXXX XXXX 
          
          1111 0000 XXXX 0    11 0000 XXXX 
          1111 0001 XXXX 1    11 0000 XXXX 
          1111 0010 XXXX 2    11 0000 XXXX 
          1111 0011 XXXX 3    11 0000 XXXX 
          1111 0100 XXXX 4    11 0000 XXXX 
          1111 0101 XXXX 0    11 0001 XXXX 
          1111 0110 XXXX 1    11 0001 XXXX 
          1111 0111 XXXX 2    11 0001 XXXX 
          1111 1000 XXXX 3    11 0001 XXXX 
          1111 1001 XXXX 4    11 0001 XXXX 
          1111 1010 XXXX 0    11 0010 XXXX 
          1111 1011 XXXX 1    11 0010 XXXX 
          1111 1100 XXXX 2    11 0010 XXXX 
          1111 1101 XXXX 3    11 0010 XXXX 
          1111 1110 XXXX 4    11 0010 XXXX 
          1111 1111 XXXX 0    11 0011 XXXX 

          1111 1111 0000 0    11 0011 0000 
          1111 1111 0001 1    11 0011 0000 
          1111 1111 0010 2    11 0011 0000  
          1111 1111 0011 3    11 0011 0000  
          1111 1111 0100 4    11 0011 0000  
          1111 1111 0101 0    11 0011 0001  
          1111 1111 0110 1    11 0011 0001  
          1111 1111 0111 2    11 0011 0001  
          1111 1111 1000 3    11 0011 0001  
          1111 1111 1001 4    11 0011 0001  
          1111 1111 1010 0    11 0011 0010  
          1111 1111 1011 1    11 0011 0010  
          1111 1111 1100 2    11 0011 0010  
          1111 1111 1101 3    11 0011 0010  
          1111 1111 1110 4    11 0011 0010  
          1111 1111 1111 0    11 0011 0011  
          
          So basically, for conversion: 
            1) replace 1111 with 0011 (base/5).
            2) for first non-1111 value Y replace with Y/5 
               (this generalizes for normal case of 15 banks --> 15/15 -> 1.   

          banks=7
		                        bank     index
		      000 XXX XXX -->    0   0 XXX XXX
		      001 XXX XXX  -->   1   0 XXX XXX
		      010 XXX XXX  -->   2   0 XXX XXX
		      011 XXX XXX  -->   3   0 XXX XXX
		      100 XXX XXX  -->   4   0 XXX XXX
		      101 XXX XXX  -->   5   0 XXX XXX
		      110 XXX XXX  -->   6   0 XXX XXX
		      111 000 XXX  -->   0   1 000 XXX
		      111 001 XXX  -->   1   1 000 XXX
		   ...
		      111 110 XXX  -->   6   1 000 XXX
		      111 111 000  -->   0   1 001 000
		      111 111 001  -->   1   1 001 000  
		    ..
		      111 111 110  -->   6   1 001 000 
		      111 111 111  -->   0   1 001 001   
		  
          Notice the pattern -- if there is a 11 or 111, we skip to the next pair of bits
          to find the bank index. 
        
          To compute the index, we use a 01 if it is a 11, a 00 if it the pair of
          bits after the last 11, othwerise we use the same bits as the input.

          // for odd numbers of bits; add a zero to the end, invoke even routine, and then drop low bit of the index at the end.
          //
          //      A                        D (a = add, d=drop)
          00 XX X 0 -> Bank 0,   00 XX X0 
		      01 XX X 0 -> Bank 1,   00 XX X0
		      10 XX X 0 -> Bank 2,   00 XX X0
		      11 00 X 0 -> Bank 0,   01 00 X0
		      11 01 X 0 -> Bank 1,   01 00 X0
		      11 10 X 0 -> Bank 2,   01 00 X0
		      11 11 0 0 -> Bank 0,   01 01 00
		      11 11 1 0 -> Bank 2,   01 01 00

	      */      
      
          // and tuplets of bank_p-1 consecutive bits
          wire [frac_width_lp-1:0] one_one;
		
          bsg_reduce_segmented #(.segments_p(frac_width_lp),.segment_width_p(lg_banks_lp),.and_p(1'b1)) brs
          (.i(i),.o(one_one));
          
          bsg_transpose #(.width_p(lg_banks_lp), .els_p(frac_width_lp)) unzip (.i(i),.o(unzippered));
      
          wire [frac_width_lp-1:0] one_one_and_scan;
      
	      // and bits from top to bottom, zeroing everything out after first 
          // zero; this is the mask the determines when 11's end.

          bsg_scan #(.width_p(frac_width_lp),.and_p(1)) scan(.i(one_one),.o(one_one_and_scan));
      
          // 111000
          // 111100
          // ------
          // 000100
      
          wire [frac_width_lp-1:0] not_one_one_and_scan = ~one_one_and_scan;
          wire [frac_width_lp-1:0] shifty;
          
          if (frac_width_lp > 1)
            assign shifty = { 1'b1, one_one_and_scan[frac_width_lp-1:1] };
          else
            assign shifty = { 1'b1 };
          
          //  wire [even_width_lp/2-1:0] border 
          //  = (~one_one_and_scan) & {1'b1, one_one_and_scan >> 1};
  
          wire [frac_width_lp-1:0] border = not_one_one_and_scan & shifty;

          // for the top bit of each pair, it should be 0 if it
          // is border or one_one_and_scan; otherwise it should be the top bit
          // from the original sequence.
        
          // for the bottom bit of each pair, it should be a 0 if border
          // a one if one_one_and_scan, otherwise it should be the bit from the original
          // sequence.

          wire [lg_banks_lp-1:0][frac_width_lp-1:0] bits;

          for (j = 1; j < lg_banks_lp; j = j + 1)
            begin: rof2
              assign bits[j] = unzippered[j] & ~(border | one_one_and_scan);
            end
          
          assign bits[0] = (one_one_and_scan)  | (unzippered[0] & ~one_one_and_scan & ~border);
   
          wire [width_p-1:0] transpose_lo;
    
          bsg_transpose #(.els_p(lg_banks_lp), .width_p(frac_width_lp)) zip (.i({bits}),.o(transpose_lo));
      
          assign index_o = transpose_lo[index_width_lp-1:0];

          for (j = 0; j < lg_banks_lp; j = j + 1)
            begin: rof1
              // mask out all but border bits and use as the hash index bit
              assign bank_o[j] = | (border & unzippered[j]);
            end

/*          if (debug_lp)
	          always @(negedge clk)
    	      begin
	            $display ("%b -> %b %b %b %b %b %b %b %b %b %b",
	                      i, one_one, one_one_and_scan, not_one_one_and_scan, shifty, border, unzippered[1], 
                        unzippered[0], bits[1], bits[0], index_o);
            end	
 */
        end 	 
      end 
  else
      initial 
        begin 
          assert(0) else $error("unhandled case, banks_p = ", banks_p); 
        end
  
endmodule

// bsg_hash_bank_reverse
//
// See paired module bsg_hash_bank.
// This module is the inverse; taking a bank number and an index, and producing the original address.
//

`include "bsg_defines.v"

module bsg_hash_bank_reverse #(parameter banks_p="inv", width_p="inv", index_width_lp=$clog2((2**width_p+banks_p-1)/banks_p), lg_banks_lp=`BSG_SAFE_CLOG2(banks_p), debug_lp=0)
  (/* input clk,*/ 

   input [index_width_lp-1:0] index_i
   , input [lg_banks_lp-1:0] bank_i
   , output [width_p-1:0] o
   );
  
  if (banks_p == 1)
    begin: hash1
      assign o = index_i;
    end	
  else  
  if (banks_p == 2)
    begin: hash2
      assign o = { bank_i, index_i };
    end  
  else
   if (~banks_p[0])
      begin: hashpow2
        assign o[width_p-1] = bank_i[0];
        bsg_hash_bank_reverse #(.banks_p(banks_p >> 1),.width_p(width_p-1)) bhbr (/* .clk(clk) , */ .index_i(index_i[index_width_lp-1:0]),.bank_i(bank_i[lg_banks_lp-1:1]),.o(o[width_p-2:0]));
      end
  else    
    if ((banks_p & (banks_p+1)) == 0) // test for (2^N)-1
    begin : hash3
      if (width_p % lg_banks_lp)
        begin : odd
          wire _unused;
        
          bsg_hash_bank_reverse #(.banks_p(banks_p),.width_p(width_p+1)) rhf
          ( /* .clk(clk),*/ .index_i({index_i, 1'b0}), .bank_i(bank_i), .o({o[width_p-1:0], _unused}));

        end
      else        
        begin : even  
          /*  This is the hash function we implement.

          Bank Zero,   0 XX XX --> 00 XX XX
		      Bank One,    0 XX XX --> 01 XX XX
		      Bank Two,    0 XX XX --> 10 XX XX
          Bank Zero,   1 00 XX --> 11 00 XX
		      Bank One,    1 00 XX --> 11 01 XX 
		      Bank Two,    1 00 XX --> 11 10 XX 
		      Bank Zero,   1 01 00 --> 11 11 00
		      Bank One,    1 01 00 --> 11 11 01
		      Bank Two,    1 01 00 --> 11 11 10
		      Bank Zero,   1 01 01 --> 11 11 11
       
          the algorithm is:
        
          starting from the left; the first 00 you see, substitute the bank number
          starting from the left; as long as you see 01, substitute 11.
        
          */
          
          localparam frac_width_lp = width_p/lg_banks_lp;
          wire [lg_banks_lp-1:0][frac_width_lp-1:0] unzippered;
          wire [width_p-1:0] index_i_ext = (width_p) ' (index_i); // add 0's on
          
          bsg_transpose #(.width_p(lg_banks_lp), .els_p(frac_width_lp)) unzip (.i(index_i_ext),.o(unzippered));

          genvar j;
  
          // and tuplets of lg_bank_lp-1 consecutive 0 bits
          wire [frac_width_lp-1:0] zero_pair;

          bsg_reduce_segmented #(.segments_p(frac_width_lp),.segment_width_p(lg_banks_lp),.nor_p(1)) brs
          (.i(index_i_ext),.o(zero_pair));
          
          wire [frac_width_lp-1:0] zero_pair_or_scan;
 
          bsg_scan #(.width_p(frac_width_lp),.or_p(1)) scan
          (.i(zero_pair),.o(zero_pair_or_scan));  
  
          // everything that is 0 should be converted to a 11
          // the first 1 should be converted to the bank # 
          // the following 1's should just take the old bit values.

          wire [frac_width_lp-1:0] first_one;
          
          if (frac_width_lp > 1)
            assign first_one = zero_pair_or_scan & ~{1'b0, zero_pair_or_scan[frac_width_lp-1:1]};
          else
            assign first_one = zero_pair_or_scan;

          wire [lg_banks_lp-1:0][frac_width_lp-1:0] bits;
          
          for (j = 0; j < lg_banks_lp; j=j+1)
            begin: rof2
              assign bits[j] = (zero_pair_or_scan & ~first_one & unzippered[j]) | (first_one & { frac_width_lp { bank_i[j] }}) | ~zero_pair_or_scan;
            end

 /*         if (debug_lp)
   begin
          always @(negedge clk)
            begin
              $display ("%b %b -> ZP(%b) ZPS(%b) FO(%b) TB(%b) BB(%b) %b ",
                       index_i, bank_i, zero_pair, zero_pair_or_scan, first_one, top_bits, bot_bits, o);
            end
        end
   */       
          wire [width_p-1:0] transpose_lo;
          bsg_transpose #(.els_p(lg_banks_lp), .width_p(frac_width_lp)) zip (.i({bits}),.o(transpose_lo));  
          
          assign o = transpose_lo[width_p-1:0];
        end
    end
  else
      initial 
        begin 
          assert(0) else $error("unhandled case, banks_p = ", banks_p); 
        end	
  
endmodule	

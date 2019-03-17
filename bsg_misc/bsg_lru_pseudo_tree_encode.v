/**
 *  Name:
 *    bsg_lru_pseudo_tree_encode.v
 *
 *  Description:
 *    Pseudo-Tree-LRU decode unit.
 *    Given the LRU bits, traverses the pseudo-LRU tree and returns the LRU way_id.
 */

module bsg_lru_pseudo_tree_encode
  #(parameter ways_p       = "inv"
    ,localparam lg_ways_lp = `BSG_SAFE_CLOG2(ways_p)
  )
  (
    input [ways_p-2:0] lru_i
    , output logic [lg_ways_lp-1:0] way_id_o
  );

  logic [ways_p-2:0]                     mask;
  logic [lg_ways_lp-1:0][ways_p-2:0]     pe_i;
  logic [lg_ways_lp-1:0][lg_ways_lp-1:0] pe_o;
  
  
  genvar i;
  generate 
    for(i=0; i<ways_p-1; i++) begin: rof
      if(i == 0) begin: fi
	    assign mask[i] = 1'b1;
	  end
	  else if(i%2 == 1) begin: fi
	    assign mask[i] = mask[(i-1)/2] & ~lru_i[(i-1)/2];
	  end
	  else begin: fi
	    assign mask[i] = mask[(i-2)/2] & lru_i[(i-2)/2];
	  end
    end
    
    
    for(i=0; i<lg_ways_lp; i++) begin: rof2
    
      assign way_id_o[lg_ways_lp-1-i] = lru_i[pe_o[i]];
    
	  if(i == 0) begin: fi2
	    assign pe_i[i] = mask;
	    assign pe_o[i] = '0;
	  end
	  else begin: fi2
        assign pe_i[i] = pe_i[i-1] ^ ({{(ways_p-2){1'b0}}, 1'b1} << pe_o[i-1]);
	  end
	  
      if(i != 0) begin: fi3
	    bsg_priority_encode 
          #(.width_p(ways_p-1)
            ,.lo_to_hi_p(1'b1)
          ) pe 
          (.i(pe_i[i])
           ,.addr_o(pe_o[i])
           ,.v_o()
          );
	  end
    end
  endgenerate
  
endmodule

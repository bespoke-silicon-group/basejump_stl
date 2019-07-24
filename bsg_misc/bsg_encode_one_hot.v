// MBT 10-26-2014
//
// bsg_encode_one_hot
//
// encodes a one hot signal into an address
// 0001     --> 0, v=1
// 0010     --> 1, v=1
// 0100     --> 2, v=1
// 1000     --> 3, v=1
// 0000     --> 0, v=0
// O*1O*1O* --> undefined

// we implement at this as a parallel prefix computation
// it is basically a big, clever tree of OR's with a
// certain structure.
//

module bsg_encode_one_hot #(parameter width_p=8, parameter lo_to_hi_p=1)
   (input    [width_p-1:0]         i
    , output [`BSG_SAFE_CLOG2(width_p)-1:0] addr_o  // feed 32 bits in, requires spots 32 to encode (0..31)
    , output v_o                           // whether any bit was found
    );

   localparam half_width_lp    = width_p >> 1;
   localparam aligned_width_lp = 1 << $clog2(width_p);

   logic [`BSG_SAFE_CLOG2(width_p)-1:0] addr_lo;

   if (width_p == 1)
     begin : base
        assign v_o = i;

	// should be ignored
        assign addr_lo = 1'bX;
     end
   else
     // align at the top; this should be more efficient
     // than aligning at intermediate nodes
     // e.g. 4 != (1 << 2)
     if (width_p != aligned_width_lp)
       begin : unaligned
	  wire [$clog2(aligned_width_lp)-1:0] aligned_addr;
	  wire [aligned_width_lp-width_p-1:0] zero_pad = { (aligned_width_lp-width_p) {1'b0} };
	  wire [aligned_width_lp-1:0] 	      padded = lo_to_hi_p ? { zero_pad, i } : { i, zero_pad };
	  
          bsg_encode_one_hot #(.width_p(aligned_width_lp))
          align(.i      (padded      )
                ,.addr_o(aligned_addr)
                ,.v_o   (v_o         )
                );

	  assign addr_lo = aligned_addr[$clog2(width_p)-1:0];
       end
     else
       begin: aligned
          wire [1:0] [`BSG_SAFE_CLOG2(half_width_lp)-1:0] addrs;
          wire [1:0]                     vs;

          bsg_encode_one_hot #(.width_p(half_width_lp)) left
            (.i      (i    [0+:half_width_lp])
             ,.addr_o(addrs[0]               )
             ,.v_o   (vs   [0]               )
             );

          bsg_encode_one_hot #(.width_p(half_width_lp)) right
            (.i      (i[half_width_lp+:half_width_lp])
             ,.addr_o(addrs[1]                       )
             ,.v_o   (vs   [1]                       )
             );

          assign v_o     = | vs;
	  if (width_p == 2)
	    assign addr_lo = vs[lo_to_hi_p];
	  else
            assign addr_lo = { vs[lo_to_hi_p], (addrs[0] | addrs[1]) };
       end // block: aligned

  `ifdef SYNTHESIS
    assign addr_o = addr_lo;
  `else
    assign addr_o = (((i-1) & i) == '0)
      ? addr_lo
      : {`BSG_SAFE_CLOG2(width_p){1'bx}};
  `endif


endmodule // bsg_encode_one_hot


// encodes a one hot signal into an address
// 0001     --> 0, v=1
// 0010     --> 1, v=1
// 0100     --> 2, v=1
// 1000     --> 3, v=1
// 0000     --> 0, v=0
// O*1O*1O* --> undefined
`include "bsg_defines.v"

	
// we implement at this as a parallel prefix computation
// it is basically a big, clever tree of OR's with a
// certain structure (see sample debug output).	

module bsg_encode_one_hot #(parameter width_p=8, parameter lo_to_hi_p=1, parameter debug_p=0)
(input [width_p-1:0] i
 ,output [`BSG_SAFE_CLOG2(width_p)-1:0] addr_o
 ,output v_o // whether any bits are set
);

  localparam levels_lp = $clog2(width_p);
  // adjust for non-power of two input
  localparam aligned_width_lp = 1 << $clog2(width_p);
  
  genvar level;
  genvar segment;
  
  wire [levels_lp:0][aligned_width_lp-1:0] addr;
  wire [levels_lp:0][aligned_width_lp-1:0] v; 
  
  // base case, also handle padding for non-power of two inputs
  assign v   [0] = lo_to_hi_p ? ((aligned_width_lp) ' (i)) :  i << (aligned_width_lp - width_p);
  assign addr[0] = (width_p == 1) ? '0 : `BSG_UNDEFINED_IN_SIM('0);
  
  for (level = 1; level < levels_lp+1; level=level+1)
    begin : rof
      localparam segments_lp = 2**(levels_lp-level);
      localparam segment_slot_lp = aligned_width_lp/segments_lp;
      localparam segment_width_lp = level; // how many bits are needed at each level
      
      for (segment = 0; segment < segments_lp; segment=segment+1)
        begin : rof1
          wire [1:0] vs = {
                           v[level-1][segment*segment_slot_lp+(segment_slot_lp >> 1)] 
                           , v[level-1][segment*segment_slot_lp]
                          };
          
          assign v[level][segment*segment_slot_lp] = | vs;

          if (level == 1)
            assign addr[level][(segment*segment_slot_lp)+:segment_width_lp] = { vs[lo_to_hi_p] };                   
          else
            begin : fi
              assign addr[level][(segment*segment_slot_lp)+:segment_width_lp]
              = { vs[lo_to_hi_p]
                 , addr[level-1][segment*segment_slot_lp+:segment_width_lp-1]
                 | addr[level-1][segment*segment_slot_lp+(segment_slot_lp >> 1)+:segment_width_lp-1]
                };
            end        
        end  
    end	
  
  assign v_o = v[levels_lp][0];
  
// BSG_SAFE_CLOG2 handles width_p = 1 case
`ifdef SYNTHESIS
  assign addr_o = addr[levels_lp][`BSG_SAFE_CLOG2(width_p)-1:0];
`else
  assign addr_o = (((i-1) & i) == '0) 
                  ? addr[levels_lp][`BSG_SAFE_CLOG2(width_p)-1:0] 
                  : { `BSG_SAFE_CLOG2(width_p){1'bx}};

// generates debug output that looks like this:
//       (addr)                      (v)
// xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 00000000000000000000000000000100
// z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0z0 z0z0z0z0z0z0z0z0z0z0z0z0z0z0z1z0
// zz00zz00zz00zz00zz00zz00zz00zz10 zzz0zzz0zzz0zzz0zzz0zzz0zzz0zzz1
// zzzzz000zzzzz000zzzzz000zzzzz010 zzzzzzz0zzzzzzz0zzzzzzz0zzzzzzz1
// zzzzzzzzzzzz0000zzzzzzzzzzzz0010 zzzzzzzzzzzzzzz0zzzzzzzzzzzzzzz1
// zzzzzzzzzzzzzzzzzzzzzzzzzzz00010 zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz1
// addr_o=00010                     v_o=1 
  
  if (debug_p)
    always @(addr_o or v_o)
      begin
        `BSG_HIDE_FROM_VERILATOR(#1)
        for (integer k = 0; k <= $clog2(width_p); k=k+1)
          $display("%b %b",addr[k], v[k]);
        $display("addr_o=%b v_o=%b", addr_o, v_o);
      end
`endif

endmodule

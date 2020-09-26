// bsg_arb_round_robin
//
// generally prefer this arbiter instead of bsg_round_robin_arb
// if the interface works for you (eventually we would like to deprecate bsg_round_robin_arb
// as the interface is too complex)
//
// note:  (| reqs_i) can be used to determine if something is available to route (i.e. v_o)
//        bsg_encode_one_hot(grants_o) can be used to determine what item was selected
//
// compared to bsg_round_robin_arb this design is more scalable but uses more registers
//
// priority goes high-to-low, wrapping around
//
// todo: maybe use some hardcoded case statements to optimize small cases
//
//

`include "bsg_defines.v"

module bsg_arb_round_robin #(parameter width_p=-1)
  (input          clk_i
   , input        reset_i

   , input        [width_p-1:0] reqs_i    // which items would like to go; OR this to get v_o equivalent
   , output logic [width_p-1:0] grants_o  // one hot, selected item
   , input        yumi_i                  // the user of the arbiter accepts the arb output, change MRU
    );
  
  if (width_p == 1)
    begin: fi
      assign grants_o = reqs_i;
    end
  else
    begin: fi2
      // the current start location is represented as a thermometer code
      logic [width_p-1-1:0] thermocode_r, thermocode_n;  
  
      always_ff @(posedge clk_i)
        if (reset_i)
          thermocode_r <= '0; // initialize thermometer to all 0's
        else
          if (yumi_i)
            thermocode_r <= thermocode_n;
  
      // this is essentially implementing a cyclic scan
      wire [width_p*2-1:0] scan_li = { 1'b0, thermocode_r & reqs_i[width_p-1-1:0], reqs_i };
      wire [width_p*2-1:0] scan_lo;
  
      // default is high-to-lo
      bsg_scan #(.width_p(width_p*2)
                ,.or_p(1)
                ) scan
      (
       .i(scan_li)
       ,.o(scan_lo) // thermometer code of the next item
      ); 

      // finds the first 1
      wire [width_p*2-1:0] edge_detect = ~(scan_lo >> 1) & scan_lo;
    
      // collapse the cyclic scan
      assign grants_o = edge_detect[width_p*2-1-:width_p] | edge_detect[width_p-1:0];

      always_comb
        begin
          if (|scan_li[width_p*2-1-:width_p]) // no wrap around
            thermocode_n = scan_lo[width_p*2-1-:width_p-1];
          else // wrap around
            thermocode_n = scan_lo[width_p-1:1];
        end  
    end
endmodule

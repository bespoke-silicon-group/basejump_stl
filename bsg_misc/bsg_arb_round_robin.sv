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

`include "bsg_defines.sv"

// worker module that externalizes the current state vector
// so that more complex schedulers can be constructed hierarchically

module bsg_arb_round_robin_composable #(parameter `BSG_INV_PARAM(width_p)
					,localparam thermo_width_m1_lp=`BSG_SAFE_MINUS(width_p,2)
					)
  (input          clk_i
   , input        reset_i

   , input        [width_p-1:0] reqs_i    // which items would like to go; OR this to get v_o equivalent
   , output logic [width_p-1:0] grants_o  // one hot, selected item

   // the current start location is represented as a thermometer code
   , input        [thermo_width_m1_lp:0] thermocode_r_i
   , output logic [thermo_width_m1_lp:0] thermocode_n_o
    );

  if (width_p == 1)
    begin: fi
      assign grants_o = reqs_i;
      assign thermocode_n_o = 1'b0;
    end
  else
    begin: fi2
  
      // this is essentially implementing a cyclic scan
      wire [width_p*2-1:0] scan_li = { 1'b0, thermocode_r_i & reqs_i[width_p-1-1:0], reqs_i };
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
            thermocode_n_o = scan_lo[width_p*2-1-:width_p-1];
          else // wrap around
            thermocode_n_o = scan_lo[width_p-1:1];
        end  
    end
endmodule

`BSG_ABSTRACT_MODULE(bsg_arb_round_robin_composable)

module bsg_arb_round_robin #(parameter `BSG_INV_PARAM(width_p))
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

        bsg_arb_round_robin_composable #(.width_p(width_p)) barrc
          (.clk_i          (clk_i)
	   ,.reset_i       (reset_i)
	   ,.reqs_i        (reqs_i)
	   ,.grants_o      (grants_o)
	   ,.thermocode_r_i(thermocode_r)
	   ,.thermocode_n_o(thermocode_n)
	   );
     end
endmodule

//
// this implements a two-level priority scheme. each item can be flagged as a high priority.
// if nothing is high priority, then it acts as round robin among the items. If items are flagged
// as high priority, it round robins among the high priority items. 
//

module bsg_arb_round_robin_two_level #(parameter `BSG_INV_PARAM(width_p))
   (input          clk_i
    , input        reset_i
    , input        [1:0][width_p-1:0] reqs_i // 0 = high, 1 = low
    , output logic [width_p-1:0] grants_o    // one hot, selected item
    , output logic granted_high_o            // whether we granted a high priority item
    , input        yumi_i                    // the user of the arbiter accepts the arb output, change MRU
    );
   logic [width_p-1:0] grants_low_lo;
   logic [width_p-1:0] grants_high_lo;

   logic granted_low_lo;
   
   bsg_arb_round_robin #(.width_p(width_p)) low
     (.clk_i    (clk_i)
      ,.reset_i (reset_i)
      ,.reqs_i  (reqs_i[1])
      ,.grants_o(grants_low_lo)
      ,.yumi_i  (granted_low_lo & yumi_i)
      );

   bsg_arb_round_robin #(.width_p(width_p)) hi
     (.clk_i    (clk_i)
      ,.reset_i (reset_i)
      ,.reqs_i  (reqs_i[0])
      ,.grants_o(grants_high_lo)
      ,.yumi_i  (granted_high_o & yumi_i)
      );

   // we had a high grant 
   assign granted_high_o = (|reqs_i[0]);
   // we had a low grant that was not overridden by high grants
   assign granted_low_lo = (|reqs_i[1]) & ~granted_high_o;
   
   // if we did not grant high, then sub in the low grants
   assign grants_o = granted_high_o ? grants_high_lo : grants_low_lo;

endmodule
   
`BSG_ABSTRACT_MODULE(bsg_arb_round_robin)
`BSG_ABSTRACT_MODULE(bsg_arb_round_robin_two_level)
   

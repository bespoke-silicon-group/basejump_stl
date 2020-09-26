// parallel to bsg_counter_clear_up
// set occurs before down, and both events can take place in the same cycle.
// we do not output an overflow flag because there is no == that we would
// want to amortize the cost of

`include "bsg_defines.v"

module bsg_counter_set_down #(parameter width_p="inv", parameter init_val_p='0, parameter set_and_down_exclusive_p=0)
  (input clk_i
   , input reset_i
   , input set_i
   , input [width_p-1:0] val_i
   , input down_i
   , output [width_p-1:0] count_r_o
  );
  
  logic [width_p-1:0] ctr_r, ctr_n;
 
  always_ff @(posedge clk_i)	    
    if (reset_i)
      ctr_r <= width_p ' (init_val_p);
    else
      ctr_r <= ctr_n;
	
  if (set_and_down_exclusive_p)
    begin: excl
       always_comb 
	 begin
	    ctr_n = ctr_r;

	    if (set_i)
              ctr_n = val_i;
	    else
              if (down_i)
		ctr_n = ctr_n - 1;     
	 end
    end
     else
    begin : non_excl 
      always_comb
    	begin
          ctr_n = ctr_r;

          if (set_i)
            ctr_n = val_i;
      
          if (down_i)
            ctr_n = ctr_n - 1;
        end
    end
  
  assign count_r_o = ctr_r;
  
`ifndef SYNTHESIS
  always_ff @(negedge clk_i)
    begin
      if (!reset_i && down_i && (ctr_n == '1))
        $display("%m error: counter underflow at time %t", $time);

      if (~reset_i & set_and_down_exclusive_p & set_i & down_i)
	      $display("%m error: set and down non-exclusive at time %t", $time);
    end
`endif
      
endmodule

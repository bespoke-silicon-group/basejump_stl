// This counter counts up and is occasionally cleared.
// If up and clear are applied on the same cycle, the
// clear occurs first, and then the up.
//

module bsg_BL_LD_counter #(parameter max_val_p     = -1
			      // this originally had an "invalid" default value of -1
			      // which is a bad choice for a counter
                ,parameter init_val_p   = `BSG_UNDEFINED_IN_SIM('0)
                ,parameter ptr_width_lp = `BSG_SAFE_CLOG2(max_val_p+1)
			    ,parameter disable_overflow_warning_p = 0
                             )
   (input  clk_i
    , input reset_i
    , input v_i
    , input clear_i
    , input ready_i
    // fixme: count_o should be renamed to count_r_o since some modules
    // depend on this being a register and we want to indicate this at the interface level
    , output logic [ptr_width_lp-1:0] count_o
    , output logic v_o
    );

   // keeping track of number of entries and updating read and
   // write pointers, and displaying errors in case of overflow
   // or underflow
   logic counter_max, v_r;
   
   assign counter_max = (count_o == max_val_p);
   assign v_o = |count_o;

   always_ff @(posedge clk_i)
   	begin
   		if(v_i | counter_max)
   			v_r <= v_i;
   	end

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          count_o <= init_val_p;
        else if (v_i | v_r)
	  	    count_o <= clear_i ? (ptr_width_lp ' (ready_i) ) : (count_o+(ptr_width_lp ' (ready_i)));
     end

endmodule

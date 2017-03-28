// This counter counts up and is occasionally cleared.
// If up and clear are applied on the same cycle, the
// clear occurs first, and then the up.
//

module bsg_counter_clear_up #(parameter max_val_p     = -1
                             ,parameter init_val_p   = -1
                             ,parameter ptr_width_lp =
                             `BSG_SAFE_CLOG2(max_val_p+1)
                             )
   (input  clk_i
    , input reset_i

    , input clear_i
    , input up_i

    , output logic [ptr_width_lp-1:0] count_o
    );

   // keeping track of number of entries and updating read and
   // write pointers, and displaying errors in case of overflow
   // or underflow

   always_ff @(posedge clk_i)
     begin
        if (reset_i)
          count_o <= init_val_p;
        else
	  count_o <= clear_i ? (ptr_width_lp ' (up_i) ) : (count_o+up_i);
     end

//synopsys translate_off

   always_ff @ (negedge clk_i) begin
      if ((count_o==max_val_p) & up_i   & (reset_i===0))
        $display("%m error: counter overflow at time %t", $time);
   end

//synopsys translate_on

endmodule

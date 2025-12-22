// This counter counts up and is occasionally cleared.
// If up and clear are applied on the same cycle, the
// clear occurs first, and then the up.
//
// This "multi" version of the module takes in a number of input
// signals, and increments the counter by the countones of those inputs.
//

`include "bsg_defines.sv"

module bsg_counter_clear_up_multi #(parameter `BSG_INV_PARAM(max_val_p)
				    // this originally had an "invalid" default value of -1
				    // which is a bad choice for a counter
				    ,parameter init_val_p   = `BSG_UNDEFINED_IN_SIM('0)
				    ,parameter ptr_width_lp =
				    `BSG_WIDTH(max_val_p)
				    ,parameter disable_overflow_warning_p = 0
				    ,parameter els_p
				    )
   (input  clk_i
    , input reset_i

    , input clear_i
    , input [els_p-1:0] up_i
    , output logic [ptr_width_lp-1:0] count_r_o
    );

   logic [`BSG_WIDTH(els_p)-1:0] up_binary_li;

   bsg_popcount #(.width_p(els_p)) pop
     (.i(up_i)
      ,.o(up_binary_li)
      );
   
   // keeping track of number of entries and updating read and
   // write pointers, and displaying errors in case of overflow
   // or underflow

   always_ff @(posedge clk_i)
     begin
        if (reset_i) begin
          count_r_o <= init_val_p;
        end
        else begin
          if (clear_i) begin
            count_r_o <=  ptr_width_lp'(up_binary_li);
          end
          else if (|up_i) begin
            count_r_o <= count_r_o + up_binary_li;
          end
        end
     end

`ifndef BSG_HIDE_FROM_SYNTHESIS

   always_ff @ (negedge clk_i) 
     begin
       if ((count_r_o==ptr_width_lp '(max_val_p)) && up_i && (reset_i===0) && !disable_overflow_warning_p)
         $display("%m error: counter overflow at time %t", $time);
     end

`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_clear_up_multi)

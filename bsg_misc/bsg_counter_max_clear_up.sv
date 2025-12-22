// This counter takes the max of current and new data is occasionally cleared.
// If v_i and clear are applied on the same cycle, the
// clear occurs first, and then the new value is applied.
//

`include "bsg_defines.sv"

module bsg_counter_max_clear_up #(parameter `BSG_INV_PARAM(max_val_p)
			      // this originally had an "invalid" default value of -1
			      // which is a bad choice for a counter
			     ,parameter init_val_p   = `BSG_UNDEFINED_IN_SIM('0)
           ,parameter ptr_width_lp = `BSG_WIDTH(max_val_p)
)
   (input  clk_i
    , input reset_i

    , input clear_i
    , input v_i
    , input [ptr_width_lp-1:0] data_i

    , output logic [ptr_width_lp-1:0] data_r_o
    );

   // keeping track of number of entries and updating read and
   // write pointers, and displaying errors in case of overflow
   // or underflow

   always_ff @(posedge clk_i)
     begin
        if (reset_i) begin
          data_r_o <= init_val_p;
        end
        else begin
          if (clear_i) begin
            data_r_o <=  v_i ? data_i : init_val_p;
          end
          else if (v_i && (data_i > data_r_o)) begin
            data_r_o <= data_i;
          end
        end
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_max_clear_up)

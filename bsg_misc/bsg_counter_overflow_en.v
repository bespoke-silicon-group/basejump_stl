`include "bsg_defines.v"

module bsg_counter_overflow_en #(parameter max_val_p    = -1
                               , parameter init_val_p   = -1
                               , parameter ptr_width_lp = `BSG_SAFE_CLOG2(max_val_p)
                               )
  ( input  clk_i
  , input  reset_i
  , input  en_i
  
  , output logic [ptr_width_lp-1:0] count_o
  , output logic                    overflow_o
  );

  assign overflow_o  = (count_o == max_val_p);
  
  always_ff @(posedge clk_i)
    begin
      if (reset_i | overflow_o)
        count_o <= init_val_p;
      else if (en_i)
        count_o <= count_o + 1'b1;
    end

endmodule


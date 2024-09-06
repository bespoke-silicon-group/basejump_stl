`include "bsg_defines.sv"

module bsg_counter_overflow_en #(parameter `BSG_INV_PARAM(max_val_p    )
                               , parameter `BSG_INV_PARAM(init_val_p   )
                               , parameter ptr_width_lp = `BSG_WIDTH(max_val_p)
                               )
  ( input  clk_i
  , input  reset_i
  , input  en_i
  
  , output logic [ptr_width_lp-1:0] count_o
  , output logic                    overflow_o
  );

  assign overflow_o  = (int'(count_o) == max_val_p);
  
  always_ff @(posedge clk_i)
    begin
      if (reset_i | overflow_o)
        count_o <= init_val_p;
      else if (en_i)
        count_o <= count_o + 1'b1;
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_overflow_en)


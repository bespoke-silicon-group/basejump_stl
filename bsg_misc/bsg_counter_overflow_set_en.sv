`include "bsg_defines.sv"

module bsg_counter_overflow_set_en #( parameter `BSG_INV_PARAM(max_val_p     )
                                    , parameter lg_max_val_lp = `BSG_SAFE_CLOG2(max_val_p+1)
                                    )
  ( input  clk_i
  , input  en_i

  , input                            set_i
  , input        [lg_max_val_lp-1:0] val_i
  
  , output logic [lg_max_val_lp-1:0] count_o
  , output logic                     overflow_o
  );

  assign overflow_o  = (count_o == max_val_p);
  
  always_ff @(posedge clk_i)
    begin
      if (set_i)
        count_o <= val_i;
      else if (en_i)
        begin
          if (overflow_o)
            count_o <= {lg_max_val_lp{1'b0}};
          else 
            count_o <= count_o + 1'b1;
        end
    end

endmodule

`BSG_ABSTRACT_MODULE(bsg_counter_overflow_set_en)


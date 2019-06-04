
//
// Paul Gao 06/2019
//
// By default it is a DOWN COUNTER that supports dynamic start value
//
// It counts down to fixed value end_val_p, then reset to start_i
// Counter is updated only when en_i is asserted
// start_i must be of correct value when is_end_val_o is high
//
// Set parameter up_not_down_p=1 if UP COUNTER is needed
//

module bsg_counter_dynamic_start_fixed_end_en

 #(parameter width_p = "inv"
  ,parameter end_val_p = "inv"
  ,parameter up_not_down_p = 0
  )

  (input                      clk_i
  ,input                      reset_i

  ,input                      en_i
  ,input        [width_p-1:0] start_i
  ,output logic [width_p-1:0] counter_o
  ,output                     is_end_val_o
  );

  assign is_end_val_o = (counter_o == end_val_p);
  
  always_ff @ (posedge clk_i)
    if (reset_i)
        counter_o <= end_val_p;
    else if (en_i)
        if (is_end_val_o) 
            counter_o <= start_i;
        else
            if (up_not_down_p == 0)
                counter_o <= counter_o - width_p'(1);
            else
                counter_o <= counter_o + width_p'(1);

endmodule


//
// Paul Gao 06/2019
//
// This is a count-down counter that supports dynamic start value
// It counts down to last_val_p, then reset to start_i value
// Counter is updated only if en_i is asserted
// start_i must be of correct value when is_last_val_o is asserted
//
//

module bsg_counter_dynamic_start_en_down

 #(parameter width_p = "inv"
  ,parameter last_val_p = "inv"
  )

  (input                      clk_i
  ,input                      reset_i

  ,input                      en_i
  ,input        [width_p-1:0] start_i
  ,output logic [width_p-1:0] counter_o
  ,output                     is_last_val_o
  );

  assign is_last_val_o = (counter_o == last_val_p);
  
  always_ff @ (posedge clk_i)
    if (reset_i)
        counter_o <= last_val_p;
    else if (en_i)
        if (is_last_val_o) 
            counter_o <= start_i;
        else
            counter_o <= counter_o - width_p'(1);

endmodule

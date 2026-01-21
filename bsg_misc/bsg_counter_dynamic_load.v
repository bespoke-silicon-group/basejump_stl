//
// This is a counter which can count up or down and supports loading 
//   the current counter value. Upon a load, the value in the
//   next cycle will be the loaded value (not +1)
//

module bsg_counter_dynamic_load
 #(parameter width_p = "inv"

  // Up is default
  , parameter down_not_up_p = 0
  )
 (input                        clk_i
  , input                      reset_i

  , input                      w_v_i
  , input        [width_p-1:0] data_i

  , output logic [width_p-1:0] counter_o
  );

  always_ff @(posedge clk_i)
    if (reset_i)
      counter_o <= '0;
    else if (w_v_i)
      counter_o <= data_i;
    else if (down_not_up_p)
      counter_o <= counter_o - 1'b1;
    else
      counter_o <= counter_o + 1'b1;

endmodule


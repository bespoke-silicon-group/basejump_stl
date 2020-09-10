`include "bsg_defines.v"

module bsg_dlatch #(parameter width_p="inv"
                   ,parameter i_know_this_is_a_bad_idea_p=0
                   )
  (input               clk_i
  ,input [width_p-1:0] data_i
  ,output logic [width_p-1:0] data_o
  );

  if (i_know_this_is_a_bad_idea_p == 0)
    $fatal( 1, "Error: you must admit this is a bad idea before you are allowed to use the bsg_dlatch module!" );

  always_latch
    begin
      if (clk_i)
        data_o <= data_i;
    end

endmodule


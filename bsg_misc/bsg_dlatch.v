module bsg_dlatch #(parameter width_p="inv"
                   ,parameter i_know_this_is_a_bad_idea_p=0
                   )
  (input               clk_i
  ,input [width_p-1:0] data_i
  ,output logic [width_p-1:0] data_o
  );

  // synopsys translate_off
  initial assert (i_know_this_is_a_bad_idea_p == 1)
    else $error("# Error (%m) using bsg_dlatch without admitting that this is a bad idea!");
  // synopsys translate_on

  always_latch
    begin
      if (clk_i)
        data_o <= data_i;
    end

endmodule


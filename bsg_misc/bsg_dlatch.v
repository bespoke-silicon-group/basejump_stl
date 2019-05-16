module bsg_dlatch #(parameter width_p="inv"
                   ,parameter i_know_this_is_a_bad_idea_p=0
                   )
  (input               clk_i
  ,input [width_p-1:0] data_i
  ,output logic [width_p-1:0] data_o
  );

  // Do not surround with translate off tags so that a warning is issued in DC
  // if the user has not admitted that this is a bad idea.
  if (i_know_this_is_a_bad_idea_p == 0)
    begin
      initial $warning("# WARNING (%m) using bsg_dlatch without admitting that this is a bad idea!");
    end

  always_latch
    begin
      if (clk_i)
        data_o <= data_i;
    end

endmodule


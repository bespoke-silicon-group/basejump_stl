`include "bsg_defines.sv"

module bsg_dlatch #(parameter `BSG_INV_PARAM(width_p)
                   ,parameter i_know_this_is_a_bad_idea_p=0
                   )
  (input               clk_i
  ,input [width_p-1:0] data_i
  ,output logic [width_p-1:0] data_o
  );

  if (i_know_this_is_a_bad_idea_p == 0)
    $fatal( 1, "Error: you must admit this is a bad idea before you are allowed to use the bsg_dlatch module!" );

  logic [width_p-1:0] data_r;
`ifdef VERILATOR
  // Workaround: Verilator executes <= in always_latch as =, so logic
  // sampling this latch on its opening edge would see the new value
  // (issue 5819 in the Verilator repository; the fix in Verilator PR 9184
  // was closed). An explicit sensitivity list keeps the <=.
  always @(clk_i or data_i)
`else
  always_latch
`endif
    begin
      if (clk_i)
        data_r <= data_i;
    end

  assign data_o = data_r;

endmodule

`BSG_ABSTRACT_MODULE(bsg_dlatch)


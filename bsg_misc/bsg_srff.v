
module bsg_srff
 #(parameter width_p = "inv"

   , parameter logic reset_dominates_set_p = 0
   )
  (input clk_i

   , input set_i
   , input reset_i
   , input [width_p-1:0] data_i

   , output [width_p-1:0] data_o
   );

  logic [width_p-1:0] data_r;

  wire do_set = set_i & ~(reset_dominates_set_p & reset_i);
  wire do_reset = reset_i & ~(~reset_dominates_set_p & set_i);

  always @(posedge clk_i)
    if (do_set)
      data_r <= data_i;
    else if (do_reset)
      data_r <= '0;

endmodule


/**
 *  bsg_dff.v
 */

module bsg_dff #(parameter width_p="inv"
		            ,parameter harden_p=0
		            ,parameter strength_p=1   // set drive strength
)
(
  input clock_i
  ,input [width_p-1:0] data_i
  ,output [width_p-1:0] data_o
);

  logic [width_p-1:0] data_r;

  assign data_o = data_r;

  always_ff @ (posedge clock_i) begin
    data_r <= data_i;
  end

endmodule

/**
 *  bsg_less_than.v
 *
 *  @author Tommy Jung
 */

module bsg_less_than #(parameter width_p="inv") (
    input [width_p-1:0] a_i,	// a
    input [width_p-1:0] b_i,	// b
    output logic lt_o			// a is less than b
);

logic cout;
logic [width_p-1:0] diff;

assign {cout, diff} = {1'b0, a_i} + {1'b0, ~b_i} + {{(width_p){1'b0}}, 1'b1};
assign lt_o = ~cout; 

endmodule

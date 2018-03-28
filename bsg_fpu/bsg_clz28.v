/**
 *	bsg_clz28.v
 *
 *	@author Tommy Jung
 */

module bsg_clz28 (
    input [27:0] a_i,				// input
    output logic [4:0] num_zero_o,	// number of leading zeros
    output logic all_zero_o			// input is all zeros
);

logic [15:0] val16;
logic [7:0] val8;
logic [3:0] val4;
logic [1:0] val2;

assign num_zero_o[4] = (a_i[27:12] == 16'b0);
assign val16 = num_zero_o[4] ? {a_i[11:0], 4'b1111} : a_i[27:12]; 
assign num_zero_o[3] = (val16[15:8] == 8'b0);
assign val8 = num_zero_o[3] ? val16[7:0] : val16[15:8];
assign num_zero_o[2] = (val8[7:4] == 4'b0);
assign val4 = num_zero_o[2] ? val8[3:0] : val8[7:4];
assign num_zero_o[1] = (val4[3:2] == 2'b0);
assign val2 = num_zero_o[1] ? val4[1:0] : val4[3:2];
assign num_zero_o[0] = ~val2[1];

assign all_zero_o = (a_i == 28'b0);

endmodule
